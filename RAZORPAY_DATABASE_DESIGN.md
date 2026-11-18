# RAZORPAY DATABASE DESIGN — Attirely Marketplace

**Phase 2 deliverable.** Based on the Phase 1 audit (`RAZORPAY_IMPLEMENTATION_AUDIT.md`)
and the actual SQL export in `backend/app/core/existing_payment_functions.sql`.

⚠ **Nothing in `supabase/migrations/` has been executed.** All files are for
review and must be run manually in the Supabase SQL editor after approval.

Confirmed business decisions applied in this design:
1. Trial rejection → refund the **trial fee**, retain the **platform fee**, refund via Razorpay.
2. HAUTE10 coupon → disabled (out of DB scope; Flutter/backend change in Phase 3/4).
3. Trial and rental payments are separate checkouts/payments.
4. One payment can contain items from multiple vendors and individual sellers.
5. No seller transfers; `seller_payables` records obligations for future Route integration.
6. Accessories remain outside payment scope.

---

## 1. Inspection of the Existing SQL and Backend Dependencies

### 1.1 The two `create_rental_booking` overloads

| | Overload A (legacy) | Overload B (ACTIVE) |
|---|---|---|
| Signature | `(p_user_id uuid, p_booking_reference uuid, p_items jsonb, p_payment_method text DEFAULT 'dummy', p_transaction_reference text DEFAULT NULL, p_platform_fee_per_outfit numeric DEFAULT 50)` | `(p_user_id uuid, p_booking_reference text, p_items jsonb, p_payment_method text, p_transaction_reference text, p_platform_fee_per_outfit numeric, p_delivery_address jsonb)` |
| Attributes | `SECURITY DEFINER` | invoker (no `SECURITY DEFINER`) |
| Delivery address | ❌ | ✅ validated (`'Valid delivery address is required'`) |
| Own-outfit prevention | ❌ **missing** | ✅ `'You cannot rent your own outfit'` |
| Cover image | ❌ (relies on `trg_set_rental_outfit_image`) | ✅ explicit `outfit_images` lookup |
| Payment insertion | `payment_status='success'`, `paid_at=NOW()`, `DUMMY-<uuid>` fallback reference | identical |

**Which overload the backend calls:** `app/services/rentals_service.py`
(`create_rental_booking`, line ~153) passes **7 named arguments including
`p_delivery_address`**. PostgREST resolves function overloads by the
named-argument set, so the call resolves to **Overload B**. Overload A has
**zero callers** in the backend (single RPC call site in the whole codebase).

Consequences:
- Overload A is dead code **and less safe** (no own-outfit check, no address
  validation). It must never be called by the new flow.
- Both overloads insert `payment_status='success'`, `paid_at=NOW()` and a
  `DUMMY-…` transaction reference — the exact behaviour the Razorpay flow must
  not reproduce.
- Neither overload reserves more than its arguments allow for pending
  payments; the backend compensates by calling it **once per item** (one
  transaction per item), which permits partially-booked checkouts.

### 1.2 `/trials/book` inspection (backend, not SQL)

`app/routes/trails.py` inserts directly into `trial_requests` — **no RPC**:
- Generates one shared `booking_reference` (uuid4) for all items.
- Validates: duplicate outfits in request, past dates, outfit published +
  available, size in `outfits.sizes` jsonb array, own-outfit prevention,
  `role in ('vendor','user')`, vendor resolution via `vendors.auth_user_id`.
- Inserts `payment_status='successful'`, `payment_method='dummy'`,
  `payment_reference='DUMMY-<uuid>'`, **hardcoded** `trial_fee=150`,
  `platform_fee=50`, `trial_amount=200`.
- Trial insert intentionally omits `outfit_owner_user_id` (column does not
  exist on `trial_requests`); individual-seller ownership resolves through
  `outfits.uploaded_by`.

### 1.3 Other dependencies verified

- **`manage_rental_status(p_rental_id uuid, p_actor_user_id uuid, p_action text, p_reason text, p_rent_method text)`** — full state machine (accept/reject/cancel/handover/complete) with vendor/individual owner authorization, 24-hour owner-cancellation rule, completion-on/after-return-date rule. Called by `app/routes/rentals.py` via `app/services/rentals_service.py`. **Preserved unchanged.**
- **`calculate_customer_rental_refund()`** — BEFORE UPDATE OF status trigger on `rentals` (`trg_customer_rental_refund`). Fires only for customer cancellation of a pending rental; sets `refund_amount = rental_amount + security_deposit_amount`, `refund_status='pending'`, `refunded_at=NULL` when `payment_status='success'`. Already gateway-neutral. **Not modified** (optional extension in migration 00800).
- **`set_rental_outfit_image()`** — BEFORE INSERT OR UPDATE OF outfit_id trigger (`trg_set_rental_outfit_image`). **Untouched.**
- **`update_trial_requests_updated_at()`** — BEFORE UPDATE trigger on `trial_requests`. **Untouched.**
- Rentals `refund_amount/refunded_at/refund_status` are already maintained by the trigger — the gateway refund lifecycle must slot into `refund_status='pending' → processed/failed` without conflicting.
- `vendor_trial_payment_audit_archive` — written by something outside the app code (not in the export; likely a trigger or the vendor-deletion flow). No payment migration writes to `trial_requests` in a way that would archive rows (only column updates), so it is not at risk. Flagged for verification at execution time.

---

## 2. Proposed Database Schema

New tables (all created by the migration files; none of the existing tables are
altered):

```
payment_fee_settings                payments
─────────────────────               ──────────────────────────────────────────
fee_key (unique)                    id, user_id → users.id
fee_amount numeric                  booking_reference (unique)
is_active                           checkout_type 'trial'|'rental'
                                    razorpay_order_id (unique)
                                    razorpay_payment_id (unique)
                                    amount numeric, gateway_amount_paise bigint
                                    payment_status, gateway_status
                                    failure_reason, payment_method
                                    verified_at, paid_at, expires_at, metadata
                                            │ 1
                                            │
                                            │ *
                                    payment_items
                                    ──────────────────────────────────────────
                                    id, payment_id → payments.id (cascade)
                                    booking_reference, booking_type, booking_id
                                    outfit_id → outfits.id
                                    seller_type 'vendor'|'individual'
                                    vendor_id → vendors.id (nullable)
                                    seller_user_id (= outfits.uploaded_by)
                                    item_amount, rental_amount?, trial_fee?,
                                    security_deposit, platform_fee,
                                    platform_subsidy, refund_due_amount
                                    refundable_amount, seller_payable_amount
                                    refunded_amount
                                            │ 1                    │ 1
                    ┌───────────────────────┤                      │
                    │ 1                     │ 1                    │ 1
        payment_refunds                seller_payables          │
        ─────────────────────          ────────────────────     │
        id, payment_id → payments.id   id, payment_id → payments.id
        payment_item_id → items (null) payment_item_id → items (unique)
        booking_type, booking_id       seller_user_id, vendor_id
        razorpay_refund_id (unique)    gross_amount (excl. deposit)
        amount, gateway_amount_paise   platform_fee, net_payable,
        refund_type full|partial       platform_subsidy, refund_amount
        refund_status                  settlement_status, settlement_reference
        refund_reason, initiated_by
        processed_at, failure_reason   payment_webhook_events
                                       ────────────────────────
                                       razorpay_event_id (unique)
                                       event_type, payment/order/refund ids
                                       signature_valid, payload jsonb
                                       processing_status, processing_error
                                       retry_count, received_at, processed_at
```

Full column definitions, CHECK constraints, indexes and RLS policies are in the
migration files. Highlights:

- **Money:** business amounts `numeric(12,2)` (matches `rentals`/`trial_requests`);
  `gateway_amount_paise bigint` is the authoritative Razorpay amount; a CHECK
  enforces `gateway_amount_paise = round(amount * 100)`. All Razorpay API
  operations use integer paise.
- **Payment statuses:** `created, pending, authorized, captured, failed,
  cancelled, expired, partially_refunded, refunded` (TEXT + CHECK — no enum
  type to keep migrations simple and reversible).
- **Idempotency:** `UNIQUE(booking_reference)` on payments (one payment per
  checkout; retries reuse it), `UNIQUE(razorpay_order_id)`,
  `UNIQUE(razorpay_payment_id)`, `UNIQUE(razorpay_refund_id)`,
  `UNIQUE(razorpay_event_id)` on webhook events,
  `UNIQUE(booking_type, booking_id)` on payment_items (a booking can appear in
  exactly one payment), and a **unique partial index** allowing only ONE
  pending refund per booking.
- **Financial integrity:** payment_items CHECKs enforce type-specific component
  sums (`item_amount = rental_amount + deposit + fee` or `= trial_fee + fee`).
- **Seller payable financial safety (Phase 2 correction):**
  `seller_payables.net_payable = greatest(gross_amount - platform_fee, 0)` and a
  new `platform_subsidy` column records `greatest(platform_fee - gross_amount, 0)`
  — a platform fee larger than the seller gross can never violate the CHECK and
  roll back a verified capture (financial alternatives in §7.1).
- **Audit columns:** every mutable table carries `updated_at` maintained by the
  `payment_touch_updated_at` triggers. `payment_items` previously LACKED the
  column its trigger referenced — that bug is fixed (the column is part of the
  table definition), so `mark_refund_result` can update `refunded_amount`.
- **RLS:** enabled on every new table; customers can SELECT only their own
  payments/items/refunds; sellers can SELECT only their own payables; fee
  settings readable by authenticated users; **no write policies at all** — all
  writes go through the FastAPI service role. Webhook events: no policies.

### 2.1 Function-level security (Phase 2 correction)

Every new SECURITY DEFINER function is backend-only. Each migration ends with:

```sql
revoke execute on function <signature> from public, anon, authenticated;
grant  execute on function <signature> to service_role;
```

| Migration | Functions restricted |
|---|---|
| 00100 | `get_platform_fee(text)` |
| 00400 | `expire_stale_checkouts()`, `expire_orphan_reservations()`, `init_rental_checkout(uuid, uuid, jsonb, jsonb)` |
| 00500 | `init_trial_checkout(uuid, uuid, jsonb)` |
| 00600 | `register_razorpay_checkout(...)`, `confirm_razorpay_payment(...)`, `fail_razorpay_payment(uuid, text, text, text)`, `create_full_item_refund_records(uuid, text)` |
| 00700 | `initiate_item_refund(...)`, `initiate_full_payment_refund(...)`, `mark_refund_result(...)`, `handle_trial_rejection_refund()` |

- All definer functions carry `set search_path to 'public', 'pg_temp'` (verified
  in every file), so they cannot be hijacked through search_path manipulation.
- The init functions accept caller-supplied user ids and are therefore never
  exposed to clients — only the FastAPI backend (service role) may call them
  after authentication. This directly implements "never expose functions taking
  arbitrary `p_user_id` to untrusted callers".
- Function owners (the SQL-editor role, typically `postgres`) retain implicit
  execute rights, so nested definer calls (e.g. `init_*_checkout` →
  `get_platform_fee`) keep working after the revocations.
- Migration 00800's `calculate_customer_rental_refund` is deliberately NOT
  security definer — the original is a plain trigger function and its extended
  body only assigns `rentals` columns (no cross-table writes), so preserving the
  original form is safe.
- Dropping a function (rollback) automatically drops its grants.

---

## 3. Database Relationship Explanation

- `payments.booking_reference` equals the shared `rentals.booking_reference` /
  `trial_requests.booking_reference` of the checkout. A checkout's payment is
  found by that reference in either table.
- `payment_items.booking_id` points at `rentals.id` (rental) or
  `trial_requests.id` (trial). It cannot be a hard FK to both tables, so
  integrity is enforced by `UNIQUE(booking_type, booking_id)` + the
  `register_razorpay_checkout` RPC, which refuses to register a booking row
  that is missing, not pending, or not owned by the customer.
- `payment_items.seller_user_id` = `outfits.uploaded_by` (vendor or
  individual). `vendor_id` is filled only for `seller_type='vendor'`. This
  removes the individual-seller attribution dependency on
  `trial_requests` (which has no owner column) for accounting purposes.
- `seller_payables.payment_item_id` is UNIQUE — exactly one payable per item;
  created at payment confirmation; `gross_amount = rental_amount` (or
  `trial_fee`) deliberately **excludes security deposits**, which are customer
  liabilities, not seller income.
- `payment_refunds` links a refund to the payment (gateway operation level)
  and, for booking-level refunds, to `payment_item_id` / `booking_type` /
  `booking_id`.

---

## 4. Payment and Booking State Transitions

### 4.1 `payments.payment_status`

```
                register order          checkout opened
   (none) ────────────────▶ created ────────────────▶ pending
                              │    │                     │
        retry (before expiry) │    │ gateway authorized  │ verified captured
        reuses same record    │    ▼                     ▼
                              │  authorized ───(capture event)──▶ captured ◀─┐
                              ▼                                              │
                            failed ──(retry until expires_at)────────────────┘
                              │ expires_at passes
                              ▼
                           expired ────────▶ (late capture?) recorded, bookings NOT
                                             confirmed; full refund required
   captured ──▶ partially_refunded ──▶ refunded   (via payment_refunds)
   created/pending/failed ──▶ cancelled (operator only)
```

Rules enforced by `confirm_razorpay_payment` (Phase 2 corrections applied):
- **Outcome persistence:** every captured outcome is persisted in
  `payments.metadata->>'confirmation_outcome'` — `'confirmed'`,
  `'late_capture'`, or `'unconfirmable_refund_required'` — with
  `confirmation_outcome_message` and `requires_full_refund` where applicable.
- **Idempotent, outcome-aware replay:** a replay with the same gateway payment
  id returns the ORIGINAL outcome from metadata: `'confirmed'` →
  `success/already_processed`; `'late_capture'`/`'unconfirmable_refund_required'`
  → the identical refund-required outcome, never an ordinary success. Works
  identically for the verification path and the webhook path (both call this
  one function).
- Different gateway payment id on a captured payment → exception.
- Amount mismatch (paise-exact) → exception.
- `expired`/`cancelled` payment receiving a capture → the verified capture is
  recorded transactionally (`payment_status='captured'`), bookings **not**
  confirmed, pending full-refund records created for every item (via
  `create_full_item_refund_records`), outcome
  `'unconfirmable_refund_required'`.
- `authorized` → payment marked authorized, bookings stay pending until
  capture. A repeated `authorized` call with the same gateway payment id is
  answered idempotently.
- **Capture after `expires_at`** → outcome `'late_capture'`; bookings **not**
  confirmed; pending full-refund records created transactionally; backend must
  auto-refund (Phase 3).
- **Seller rejection/cancellation before capture** → the confirmable count is
  checked BEFORE updating bookings; if any booking is unconfirmable, the
  verified capture is recorded, NOTHING is confirmed, outcome
  `'unconfirmable_refund_required'`, pending full-refund records created for
  every item. (The previous design raised here, rolling back a verified
  capture — fixed.) Interim rule: refund the whole payment; partial
  confirmation is the documented alternative (§7.1).
- **Retry payment ids:** a retry on the same Razorpay order produces a NEW
  gateway payment id; in created/pending/failed states the recorded id is
  only the last attempt and is legitimately replaced. In
  captured/authorized states the id is authoritative and mismatches are
  rejected by the replay guards.

### 4.2 `rentals` (payment lifecycle only; business statuses unchanged)

| Event | payment_status | status | notes |
|---|---|---|---|
| `init_rental_checkout` | `pending` | `pending` | `paid_at`/`transaction_reference` NULL; holds inventory |
| `expire_stale_checkouts` | `failed` | `cancelled` | `cancelled_by_role='system'`; releases exclusion constraint |
| `confirm_razorpay_payment` | `success` | `pending` (unchanged) | `paid_at`, `transaction_reference = razorpay_payment_id`; seller acceptance still required |
| `manage_rental_status` cancel (customer) | unchanged | `cancelled` | trigger sets `refund_status='pending'` + `refund_amount` |
| refund processed | `refunded` only when the full refundable portion is returned; otherwise stays `success` | unchanged | via `mark_refund_result` (§7) |
| `manage_rental_status` accept/reject/handover/complete | unchanged | unchanged | authorization preserved |

No new rental status values are introduced; the exclusion constraint is never
touched.

### 4.3 `trial_requests`

| Event | payment_status | status |
|---|---|---|
| `init_trial_checkout` | `pending` | `pending` |
| `expire_stale_checkouts` | `failed` | `pending` (no new status value — see §9 assumptions) |
| `confirm_razorpay_payment` | `successful` | `pending` (seller acceptance still required) |
| seller rejects (paid) | `successful` → `refunded` after refund processed | `rejected` |
| refund processed | `refunded` | unchanged |

**Expired unpaid trials (Phase 2 correction — documented handling):** an
expired checkout leaves trial rows `status='pending'` +
`payment_status='failed'` (no new trial status value exists). Seller
dashboards built on `status='pending'` would show them as actionable
requests, which is wrong — Phase 3 MUST filter them out (e.g. exclude
`payment_status='failed'` rows from seller trial lists, or treat them as
"payment not completed"). An optional later migration can auto-reject them
(`rejection_reason='Payment not completed'`) once the DDL inspection confirms
the `trial_requests.status` CHECK allows it. Until then the dashboard filter
in Phase 3 is the handling mechanism — flagged for the Phase 3 review.

### 4.4 `payment_refunds`

`pending` → `processed` (gateway confirmed) → booking/payment/seller updates applied
`pending` → `failed` → retry allowed (new record or re-process)
One pending refund per booking (unique partial index).

**Gateway-immutability (Phase 2 round 2):** the backend sets
`gateway_initiated_at` / `gateway_initiated_amount` immediately after calling
the Razorpay Refund API. A pending refund that has reached the gateway is
immutable — `create_full_item_refund_records` never enlarges or duplicates it;
any uncovered remainder is recorded in `payment_items.refund_due_amount` and
`convert_refund_due_to_pending_refund` (auto-called by `mark_refund_result`
on every result) turns it into a fresh pending record once the blocking
refund settles and frees the unique index slot.

### 4.5 `seller_payables`

Created at confirmation with `settlement_status='pending'`; moved to
`on_hold` when any refund affects the item; `eligible`/`settled` are future
settlement states (no automation in this phase).

### 4.6 `payment_webhook_events`

`received` → `processed` | `failed` (retryable) | `skipped` (e.g. duplicate).
`UNIQUE(razorpay_event_id)` guarantees a single processing pass; `retry_count`
tracks redelivery attempts.

---

## 5. Rental Reservation and Expiry Strategy

**Problem:** the existing exclusion constraint treats `status='pending'` rentals
as active, so an unpaid reservation blocks the same outfit+size for every
customer until it is released. `NOW()` cannot appear in an exclusion constraint
predicate (volatile), so expiry must be enforced procedurally.

**Design (migration 20261117000400 + 00900):**

1. **Reservation window:** `payments.expires_at` (set by the backend at order
   creation from a configurable TTL, e.g. 15–20 minutes).
2. **Lazy expiry:** `expire_stale_checkouts()` is executed at the start of every
   `init_rental_checkout` / `init_trial_checkout` call — correctness never
   depends on a scheduler. The partial index
   `payments_active_expiry_idx` keeps this scan cheap.
3. **Scheduled expiry (optional):** pg_cron every minute (migration 00900),
   plus `expire_orphan_reservations()` every 10 minutes for reservations whose
   payment row was never registered (crash between reservation and order
   creation).
4. **Release mechanics:** expired payments are marked `payment_status='expired'`;
   their pending rental reservations become `status='cancelled'`,
   `cancelled_by_role='system'`, `payment_status='failed'` — existing values
   only, so all existing frontend filters and status handling keep working, and
   the exclusion constraint releases immediately. Trial reservations are marked
   `payment_status='failed'` (no new trial status value is introduced).
5. **Late successful payment:** `confirm_razorpay_payment` refuses to confirm
   bookings for `expired`/`cancelled` payments or captures after `expires_at`;
   it records the verified money transactionally, sets
   `requires_full_refund=true`, persists the outcome in
   `metadata->>'confirmation_outcome'` and creates pending full-refund records
   for every item in the SAME transaction, so the refund requirement is durable
   and replays return the identical outcome. A late capture can never silently
   confirm a booking that may have been given to another customer.
6. **Retry semantics:**
   - Attempt failed but window open → same payment row, same Razorpay order,
     same reservations (no duplicate bookings — enforced by the
     `payments_booking_reference` unique index and the duplicate guard inside
     both init functions).
   - Window expired → a **new checkout** (new `booking_reference`) is required;
     the expired payment remains as an auditable record.

### 5.1 Authorized-but-never-captured payments (Phase 3 reconciliation contract)

Authorized payments are deliberately **never** auto-expired by
`expire_stale_checkouts()` — expiring a payment while its gateway
authorization may still be active could lose money or confirm nothing while
the customer was charged. Instead, Phase 3 MUST run an authorized-payment
reconciliation job (e.g. every 5–10 minutes) with exactly this flow:

1. **Select candidates:** `payments` with `payment_status='authorized'` whose
   `expires_at` has passed by a grace margin (e.g. +60 minutes), plus any
   `authorized` payment explicitly flagged by support.
2. **Ask the gateway first — never decide from local state:** fetch the
   payment from the Razorpay API (`GET /payments/{id}`, server-to-server with
   the key id/secret; no signature needed for a fetch) and branch on the
   AUTHORITATIVE gateway state:
   - **`captured`** → call `confirm_razorpay_payment(..., 'captured', ...)` as
     usual. The normal outcome logic applies: bookings still confirmable →
     confirmed; otherwise → late-capture/unconfirmable outcome with automatic
     pending full-refund records. (Replays are idempotent.)
   - **still `authorized`** → business decision per case:
     - If the reservations are still confirmable (inventory intact): either
       capture via the Razorpay capture API and run the normal confirm flow,
       or cancel the authorization.
     - Otherwise: cancel the authorization via Razorpay's cancel-payment API
       (only `authorized` payments are cancellable — verify the exact
       endpoint/behaviour against current Razorpay docs during Phase 3) or
       let the authorization lapse per the gateway's own validity policy.
   - **`failed`/`cancelled` at the gateway** → record locally via
     `fail_razorpay_payment` (or mark `cancelled`) — no refund needed, money
     was never captured.
3. **Only after the gateway state is terminal** (captured handled, or the
   authorization cancelled/released and confirmed so at the gateway) may the
   local payment row leave the `authorized` state. THEN run
   `expire_stale_checkouts()`: it releases the reservations of the no-longer-
   active payment (`cancelled`/`system`/`failed`), freeing inventory via the
   existing exclusion constraint.
4. **Inventory safety:** while a payment is `authorized`, its reservations
   legitimately keep holding inventory (the customer paid or will imminently).
   The reconciliation job bounds this holding to `expires_at + grace`; it must
   never release inventory while the authorization is still live, and never
   confirm bookings for inventory already released (handled by the
   late-capture outcome).
5. **Late captures after release:** if the gateway captures an
   already-released/cancelled authorization, `confirm_razorpay_payment`
   records the verified capture and creates pending full-refund records
   (outcome `unconfirmable_refund_required`); the Phase 3 auto-refund loop
   executes them. The customer is never left charged without a recorded
   refund requirement.
6. **Idempotency:** the reconciliation job may crash between steps; every
   step is safe to re-run — gateway fetches are read-only, confirmations are
   idempotent, and local status transitions only move forward.

---

## 6. Existing Functions — Modification Plan

| Function | Signature (exact) | Backend callers | Dependencies | Modification required? | Proposal |
|---|---|---|---|---|---|
| `create_rental_booking` (Overload A) | `(uuid, uuid, jsonb, text, text, numeric)` | **none** (dead code) | rentals; relies on `trg_set_rental_outfit_image` | **No — do not touch** | Leave as rollback path; add to a later cleanup migration (with own-outfit fix or removal) only after the new flow is live. Never called by the payment flow. |
| `create_rental_booking` (Overload B, ACTIVE) | `(uuid, text, jsonb, text, text, numeric, jsonb)` | `app/services/rentals_service.py` (one RPC per item) | outfits (FOR UPDATE), outfit_images, vendors, rentals, `trg_set_rental_outfit_image`, exclusion constraint | **No** | Superseded by `init_rental_checkout` (atomic, pending payment, DB-configured fee). Kept intact for backward compatibility and instant rollback: reverting the backend to the old call restores today's behaviour exactly. |
| `manage_rental_status` | `(uuid, uuid, text, text, text)` | `rentals.py` (accept/reject/cancel/handover/complete) | rentals, vendors, `trg_customer_rental_refund` | **No** | Authorization + business rules preserved as-is. Expiry uses `cancelled_by_role='system'`, which the refund trigger ignores by design. |
| `calculate_customer_rental_refund()` | trigger fn, no args | trigger `trg_customer_rental_refund` | rentals financial columns | **Optional only** | Migration 00800 (OPTIONAL, needs approval) extends it to seller rejection / seller cancellation of paid rentals (same amounts, platform fee retained). Without it, those cases produce **no** refund record — a real-money gap documented in §10. |
| `set_rental_outfit_image()` | trigger fn, no args | trigger `trg_set_rental_outfit_image` | outfit_images | **No** | Untouched. |
| `update_trial_requests_updated_at()` | trigger fn, no args | trigger on trial_requests | — | **No** | Untouched. |

New functions introduced (none replace existing production functions):
`get_platform_fee`, `expire_stale_checkouts`, `expire_orphan_reservations`,
`init_rental_checkout`, `init_trial_checkout`, `register_razorpay_checkout`,
`confirm_razorpay_payment`, `fail_razorpay_payment`,
`create_full_item_refund_records`, `initiate_item_refund`,
`initiate_full_payment_refund`, `mark_refund_result`,
`handle_trial_rejection_refund` (+ trigger `trg_trial_rejection_refund`),
`payment_touch_updated_at` (+ triggers on the four new tables). All SECURITY
DEFINER functions are backend-only with explicit revoke/grant statements
(§2.1).

---

## 7. Refund Architecture

```
                       ┌──────────────────────────────────────────────┐
 rental cancel/reject/  │ DB triggers / functions create PENDING      │
 expiry late-capture    │ payment_refunds rows (calculated amounts)   │
 trial seller rejection │ — never proof of money movement             │
                       └──────────────────┬───────────────────────────┘
                                          │ Phase 3 backend picks up
                                          ▼
                       Razorpay Refund API (payment_id, amount in paise)
                                          │
                       mark_refund_result(refund_id, rp_refund_id, status)
                        ├── processed → booking refunded, payment
                        │   partially_refunded/refunded, seller payable
                        │   adjusted (deposit portion never seller income)
                        └── failed    → retry allowed, bookings untouched
```

- **Booking-level refunds** (one item of a multi-item payment): `initiate_item_refund`
  validates against `payment_items.refundable_amount` minus already
  pending/processed refunds. `refundable_amount` per policy:
  rental → `rental_amount + security_deposit` (platform fee retained, matching
  the existing trigger); trial → `trial_fee` (platform fee retained — **the
  confirmed Phase 2 decision**).
- **Payment-level refunds** (whole payment): `initiate_full_payment_refund`
  creates per-item pending records capped at `item_amount` each (covers late
  captures where the full paid amount must return to the customer).
- **Gateway truth:** a refund record becomes real only when
  `mark_refund_result` records a Razorpay refund id with status `processed`
  (from the API response or the `refund.processed` webhook). `refunded_at`,
  booking `payment_status='refunded'`, payment aggregate status and seller
  payable adjustments all happen only at that point.
  **Phase 2 review rule (confirmed):** Razorpay's Refund API can respond with
  status `pending`. A pending API response must NEVER be recorded as
  `processed` — only a verified `refund.processed` webhook or a re-fetched
  gateway state showing the refund settled may mark it processed. The Phase 3
  backend enforces this; pending refunds stay `pending` and visible until then.
- **`refunded` semantics (Phase 2 correction):** a booking's
  `payment_status='refunded'` means its ENTIRE refundable portion (rental
  amount + security deposit / trial fee) has been returned to the customer.
  The retained platform fee is tracked in the financial columns
  (`payment_items.platform_fee`, `seller_payables`), never through the booking
  status. Partially refunded bookings keep `success`/`successful`.
  The `payments` aggregate becomes `partially_refunded` unless EVERY rupee of
  the captured amount is refunded, in which case it becomes `refunded`.
- **Seller payable safety (Phase 2 correction):** `seller_payables.refund_amount`
  is clamped against the remaining un-refunded seller gross, so repeated
  refunds on one item can never push it past `gross_amount`; and the payable
  INSERT uses `greatest()` clamping with `platform_subsidy` (§7.1), so a
  platform fee larger than the seller gross can never roll back a verified
  capture. The same clamping applies to `payment_items.seller_payable_amount`
  at registration (round 2).
- **Full-refund reconciliation (Phase 2 round 2):** when a full-refund
  requirement arises while an item already has a pending refund,
  `create_full_item_refund_records` reconciles instead of silently dropping
  the remainder:
  1. no pending refund → insert one pending record for the full remainder;
  2. pending refund NOT yet handed to Razorpay (`gateway_initiated_at` NULL)
     → TOP IT UP to cover the remainder (one gateway refund, no duplicates);
  3. pending refund already handed to Razorpay (immutable) → the remainder is
     recorded durably in `payment_items.refund_due_amount`;
     `convert_refund_due_to_pending_refund` (auto-invoked by
     `mark_refund_result` on every processed/failed result) converts it into
     a fresh pending record once the blocking refund settles and frees the
     one-pending-per-booking index slot. The entire remaining amount is
     therefore always represented in the database without duplicate gateway
     refunds.
- **Duplicate protection:** unique pending-refund-per-booking index +
  `razorpay_refund_id` uniqueness + idempotent replay handling.
- **Amount ceiling:** every path validates the requested amount against the
  remaining refundable balance; exceeding it raises an exception.
- Seller payable impact: only the seller gross portion
  (`rental_amount`/`trial_fee`) reduces `refund_amount`; a security-deposit
  component of a refund was never seller income.

### 7.1 When the platform fee exceeds the seller gross (financial alternatives — PRODUCT DECISION REQUIRED)

With the current fees (₹50 platform fee per item) a very cheap item (e.g. a
₹10/day 1-day rental, or a trial fee lower than the platform fee) makes
`gross_amount < platform_fee`. The mathematically correct `net_payable` would
be NEGATIVE ("seller owes the platform"). The original design would have
violated the `net_payable >= 0` CHECK **inside the confirmation transaction**,
rolling back an already-verified gateway capture — the worst possible failure
mode. That is fixed in this correction pass.

**Implemented interim rule (no business-model change required to go live):**

| Column | Value | Meaning |
|---|---|---|
| `net_payable` | `greatest(gross_amount - platform_fee, 0)` | seller owes/earns at least ₹0 |
| `platform_subsidy` | `greatest(platform_fee - gross_amount, 0)` | the part of the platform fee the platform absorbs when it exceeds the seller gross |

The customer always pays the full quoted price; nothing about the checkout
changes. The subsidy is VISIBLE in accounting rather than silently lost.

**Alternatives requiring product approval (NOT implemented silently):**

1. **"Seller owes platform" (negative net_payable):** drop the
   `net_payable >= 0` CHECK, store negative values and net them against future
   settlements. Pros: economically exact. Cons: requires settlement logic that
   nets debits (out of scope this phase), seller-communication implications,
   and a schema change. **Decision needed if/when cheap items become common.**
2. **Reject tiny-rental checkouts:** enforce a minimum item gross
   (e.g. `rental_amount >= platform_fee`) in `init_rental_checkout`. Pros:
   keeps accounting simple. Cons: blocks low-price inventory — a merchandising
   decision, not a technical one.
3. **Percentage platform fee instead of flat per-item fee:** would scale with
   item price but changes the current hardcoded flat-fee model. Out of scope.

The database now supports (1) with a one-line CHECK change plus settlement
logic; (2)/(3) need schema/function changes. None of them is required for
Phase 2 correctness because of the interim rule.

---

## 8. Migration Files, Order and Rollback

### Files (execute in this order)

| # | File | Contents |
|---|---|---|
| 1 | `supabase/migrations/20261117000100_payment_fee_settings.sql` | Fee settings table + seed (150/50/50 = current hardcoded values) + `get_platform_fee` + RLS |
| 2 | `supabase/migrations/20261117000200_payment_core_tables.sql` | `payments`, `payment_items`, updated_at trigger, indexes, RLS |
| 3 | `supabase/migrations/20261117000300_refunds_settlements_webhooks.sql` | `payment_refunds`, `seller_payables`, `payment_webhook_events`, indexes, RLS |
| 4 | `supabase/migrations/20261117000400_init_rental_checkout.sql` | `init_rental_checkout`, `expire_stale_checkouts`, `expire_orphan_reservations` |
| 5 | `supabase/migrations/20261117000500_init_trial_checkout.sql` | `init_trial_checkout` |
| 6 | `supabase/migrations/20261117000600_register_confirm_fail_payment.sql` | `register_razorpay_checkout`, `confirm_razorpay_payment`, `fail_razorpay_payment` |
| 7 | `supabase/migrations/20261117000700_refund_functions.sql` | Refund initiation/result functions + `trg_trial_rejection_refund` |
| 8 | `supabase/migrations/20261117000800_optional_rental_rejection_refund.sql` | **OPTIONAL** — extends `calculate_customer_rental_refund` (seller rejection/cancellation) |
| 9 | `supabase/migrations/20261117000900_scheduled_cleanup.sql` | **OPTIONAL** — pg_cron schedules |

All files are idempotent (`create table if not exists`, `insert … on conflict do
nothing`, `drop policy if exists`), and each header documents its rollback.

### Rollback plan (inverse order)

1. **00900:** `cron.unschedule('attirely-expire-stale-checkouts')`, `cron.unschedule('attirely-expire-orphan-reservations')`.
2. **00800:** re-run the original `calculate_customer_rental_refund` body from `backend/app/core/existing_payment_functions.sql` (reference file preserves it verbatim).
3. **00700:** drop `trg_trial_rejection_refund`, then the four functions.
4. **00600/00500/00400:** drop the eight checkout/confirmation functions
   (`init_rental_checkout`, `expire_stale_checkouts`,
   `expire_orphan_reservations`, `init_trial_checkout`,
   `register_razorpay_checkout`, `confirm_razorpay_payment`,
   `fail_razorpay_payment`, `create_full_item_refund_records`). Dropping a
   function also drops its grants, so no separate revoke step is needed.
   Reverting the FastAPI caller to the legacy `create_rental_booking` RPC
   (unchanged on the DB) restores the current behaviour with **zero DDL
   work**.
5. **00300/00200/00100:** drop tables (children first: `payment_webhook_events`, `seller_payables`, `payment_refunds`, `payment_items`, `payments`, `payment_fee_settings`) and the triggers/functions created in 00200/00100.
6. **Data-loss note:** dropping the payment tables discards payment history —
   take a Supabase backup (or `pg_dump` of the new tables) before any rollback
   after real transactions exist. Before go-live, rollback is lossless.
7. Existing tables (`rentals`, `trial_requests`, …) are **never dropped or
   altered** by any migration; a full rollback leaves them exactly as today.
   The only new data in existing tables after rollback: pending/cancelled
   reservation rows (test data) and cancelled reservations released by expiry —
   all visible, deletable test rows.

---

## 9. Risks and Unresolved Assumptions

| # | Assumption / risk | Impact | Mitigation |
|---|---|---|---|
| 1 | `rentals.cancelled_by_role='system'` — column is free text in observed usage; a CHECK constraint on it (or on `rentals.status`/`payment_status`) could not be verified because table DDL was not exported. | Expiry update could fail at execution time. | Verify table DDL in the SQL editor before executing 00400 (inspection query in §10). If a CHECK exists, extend the permitted values explicitly in this migration. |
| 2 | `trial_requests.status` CHECK constraint unknown — a `'cancelled'` value might be rejected, which is why expiry keeps trial status `'pending'` and only marks `payment_status='failed'`. | Expired unpaid trials linger as pending requests in seller dashboards with `payment_status='failed'`. | Accepted for now (no blocking effect). Optional follow-up after DDL inspection: auto-reject expired trials with `rejection_reason='Payment not completed'`. |
| 3 | Exact predicate of the rentals exclusion constraint not exported (believed `status IN ('pending','accepted','handed_over')`). | If it also covers `cancelled`/`failed`, released reservations would still block. | Verify with the DDL inspection query; the design only inserts existing status values, so worst case requires a policy adjustment, not a constraint change. |
| 4 | Existing RLS state on `rentals`/`trial_requests`/`outfits` unknown. | New tables' policies are self-contained; no interference expected. | Verify during execution; the backend always uses the service role. |
| 5 | Overload A of `create_rental_booking` remains callable and unsafe (no own-outfit check). | Only a caller explicitly using 6 args would hit it; none exist in the codebase. | Documented; removal deferred to a post-launch cleanup migration. |
| 6 | `vendor_trial_payment_audit_archive` writer not identified (probably a trigger). | Unverified interaction with new trial updates. | Migrations only UPDATE existing trial columns (no deletes); verify no archival trigger misbehaves during Phase 5 testing. |
| 7 | Razorpay webhooks: event id taken from the `X-Razorpay-Event-Id` header; fallback (deterministic payload hash) is implemented in the backend in Phase 3. | Replays without the header could evade dedup. | Backend computes the fallback hash from the raw body; UNIQUE constraint makes double-processing impossible either way. |
| 8 | pg_cron availability varies per Supabase project. | Scheduled expiry may not install. | Lazy expiry inside every init function keeps the system correct without cron. **Round 2:** `expire_orphan_reservations()` also runs lazily in both init functions, and partial indexes on `rentals`/`trial_requests` keep the lazy scans cheap — orphan cleanup no longer depends on pg_cron at all. |
| 9 | Payment expires while `authorized` (money held, not captured). | Deliberately NOT auto-expired; requires capture handling in Phase 3. | **Phase 3 reconciliation contract defined (§5.1)**: gateway state is fetched first; captured → normal confirm flow, still-authorized → capture-or-cancel at the gateway; only after a terminal gateway state is inventory released; late captures auto-refund. |
| 10 | Trial fee is a global fixed value (today's behaviour: ₹150/item). Per-outfit trial pricing would need an `outfits.trial_fee` column. | None today. | `payment_fee_settings` is the single source; per-outfit pricing is a future schema addition, out of scope. |
| 11 | Platform fee > seller gross (cheap items) breaks the naive `net_payable` math. | Was: payable CHECK violation rolling back a verified capture. | FIXED: `greatest()` clamp + `platform_subsidy` (interim rule). The "seller owes platform" and "reject tiny rentals" alternatives are **product decisions** (§7.1). |
| 12 | A seller rejects only ONE item of a multi-item checkout before capture. | Payment is captured but the interim rule refunds the WHOLE payment and asks the customer to rebook. | Partial confirmation (confirm still-valid items, refund only the rejected one) is possible and is a **product decision** (§4.1). Current rule is safe but customer-inconvenient. |
| 13 | Expired unpaid trials stay `status='pending'` with `payment_status='failed'` and would appear in seller dashboards as actionable requests. | Seller confusion / wasted effort on dead requests. | **Phase 3 must filter** `payment_status='failed'` rows out of seller trial lists (§4.3). Optional later migration can auto-reject them after DDL inspection. |
| 14 | Razorpay Refund API `pending` responses recorded as processed would show money as returned before it is. | False financial state; seller payables adjusted prematurely. | FIXED/DOCUMENTED: only `refund.processed` webhooks or verified settled gateway state may call `mark_refund_result(processed)`; Phase 3 backend enforces (§7). |

---

## 10. Database Test Plan (to be executed in Phase 5 / SQL editor — not executed now)

Pre-step — DDL inspection queries to run **before** executing migrations:

```sql
-- Verify CHECK constraints / defaults that this design assumes
select conname, pg_get_constraintdef(oid)
  from pg_constraint
 where conrelid in ('public.rentals'::regclass, 'public.trial_requests'::regclass);

-- Verify the exclusion constraint predicate
select indexname, indexdef
  from pg_indexes
 where tablename = 'rentals';

-- Verify existing RLS state
select tablename, rowsecurity from pg_tables
 where schemaname = 'public';
```

Test scenarios (SQL-editor execution on test data; expected → actual recorded in Phase 5):

| # | Scenario | Expected |
|---|---|---|
| D1 | `get_platform_fee('rental_platform_fee')` | 50.00; raises for unknown key |
| D2 | `init_rental_checkout` with 2 items, mixed vendor/individual owners | 2 rentals `payment_status='pending'`, no `paid_at`, amounts from `outfits`, total = Σ(item) |
| D3 | `init_rental_checkout` with own outfit | exception `You cannot rent your own outfit`; **no rows inserted** (atomicity) |
| D4 | `init_rental_checkout` where item 2 has an invalid size | exception; item 1 is **rolled back** (no partial reservation) |
| D5 | Overlapping dates from another customer | exclusion constraint violation |
| D6 | Duplicate booking_reference | exception `A payment checkout already exists…` |
| D7 | `register_razorpay_checkout` with order amount ≠ Σ item totals | exception `Razorpay order amount … does not match` |
| D8 | `register_razorpay_checkout` happy path | payments row `created` + one payment_item per booking, `refundable_amount`/`seller_payable_amount` per policy |
| D9 | Re-register same booking_reference + same order id | `already_registered: true`, no duplicate rows |
| D10 | `confirm_razorpay_payment` happy path (captured) | payment `captured`; all rentals `success` with payment reference; seller_payables created |
| D11 | `confirm_razorpay_payment` replay | `already_processed: true`, no duplicate payables |
| D12 | Confirm with wrong amount (paise) | exception; bookings untouched |
| D13 | Confirm with `authorized` | payment `authorized`; bookings still pending |
| D14 | Confirm a payment whose rentals were cancelled meanwhile | mismatch exception; whole transaction rolled back |
| D15 | `fail_razorpay_payment` | payment `failed`; reservations intact; retry reuses same order |
| D16 | Expire: set `expires_at` in past, run `expire_stale_checkouts()` | payment `expired`; rentals `cancelled`/`system`/`failed`; exclusion released (new overlapping reservation succeeds); trials `payment_status='failed'` |
| D17 | Late capture after expiry | `outcome: late_capture`; bookings NOT confirmed; `requires_full_refund=true` |
| D18 | Customer cancels paid pending rental | trigger: `refund_amount = rental + deposit`, `refund_status='pending'`, `refunded_at` NULL |
| D19 | `initiate_item_refund` beyond remaining refundable | exception |
| D20 | Duplicate pending refund for same booking | blocked by unique partial index |
| D21 | Trial rejection with payment via `payment_items` | `trg_trial_rejection_refund` inserts pending refund = trial_fee only |
| D22 | Trial rejection on legacy dummy row (no payment_item) | trigger no-op |
| D23 | `mark_refund_result(processed)` | refund processed; rental `payment_status='refunded'`; payment `partially_refunded`/`refunded`; seller payable refund_amount adjusted by gross portion only |
| D24 | `mark_refund_result` replay with same id | `already_processed: true` |
| D25 | `initiate_full_payment_refund` on multi-item payment | one pending refund per item, capped at remaining amounts |
| D26 | RLS: authenticated select of another user's payment | 0 rows |

Correction-pass scenarios (Phase 2 review):

| # | Scenario | Expected |
|---|---|---|
| D27 | `init_rental_checkout` with an unpublished outfit | exception `% is not published`; no rows inserted |
| D28 | `init_rental_checkout` with an unavailable outfit | exception `% is currently unavailable` |
| D29 | Seller rejects a pending rental reservation, then capture arrives | payment `captured`; bookings NOT confirmed; `confirmation_outcome='unconfirmable_refund_required'`; pending full refund per item; **no seller_payables created**; `success=false` |
| D30 | Replay of D29 (same ids, verify + webhook) | identical outcome + `already_processed: true`; no duplicate refund records |
| D31 | Late capture replay (repeat confirmation after expiry) | outcome `late_capture` + `already_processed: true` every time; never a success |
| D32 | Repeat `authorized` call with same gateway payment id | `already_processed: true`, payment stays `authorized` |
| D33 | Retry: fail payment, then verify a NEW gateway payment id on the same order | confirm succeeds (retry ids legitimate before capture) |
| D34 | Confirm an item with `platform_fee > gross` (e.g. ₹10 1-day rental) | capture succeeds; payable `net_payable=0`, `platform_subsidy=40` |
| D35 | Partial item refund processed (< refundable_amount) | booking keeps `success`/`successful`; payment `partially_refunded`; booking `refunded` only after the FULL refundable portion is processed |
| D36 | Refund API response status `pending` | refund record stays `pending` (backend must not call `mark_refund_result(processed)` until the `refund.processed` webhook/verified state) |
| D37 | Two processed refunds on one item totalling ≤ gross | `seller_payables.refund_amount ≤ gross_amount` always |
| D38 | `anon`/`authenticated` attempt to EXECUTE a definer function directly | permission denied |
| D39 | `mark_refund_result` updates `payment_items.refunded_amount` | succeeds (updated_at column + trigger present — Correction 1 regression check) |

Round-2 correction scenarios:

| # | Scenario | Expected |
|---|---|---|
| D40 | Register a checkout with `platform_fee > seller gross` (₹10 1-day rental) | `payment_items.seller_payable_amount = 0`, `platform_subsidy = 40`; registration succeeds (no CHECK violation) |
| D41 | Concurrent seller rejection during capture: reject tx commits while confirm holds the booking row locks | reject waits; after commit the booking is confirmed normally (no lost capture) |
| D42 | Concurrent seller rejection commits BEFORE confirm locks the rows | `unconfirmable_refund_required`: payment captured, nothing confirmed, whole-payment refund records |
| D43 | Full-refund requirement while a smaller pending refund exists (NOT gateway-initiated) | the pending refund is TOPPED UP to the full remainder; no second record; no duplicate gateway refund |
| D44 | Full-refund requirement while the pending refund IS gateway-initiated (`gateway_initiated_at` set) | remainder recorded in `payment_items.refund_due_amount`; no duplicate record |
| D45 | D44 followed by `mark_refund_result(processed)` on the blocking refund | a NEW pending refund for the remainder is auto-created (`convert_refund_due_to_pending_refund`); `refund_due_amount` reduced to 0 |
| D46 | `initiate_item_refund` after a deferred due exists | remaining refundable reduced by the due; over-recording impossible |
| D47 | Lazy cleanup without pg_cron: orphan reservation (no payment row, older than 1 day) | next `init_*_checkout` call releases it (`expire_orphan_reservations` runs lazily) |

---

## 11. What Phase 3 Will Build on Top of This

- `app/core/razorpay_config.py` (Key ID/Secret, webhook secret, TTL, currency — from env).
- `app/services/payment_service.py` — the single payment-state service that calls
  `init_*_checkout`, creates the Razorpay order, calls `register_razorpay_checkout`,
  verifies HMAC signatures, fetches gateway payment state, and calls
  `confirm_razorpay_payment` / `fail_razorpay_payment` / refund functions from
  BOTH the verification endpoint and the webhook processor.
- `app/routes/payments.py` — checkout/verify/status/refund/webhook endpoints.
- Refund pickup loop: rentals `refund_status='pending'` (incl. the 00800
  extension cases) + trial-rejection pending refunds → create
  `payment_refunds` records → Razorpay Refund API → `mark_refund_result`
  (only on `refund.processed` webhook or verified settled state).
- **Refund executor contract (round 2):** set
  `gateway_initiated_at` / `gateway_initiated_amount` on the pending refund
  record IMMEDIATELY after each Razorpay refund API call; a gateway-initiated
  pending refund is immutable. `mark_refund_result` automatically converts
  any `payment_items.refund_due_amount` remainder into a fresh pending record
  once the blocking refund settles — the pickup loop then processes it like
  any other pending refund.
- **Authorized-payment reconciliation job (round 2, §5.1):** every 5–10
  minutes, reconcile `authorized` payments past `expires_at` + grace by
  fetching the gateway state first; capture-or-cancel at the gateway; release
  inventory only after a terminal gateway state; late captures flow through
  the normal late-capture/auto-refund outcome.
- Seller dashboards: filter out expired trial requests
  (`payment_status='failed'`, `status='pending'`) so sellers never see
  actionable dead requests (§4.3).

**Phase 2 is complete and awaits review. No SQL has been executed and no
backend/Flutter code has been changed.**
