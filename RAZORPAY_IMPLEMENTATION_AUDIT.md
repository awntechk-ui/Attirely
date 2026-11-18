# RAZORPAY IMPLEMENTATION AUDIT — Attirely Marketplace

**Phase 1 deliverable — no source code or database schema was modified.**

Audit date: 2026-11-17
Method: full source inspection (Flutter + FastAPI), live read-only introspection of the
Supabase schema via the PostgREST OpenAPI description (service-role credentials used
only for reading table/function metadata; no data was mutated).

---

## 1. Executive Summary

Attirely is a working multi-seller rental/trial marketplace (Flutter + FastAPI +
Supabase) that currently books rentals and trials with **dummy "paid" records**.
There is **no real payment system** anywhere in the stack, but groundwork already
exists:

- `razorpay==2.0.1` (Python SDK) is already pinned in `backend/requirements.txt`
  but imported nowhere.
- `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` are already present in `backend/.env`
  (verified as **test-mode** keys, `rzp_test_…`) but read nowhere.
- The rental checkout already performs **server-side** per-item financial
  calculation inside the PostgreSQL function `create_rental_booking`
  (rental amount, security deposit, platform fee, total). Only the *payment
  result* is faked.
- The trial checkout hardcodes fees in Python and Dart and inserts
  `payment_status='successful'` rows directly.

The integration therefore splits naturally:

| Workflow | Current state | Gap |
|---|---|---|
| Rental checkout | Server-calculated amounts, bookings created instantly as **paid** (dummy) | Need pending-payment reservation, Razorpay order, verification, confirmation |
| Trial checkout | Hardcoded fees, bookings created instantly as **paid** (dummy), no checkout screen | Need payment step, DB-driven fees, pending-payment model, refund path on rejection |

Missing pieces: payment tables, a payments API, a webhook endpoint, the
`razorpay_flutter` plugin, refund initiation, and expiry handling for unpaid
reservations (the rentals exclusion constraint makes unpaid reservations block
other customers).

---

## 2. Technology Versions (verified)

| Component | Version |
|---|---|
| Flutter | 3.51.0-0.1.pre (main channel, 2025-12-22), Dart 3.11.0 |
| FastAPI | 0.115.12 (Starlette 0.46.2, uvicorn 0.34.2) |
| supabase-py | 2.15.0 (postgrest 1.0.2, gotrue 2.12.4) |
| razorpay (Python SDK) | 2.0.1 — already in requirements, unused |
| razorpay_flutter (target) | 1.4.7 (published 2026-09-21; supports Dart ≥2.12 <4, Flutter ≥2.0 — compatible with Dart 3.11) |
| Android | Kotlin plugin, Java 17, min/targetSdk from Flutter defaults (`com.example.attirely`) |
| App base URL | `http://192.168.1.6:8000` (LAN IP, `lib/app_config.dart`) |

---

## 3. Backend Architecture

### 3.1 Layout

```
backend/
├── .env                        # SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
│                               # RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET (test mode)
├── requirements.txt
└── app/
    ├── main.py                 # FastAPI app, CORS (allow_origins=["*"]), 16 routers
    ├── core/
    │   ├── config.py           # loads SUPABASE_URL + SERVICE_ROLE_KEY from env
    │   ├── supabase.py         # supabase_admin (service role) + supabase_auth clients
    │   └── auth_dependency.py  # get_current_user, get_current_vendor
    ├── routes/                 # auth, vendor_routes, outfits, uoutfits, user_addresses,
    │   │                       # cart, accessory, user_profile, vendor_subscription,
    │   │                       # trails, rentals, location, vendor/* (4 sub-routers)
    │   ├── trial_request_router.py   # ⚠ NOT registered in main.py (dead code)
    │   └── ...
    ├── schemas/rentals.py      # Pydantic rental checkout models
    └── services/
        ├── rentals_service.py  # rental availability, booking, status management
        └── vendor_subscription_service.py
```

No `payments` module, router, service, schema or config exists yet.
No structured logging is used — everything is `print(...)`.

### 3.2 Authentication pattern (reusable)

- `get_current_user` — `HTTPBearer` token → `supabase_auth.auth.get_user(token)`.
  Returns the Supabase auth user; user ID is a UUID matching `users.id`.
- `get_current_vendor` — resolves `vendors` row by `auth_user_id`.
- All DB access uses `supabase_admin` (service role, bypasses RLS).

Payment endpoints should follow exactly this pattern.

### 3.3 Conventions to follow

- Routers declare `prefix` + `tags`; handlers are sync `def` (not async).
- Pydantic models are defined inline in route files or in `app/schemas/`.
- Errors: `HTTPException` with hand-written detail strings; bare `except Exception`
  with `print` logging; service-role client reused directly.

---

## 4. Frontend Architecture (Flutter)

### 4.1 Layout

```
frontend/lib/
├── main.dart / app_routes.dart / app_config.dart   # baseUrl = LAN IP
├── Common_Screens/  # login, register, splash, outfit details, session_manager (token),
│                    # API_Routes (auth/accessory/location), UI_Logic, transitions
├── User/
│   ├── U_API_Routes/  # cart, outfit, u_outfit, u_accessory, u_address, u_rental, u_trial
│   ├── U_Ui/          # user_cart, book_trial, rent_out, payment_security (rental checkout),
│   │                  # my_rentals, my_trials, home, outfits, profile, ...
│   └── U_Ui_Logic/    # ChangeNotifier logic classes per screen
└── Vendor/            # vendor_main, vendor_outfit, vendor_requests, vendor_bookings,
                       # vendor_subscription_plan, vendor API routes, logic
```

State management: plain `ChangeNotifier` singletons (`UserCartLogic.instance`,
`BookTrialLogic`, …) + `AnimatedBuilder`. No Provider/Riverpod/Bloc.
HTTP: `package:http` with `Bearer` token from `SessionManager` (flutter_secure_storage).

Design system observed: burgundy (`#4C1026`-family), dark green, ivory/off-white
backgrounds (`#F7F8F5`), gold accents — must be preserved.

### 4.2 One cart, two checkouts (verified)

`user_cart.dart` holds a single server-backed cart (`cart_items` table: user_id,
outfit_id, selected_size). Two distinct exits:

1. **`_rentOut()`** → collects available outfits → `RentOutPage(outfits)`
   (rental dates/duration/sizes chosen here) → **`PaymentSecurityPage`** —
   the rental checkout screen (4,659-line file with three commented-out older
   versions appended).
2. **`_openTrialPage()`** → all available outfits → `BookTrialPage(outfits)` —
   the trial checkout (sizes, per-outfit trial date + time slot, address,
   payment summary) → books directly.

There is no trial/rental flag on cart items; the same cart feeds both flows and
the user picks the workflow at exit. This already satisfies the "one cart, two
workflows" requirement — Razorpay integration must keep both exits separate.

### 4.3 Rental checkout flow today (`payment_security.dart`)

```
PaymentSecurityPage(outfits, deliveryAddress, rentalFee, securityDeposit,
                    coutureCareFee, ...)
totalDue (client-side) = rentalFee − coupon(10%) + coutureCareFee
                       + securityDeposit + platformFee(₹50 × outfits)
_confirmBooking():
  → builds items [{outfit_id, selected_size, rental_start_date, rental_days}]
  → RentalsApiRoutes.createRentalBooking(items, deliveryAddress)   // payment_method: 'dummy'
  → shows result dialog (successful_items / failed_items)
  → Navigator.pop(context, true)
```

Notes / conflicts found:
- `platformFeePerOutfit = 50` hardcoded in Dart.
- Fake coupon `HAUTE10` (10%) reduces the *displayed* total but the backend will
  charge the full calculated amount. Coupon must be removed or disabled for real
  payments (documented decision below).
- Cart removal after booking is commented out — bookings do not clear the cart
  (pre-existing behaviour; do not silently change).
- "Demo booking only. No real payment was collected." banner must be replaced.

### 4.4 Trial checkout flow today (`book_trial.dart` + `book_trial_logic.dart`)

```
BookTrialLogic:  trialChargePerOutfit = 150, platformFeePerOutfit = 50 (hardcoded)
_continuePayment():
  → logic.submitBooking() → POST /trials/book  (no payment screen at all)
  → success dialog "Trial Booked Successfully!" (backend already marked it paid)
```

The trial flow has **no payment screen**; a new payment step must be inserted
without redesigning `book_trial.dart`'s schedule/address UI.

### 4.5 History / cancellation screens

- `my_rentals_logic.dart` — cancel (PATCH `/rentals/{id}/cancel`, pending only),
  groups by `booking_reference`, displays `refund_amount` via the rentals table.
- `my_trials_logic.dart` — trial history display; **no cancel/refund path for
  trials exists anywhere** (see §7.3).

---

## 5. Database Schema (verified live via PostgREST introspection)

Tables present: `accessories, accessory_images, cart_items, outfit_images,
outfits, rentals, trial_requests, user_addresses, users,
vendor_account_deletion_jobs, vendor_notifications, vendor_plan,
vendor_subscriptions, vendor_trial_payment_audit_archive, vendors`.

There are **no SQL migration files in the repo** — the schema is managed
directly in Supabase. New migrations should be delivered as reviewed SQL files
(Phase 2) and executed in the Supabase SQL editor.

### 5.1 `outfits` (product source of truth; also used for both seller types)

Key columns: `id uuid pk`, `uploaded_by uuid` (owner auth user), `role text`
(`vendor` | `user`), `name`, `gender`, `occasion`, `category`,
`rental_price numeric`, `mrp numeric`, `security_deposit numeric`,
`size_type`, `sizes jsonb` (array, e.g. `["L"]`), `status` (`published`…),
`is_available boolean`, `measurements jsonb`, timestamps.

No per-product platform-fee or trial-fee columns exist — trial fee is currently
hardcoded (150) and platform fee hardcoded (50) in application code.

### 5.2 `cart_items`

`id, user_id→users, outfit_id→outfits, created_at, selected_size text` —
**outfits only. The `accessories` table exists but is NOT cartable**
(no FK/reference from cart). Accessories are a separate catalogue (own table +
images + upload routes). **Implication:** this Razorpay integration covers
outfit trials/rentals only; accessories cannot enter a checkout today. Do not
invent accessory checkout in this project phase.

### 5.3 `rentals` (verified full column list)

Financial: `rental_price_per_day, rental_amount, security_deposit_amount,
platform_fee, total_amount` (all `numeric`) — all computed server-side by the
booking function. Payment: `payment_status` (`pending|success|failed|refunded`),
`payment_method`, `transaction_reference`, `paid_at`. Refund:
`refund_amount`, `refunded_at`, `refund_status` (defaults present),
`cancelled_by_role`, `cancelled_by_user_id`, `cancellation_reason`.
Business: `status` (`pending|accepted|handed_over|rejected|completed|cancelled`),
`rent_method`, `responded_at`, `cancelled_at`, `completed_at`, `activated_at`.
Ownership: `user_id` (customer), `outfit_id`, `outfit_owner_user_id`,
`vendor_id` (nullable — NULL for individually-owned outfits).
Reservation: `booking_reference uuid` (shared across one checkout's items),
`delivery_address jsonb`, `rental_start_date/return_date/days`, `selected_size`.

- Exclusion constraint prevents overlapping **active** rentals per
  outfit+size (error surfaces as `prevent_overlapping_rentals`; Python error
  mapping already exists in `rentals_service.py`).
- ⚠ `payment_status='pending'` rows count as active in the availability
  check → unpaid reservations **block other customers** → expiry design is
  mandatory (§8.4).

### 5.4 `trial_requests` (verified full column list)

`id, booking_reference, user_id→users, vendor_id nullable→vendors, outfit_id→outfits,
user_name, outfit_name, selected_size, preferred_trial_date, preferred_time_slot,
trial_address jsonb, trial_method, status
(pending|accepted|handed_over|completed — note: `rejected` rows also exist via
the reject endpoints), rejection_reason, payment_status
(pending|successful|failed|refunded), payment_method, payment_reference,
trial_fee numeric, platform_fee numeric, trial_amount numeric,
accepted_at, completed_at, created_at, updated_at`.

- **No `outfit_owner_user_id` column** — ownership of individual-seller trial
  requests is resolved via `outfit_id → outfits.uploaded_by` (the insert code
  comments out an `outfit_owner_user_id` field that doesn't exist).
- Payment status vocabulary differs from rentals (`successful` vs `success`) —
  keep each table's own vocabulary to avoid breaking existing queries/UI.

### 5.5 `vendor_trial_payment_audit_archive`

Archive of deleted/processed trial requests (payment columns + timestamps +
`archived_at`). Written by something outside the app code (likely a DB trigger
or the vendor account deletion flow `prepare_vendor_account_deletion`).
**Must not be broken** by payment changes; inspect its trigger in Phase 2.

### 5.6 `users` / `vendors`

- `users`: `id uuid pk` (= auth uid), `email, full_name, phone_number, …`.
- `vendors`: `id uuid pk, auth_user_id uuid, store_name, full_name, …`.
- Vendor outfit: `outfits.role='vendor'`, owner = `uploaded_by`, `vendor_id`
  resolved via `vendors.auth_user_id`.
- Individual outfit: `outfits.role='user'`, owner = `uploaded_by`, `vendor_id = NULL`.
This exact resolution pattern is already implemented in `trails.py` (lines
162–181) and inside `create_rental_booking` — reuse it in payment services.

---

## 6. PostgreSQL Functions (existing)

Only three functions are exposed to PostgREST:
`create_rental_booking`, `manage_rental_status`, `prepare_vendor_account_deletion`.

⚠ **Limitation of this audit:** PostgREST does not expose function *bodies*, and
no `.sql` files exist in the repo. Signatures below were verified against the
working backend calls; bodies are known from the task brief + code behaviour.
**Phase 2 must begin by exporting the exact definitions** (SQL provided in the
Phase 2 doc) before touching them.

### 6.1 `create_rental_booking` (RPC, called per single item)

Verified call signature (from `rentals_service.py`):

```
create_rental_booking(
  p_user_id uuid, p_booking_reference uuid,
  p_items jsonb            -- [{outfit_id, selected_size, rental_start_date, rental_days}]
  p_payment_method text, p_transaction_reference text,
  p_platform_fee_per_outfit numeric/int, p_delivery_address jsonb
) → json  -- {success, rental_ids[], ...}
```

Behaviour (from brief + surrounding code): validates customer, delivery
address, locks outfit, validates size/status/availability, resolves vendor vs
individual ownership, computes `rental_amount`, `security_deposit_amount`,
`platform_fee`, `total_amount`, inserts the rental row — currently with
**`payment_status='success'`, `paid_at=NOW()`, dummy transaction reference**
if none supplied. The backend deliberately calls it once per outfit (each call
is its own transaction) and aggregates success/partial failure.

**Required change (Phase 2/3):** insert with `payment_status='pending'`,
no `paid_at`, `transaction_reference = NULL` (or the payment record ID), so a
booking only becomes paid after Razorpay verification. Keep all validation,
locking, exclusion-constraint behaviour intact.

### 6.2 `manage_rental_status` (RPC)

```
manage_rental_status(p_rental_id uuid, p_actor_user_id uuid,
                     p_action text, p_reason text, p_rent_method text)
```
Actions: accept / reject / cancel / handover / complete, with actor
authorization (vendor or individual outfit owner) and business rules. Python
side already maps PG error messages to HTTP codes. **Do not rewrite**; only
confirm refund hooks on `cancel` interact correctly with real payments.

### 6.3 `calculate_customer_rental_refund` (trigger function; not RPC-exposed)

Existing customer-cancel refund policy per the brief: refund =
`rental_amount + security_deposit − platform_fee` style calculation on
cancellation (platform fee retained). It writes `refund_amount`,
`refunded_at`, `refund_status` on `rentals`. **The calculated amount is a
policy number, not a gateway refund** — Razorpay refund initiation must be
added at the FastAPI layer using this value as the eligible amount.

### 6.4 `set_rental_outfit_image` (trigger function; not RPC-exposed)

Sets `rentals.outfit_image_url` on insert — keep untouched.

### 6.5 `update_trial_requests_updated_at` (trigger)

`updated_at` maintenance on `trial_requests` — keep untouched.

---

## 7. Existing Payment-Related Code (what gets replaced)

| Location | What exists | Disposition |
|---|---|---|
| `backend/app/routes/trails.py` `/trials/book` | Inserts trial rows with `payment_status='successful'`, `payment_method='dummy'`, `payment_reference='DUMMY-<uuid>'`, **hardcoded** `trial_fee=150, platform_fee=50, trial_amount=200` | Replace with pending-payment checkout + Razorpay; fees from DB |
| `backend/app/services/rentals_service.py` | `PLATFORM_FEE_PER_OUTFIT = 50`, `DEMO-<uuid>` transaction reference, passes `p_payment_method` from frontend | Fee from DB config; transaction ref = real payment; payment method = razorpay |
| `backend/app/schemas/rentals.py` | `payment_method: str = "demo"` | Deprecate |
| `frontend/.../u_rental_api_routes.dart` | `payment_method: 'dummy'` in request body | Remove |
| `frontend/.../payment_security.dart` | Demo payment screen, fake coupon, client-side total | Replace demo confirm with Razorpay checkout; keep UI layout/styling |
| `frontend/.../book_trial.dart` | Direct booking, "Trial Booked Successfully" dialog without payment | Insert payment step |
| `backend/app/routes/trial_request_router.py` | Legacy trial status router | **Not registered in main.py — dead code; leave as is** |

Backend routes for status management that stay untouched:
- `rentals.py`: my-rentals, vendor/requests, owner/requests, accept/reject/cancel/handover/complete.
- `vendor_trial_requests.py` (`/vendor/trial-requests`): owner-scoped
  accept/reject/handover/complete with `outfits.uploaded_by` authorization.
  **Reject currently does NOT trigger any refund or payment-status change** —
  with real money, a rejected (paid) trial must refund the customer (§9.3).

Also noted: `vendor_subscriptions` flow explicitly blocks paid plans with
`501 "Paid subscription activation is coming soon"` — out of scope here, but
the payment architecture (§8) should be generic enough to reuse later.

---

## 8. Gap Analysis — What Must Be Built

### 8.1 Database (Phase 2)

No payment tables exist. Required (names per task brief, adjusted to schema):

1. **`payments`** — one row per Razorpay order/checkout (user, checkout_type
   trial|rental, razorpay_order_id unique, razorpay_payment_id, amount (paise
   or numeric — decide paise for gateway ops), currency, status
   (`created|pending|captured|failed|cancelled|expired|partially_refunded|refunded`),
   gateway_status, failure_reason, payment_method, paid_at, expires_at, metadata jsonb).
2. **`payment_items`** — one row per booking item per payment (payment_id,
   booking_reference, booking_type, booking_id, outfit_id, seller_type
   vendor|individual, vendor_id nullable, seller_user_id, item_amount,
   rental_amount, trial_fee, security_deposit, platform_fee,
   refundable_amount, seller_payable_amount). Traceability + seller accounting.
3. **`seller_payables`** — per-item seller financial obligation (gross, platform
   fee, net payable, settlement_status) — recorded at confirmation; **no payouts**.
4. **`payment_refunds`** — booking-level and payment-level refunds
   (razorpay_refund_id unique, refund_type full|partial, status, failure_reason).
5. **`payment_webhook_events`** — raw event storage, `razorpay_event_id` unique,
   processing_status/error, idempotency.
6. **`payment_fee_settings`** — configurable `trial` and `rental` platform fees
   (replaces hardcoded 50/150/50). Admin/service-role writable only.
7. Modify `create_rental_booking` → pending-payment mode + confirmation
   function; add expiry function; RLS policies (backend uses service role, but
   policies must not break any future direct client access).

### 8.2 Backend (Phase 3)

New modules following existing conventions:

```
app/core/razorpay_config.py    # env: RAZORPAY_KEY_ID/SECRET, RAZORPAY_WEBHOOK_SECRET,
                               # currency, order timeout; never logs secrets
app/schemas/payments.py
app/services/payment_service.py  # CENTRAL state transitions (verification + webhook
                                 # both call this single implementation)
app/services/razorpay_client.py  # order create / payment fetch / refund create (SDK 2.0.1)
app/routes/payments.py           # POST /payments/checkout  (create order + reservations)
                                 # POST /payments/verify   (signature + gateway-state check)
                                 # GET  /payments/{id}     (status for reopen/retry)
                                 # POST /payments/{id}/refund   (initiate)
                                 # GET  /payments/{id}/refunds
                                 # POST /payments/webhook  (raw-body signature verify)
```

Key design points discovered during audit that shape this code:

- The RPC-per-item booking pattern (one transaction per item) conflicts with
  the "all-or-nothing per checkout" requirement. Safest approach: create a new
  RPC (e.g. `init_rental_checkout`) that reserves ALL items in ONE transaction,
  or accept partial reservation with clear semantics. Decision documented in
  Phase 2 after reading the real function body.
- `check_rental_availability` (Python) duplicates DB logic — reuse for
  pre-check; final authority remains the DB.
- Webhook endpoint must read the **raw request body** (Razorpay HMAC) — with
  FastAPI this means `Request` + manual body read, not a Pydantic model.
- CORS is `allow_origins=["*"]` with `allow_credentials=True` — no change
  required for mobile clients; webhook endpoint ignores CORS anyway.

### 8.3 Flutter (Phase 4)

- Add `razorpay_flutter: ^1.4.7`.
- New `U_API_Routes/payment_api_routes.dart` + a shared
  `PaymentCheckoutService` used by BOTH checkout screens.
- `payment_security.dart`: keep layout/styling; replace `_confirmBooking`
  demo call with: create checkout → open Razorpay → on success POST /verify
  → on verified response show booking result → on failure/cancel show retry.
  Never show success from the SDK callback alone.
- `book_trial.dart`: insert the same payment step before the existing success
  dialog (or reuse `payment_security`-style payment sheet).
- App-reopen recovery: on cart/checkout entry, query pending payment status
  (GET /payments/{id}) to reconcile.
- Trial history: show payment status; rental history already shows refunds.

### 8.4 Inventory-blocking risk (must design for)

Availability treats `status IN (pending, accepted, handed_over)` as active.
Unpaid `pending` rentals therefore block other customers for the same
outfit+size until expiry. Required mechanism:
- `payments.expires_at` (configurable, e.g. 15–20 min) mirrored on the
  payment record; a lazy-expiry check (on availability check / checkout init)
  plus an optional pg_cron job marks abandoned reservations as expired/cancelled
  so the exclusion constraint releases them.
- A **late successful payment after expiry must NOT confirm bookings** — the
  central transition service must reject captured payments whose reservations
  expired or conflict, and route them to automatic refund. The brief's
  "Do not introduce an invalid rental status" rule means expiry reuses existing
  statuses (`cancelled` with reason, or keep `pending` + expired payment) —
  final choice documented in Phase 2 after inspecting `manage_rental_status`'s
  exact status vocabulary and all frontend status filters
  (`my_rentals.dart`, `vendor_bookings.dart` rely on this vocabulary).

---

## 9. Policy Conflicts Found (must be resolved in Phase 2, documented decisions)

1. **Coupon `HAUTE10`** (rental checkout) reduces the displayed total by 10%
   but the backend charges the full amount. With real payments this becomes a
   real discrepancy. Safest: disable/hide the coupon in the checkout UI
   (display-only), charge the backend-calculated amount only.
2. **Trial rejection has no refund path** while payment is dummy today.
   With real payments, a paid trial rejected by the seller must refund.
   Existing Dart logic (`refundableAmount = totalPayable − platformFee`)
   suggests the intended policy: **refund trial fee, retain platform fee**.
   To be confirmed and implemented via `payment_refunds` + Razorpay.
3. **Rental cancel-refund trigger** already computes an eligible refund on
   customer cancellation; FastAPI must *initiate* the Razorpay refund using
   that amount and track it in `payment_refunds` (per-item for multi-item
   payments → partial refunds against one `razorpay_payment_id`).
4. **Status vocabulary mismatch** (`success` vs `successful`) between rentals
   and trial_requests — preserve each as-is.
5. **Partial booking success** (rental RPC per item) vs all-or-nothing
   checkout requirement — must be reconciled; see §8.2.
6. **`trial_requests` has no `outfit_owner_user_id`** — seller attribution for
   individual sellers resolves via `outfits.uploaded_by`; `payment_items`
   should store `seller_user_id` explicitly so seller payables don't depend on
   a join.

---

## 10. Reusable Assets (do not rebuild)

- `create_rental_booking` validation/locking/amount calculation logic.
- `manage_rental_status` authorization + state machine.
- `calculate_customer_rental_refund` refund policy.
- `check_rental_availability` pre-check endpoint.
- `trails.py` vendor/individual ownership resolution snippet (lines 161–181).
- `get_current_user` / `get_current_vendor` auth dependencies.
- `cart.py` ownership validation pattern (`_get_user_id`).
- Frontend `ChangeNotifier` + `*_api_routes.dart` patterns; `SessionManager`;
  cart logic (outfit enrichment, image resolution).
- `razorpay` Python SDK 2.0.1 already pinned; test keys already in `.env`.

---

## 11. Environment & Configuration Status

| Variable | Status |
|---|---|
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Present, loaded by `config.py` |
| `RAZORPAY_KEY_ID` | Present — **test mode** (`rzp_test_…`), unused |
| `RAZORPAY_KEY_SECRET` | Present (test), unused |
| `RAZORPAY_WEBHOOK_SECRET` | **Missing** — must be added (created in Razorpay Dashboard) |
| Flutter `baseUrl` | `http://192.168.1.6:8000` — Razorpay webhooks need a **publicly reachable** backend URL; document as a manual/deployment prerequisite |

Secrets handling: backend `.env` is git-ignored (backend/.gitignore exists);
Flutter must receive only `RAZORPAY_KEY_ID` (safe to ship) — never the secret
or webhook secret.

---

## 12. Proposed Implementation Plan (Phases 2–6)

**Phase 2 — Database design.** Produce `RAZORPAY_DATABASE_DESIGN.md` + reviewable
SQL migration files (`supabase/migrations/…`): new payment tables (§8.1),
`payment_fee_settings` with seed values (trial ₹150 total trial fee ₹150 + ₹50
platform fee and rental ₹50 platform fee matching current hardcoded values to
avoid behaviour change), pending-payment adaptation of `create_rental_booking`
(export real body first, patch minimally), confirmation RPC (transactional,
idempotent), expiry RPC, refund bookkeeping functions, RLS policies.

**Phase 3 — Backend.** `razorpay_config`, `payment_service` (single central
transition implementation), `payments` router (checkout/verify/status/refund/
webhook), idempotency (payment idempotency key + unique constraints),
structured logging without secrets, seller payables at confirmation.

**Phase 4 — Flutter.** `razorpay_flutter` 1.4.7, shared checkout service,
rewire `payment_security.dart` (rental) and `book_trial.dart` (trial),
pending-payment recovery and retry, success only after backend verification.

**Phase 5 — Testing.** Backend pytest (amount calculation, signature
verification with test vectors, webhook idempotency, refund eligibility),
`flutter analyze`, then Razorpay **test-mode** manual runs of the Part 14 test
matrix (test cards / test UPI). Results recorded honestly (executed vs not).

**Phase 6 — Report.** `RAZORPAY_IMPLEMENTATION_REPORT.md` per Part 15.

---

## 13. Open Items Requiring Input / Manual Steps

1. **Export actual SQL bodies** of `create_rental_booking`,
   `manage_rental_status`, `calculate_customer_rental_refund`,
   `set_rental_outfit_image`, trial/rental triggers and the rentals exclusion
   constraint from the Supabase SQL editor (Phase 2 provides an inspection
   script). PostgREST cannot show function bodies.
2. **RLS policies** on `rentals`, `trial_requests`, `cart_items`, `outfits` —
   not introspectable via PostgREST; export together with (1).
3. **Webhook secret** — create in Razorpay Dashboard (test mode) and add
   `RAZORPAY_WEBHOOK_SECRET` to `backend/.env`.
4. **Public backend URL** for Razorpay webhooks (currently LAN-only) —
   deployment target needed, or webhook testing via a tunnel (e.g. ngrok) in test mode.
5. **Confirm trial refund-on-reject policy** (proposal: refund trial fee,
   retain platform fee — consistent with existing Dart `refundableAmount`).
6. **Confirm coupon removal** from rental checkout display (display-only today).
7. Razorpay Dashboard settings: enable webhook events (payment.captured,
   payment.failed, refund.processed, …), confirm auto-capture configuration.

---

## 14. Conclusion

Phase 1 audit complete. The codebase is well-suited for a minimally invasive
Razorpay integration: amounts are already computed server-side for rentals,
seller resolution logic exists, and the one-cart/two-workflow structure already
matches the target design. The critical work is (a) converting "create booking
as paid" into "reserve → pay → confirm" for both workflows, (b) the new payment
database layer with idempotency and webhooks, (c) refunds at booking level with
gateway execution, and (d) inserting a payment step into the trial flow.
No existing vendor/individual-seller workflow, status management, or
cancellation logic needs to be replaced — only adapted.

---

## 15. Phase 2 Correction Pass

The Phase 2 review found six issues in the migration SQL. All are addressed in
this pass; the design doc (`RAZORPAY_DATABASE_DESIGN.md`) was updated
accordingly. Nothing has been executed; no backend/Flutter code changed.

### 15.1 `payment_items.updated_at` missing (trigger would fail on every UPDATE)

- `payment_items` had no `updated_at` column while `trg_payment_items_updated_at`
  → `payment_touch_updated_at()` assigns `NEW.updated_at`. Any UPDATE — most
  importantly `mark_refund_result` updating `refunded_amount` — would fail with
  "column \"updated_at\" of relation \"payment_items\" does not exist".
- **Fix:** the column (`timestamptz not null default now()`) is now part of the
  table definition in `20261117000200`. `mark_refund_result` verified against
  the new definition; regression test added (D39).

### 15.2 SECURITY DEFINER functions not execution-restricted

- Every new definer function was callable by `public` (Postgres default).
  Functions taking caller-supplied `p_user_id`/payment ids are unsafe to
  expose.
- **Fix:** every migration that creates definer functions now ends with
  `revoke execute … from public, anon, authenticated; grant execute … to
  service_role;` for each function:
  - 00100 `get_platform_fee`; 00400 `expire_stale_checkouts`,
    `expire_orphan_reservations`, `init_rental_checkout`; 00500
    `init_trial_checkout`; 00600 `register_razorpay_checkout`,
    `confirm_razorpay_payment`, `fail_razorpay_payment` (identity signature
    corrected to 4 args), `create_full_item_refund_records` (new); 00700
    `initiate_item_refund`, `initiate_full_payment_refund`,
    `mark_refund_result`, `handle_trial_rejection_refund`.
- All definer functions verified to carry `set search_path to 'public',
  'pg_temp'`. Owners keep implicit execute, so nested definer calls keep
  working. Migration 00800's `calculate_customer_rental_refund` stays a plain
  (non-definer) trigger function by design — its body only assigns `rentals`
  columns, so no RLS/grant concern exists.

### 15.3 Capture after seller rejection/cancellation lost verified money

- A seller rejecting a pending reservation before capture made
  `confirm_razorpay_payment` raise on the booking-count mismatch, aborting the
  transaction that contained the VERIFIED capture — a successful payment
  record was silently lost.
- **Fix:** the confirmable count is checked BEFORE updating bookings. On any
  mismatch the verified capture is recorded transactionally
  (`payment_status='captured'`), NOTHING is confirmed, the outcome is
  persisted (`metadata.confirmation_outcome='unconfirmable_refund_required'`,
  `requires_full_refund=true`) and pending full-refund records are created for
  every item via the new helper `create_full_item_refund_records(uuid, text)`.
  No `seller_payables` are created in that path. Both the verification and
  webhook paths call the same function, so they behave identically.
- The `expired`/`cancelled` late-capture branch was rewritten the same way
  (record capture + create refund records + persist outcome) instead of
  returning without recording.

### 15.4 `seller_payables` CHECK could roll back a verified capture

- `net_payable = gross_amount - platform_fee` with `net_payable >= 0` fails
  when the platform fee (₹50) exceeds the seller gross (e.g. ₹10 1-day
  rental), aborting the confirmation transaction AFTER money was verified.
- **Fix (interim rule, no silent business-model change):** CHECK is now
  `net_payable = greatest(gross_amount - platform_fee, 0)` plus a new
  `platform_subsidy = greatest(platform_fee - gross_amount, 0)` column; the
  payable INSERT uses the same clamping.
- **Product decisions flagged (design doc §7.1):** (1) allow negative
  `net_payable` = "seller owes platform" (needs settlement netting), (2)
  reject tiny-rental checkouts (minimum gross), (3) percentage fee instead of
  flat. None implemented without approval.

### 15.5 Late-capture replay was reported as ordinary success

- A replayed confirmation of a late capture returned `already_processed` +
  `success=true`, indistinguishable from a normal booking confirmation.
- **Fix:** every captured outcome is persisted in
  `payments.metadata->>'confirmation_outcome'`; replays return the ORIGINAL
  outcome (`confirmed` → success; `late_capture` /
  `unconfirmable_refund_required` → the same refund-required result, never
  success). Authorized-state replays are also handled idempotently.

### 15.6 Trial/rental detail corrections

- **`trial_method`:** /trials/book leaves the column unset; `init_trial_checkout`
  therefore keeps inserting NULL (no invented default) — semantics preserved
  and documented in the 00500 header.
- **Outfit publication/availability:** `init_rental_checkout` now validates
  `status='published'` and `is_available is true` (mirrors /trials/book).
- **`payment_status='refunded'` semantics:** a booking is marked `refunded`
  only when its ENTIRE refundable portion (rental + deposit / trial fee) is
  returned; the retained platform fee lives in the financial columns.
  `mark_refund_result` now enforces this; partial refunds keep
  `success`/`successful`.
- **Expired trials in seller dashboards:** they remain `status='pending'` with
  `payment_status='failed'`; **Phase 3 must filter them** from seller lists
  (documented in design doc §4.3 and §11). Auto-reject remains optional after
  DDL inspection.
- **Refund API `pending` responses:** documented as MUST NOT be passed to
  `mark_refund_result(processed)` — only a `refund.processed` webhook or
  verified settled gateway state counts (design doc §7, 00700 header).

### 15.7 Additional consistency fixes found during recheck

- Retry attempts on the same Razorpay order produce a NEW gateway payment id;
  the stored-id mismatch guards in `confirm_razorpay_payment` /
  `fail_razorpay_payment` previously rejected such retries. They now only
  enforce id authority in captured/authorized states.
- `mark_refund_result` clamps `seller_payables.refund_amount` against the
  remaining un-refunded seller gross (multi-refund safety).
- `fail_razorpay_payment` identity signature corrected to
  `(uuid, text, text, text)` in grants and rollback statements.

### 15.8 Recheck results

- Function references: all RPC names/signatures referenced by the design doc,
  test plan and rollback headers match the migration definitions (incl. the
  4-arg `fail_razorpay_payment` fix).
- Constraints: `seller_payables_net_matches` now self-consistent with the
  INSERT in `confirm_razorpay_payment`; `payment_items_amount_match` and the
  `updated_at` column verified.
- Trigger compatibility: `trg_payment_items_updated_at` now valid;
  `mark_refund_result` UPDATE on `payment_items` works (D39); trial-rejection
  trigger unchanged; 00800 trigger extension touches only `rentals` columns.
- Security grants: revoke/grant pairs present for all 13 definer functions;
  00800 intentionally unmodified.
- Rollback instructions: every header updated (new helper function,
  corrected signatures, grants-drop note).

### 15.9 Remaining product decisions (awaiting approval)

1. Platform fee > seller gross: keep the clamp+subsidy interim rule, or adopt
   "seller owes platform" / minimum-rental rules (design doc §7.1).
2. Partially-rejected multi-item checkout: whole-payment refund (current
   interim rule) vs. partial confirmation of still-valid items (§4.1).
3. Migration 00800 (rental seller-reject/cancel refunds) — OPTIONAL, still
   needs approval.
4. Migration 00900 (pg_cron) — OPTIONAL.
5. Expired-trial dashboard handling: Phase 3 dashboard filter (planned) vs.
   optional auto-reject migration later.

---

## 16. Phase 2 Correction Pass — Round 2

The second review found four remaining issues and one unresolved lifecycle
risk. All are addressed below; nothing has been executed and no backend or
Flutter code has been modified.

### 16.1 `payment_items.seller_payable_amount` could violate its CHECK

- `register_razorpay_checkout` still computed
  `seller_payable_amount = rental_amount - platform_fee` /
  `trial_fee - platform_fee`, which is negative when the platform fee exceeds
  the seller gross — a `seller_payable_amount >= 0` CHECK violation that would
  abort checkout registration.
- **Fix:** both inserts now use `greatest(gross - fee, 0)` and set the NEW
  `payment_items.platform_subsidy` column (`greatest(fee - gross, 0)`),
  consistent with `seller_payables` (migration 00300). Subsidy accounting is
  preserved end-to-end: item → payable.

### 16.2 Capture / seller-rejection race could still roll back a capture

- The confirmable count and the booking updates were not serialized: a
  concurrent seller rejection between them still produced
  `v_confirmed <> v_expected` and rolled back a verified capture.
- **Fix:** `confirm_razorpay_payment` now locks ALL bookings of the checkout
  `FOR UPDATE` in a stable order (`ORDER BY id`) BEFORE counting. A
  concurrent rejection either commits before the locks (counted as
  unconfirmable → whole-payment refund path) or waits until after our commit.
  The count and updates observe the same row states; the whole-payment refund
  policy is preserved. Lock order (`payments` → bookings) cannot deadlock
  against `manage_rental_status` (single-row locks). The post-update
  mismatch raise is now unreachable by race (documented as a bug-only
  safeguard whose rollback converges correctly on replay).

### 16.3 Full refund after an existing pending partial refund was under-recorded

- `create_full_item_refund_records` used `ON CONFLICT DO NOTHING`: with a
  smaller pending refund already blocking the unique
  one-pending-per-booking index, the full-refund remainder was silently
  dropped.
- **Fix — safe reconciliation mechanism:**
  - New `payment_refunds.gateway_initiated_at` / `gateway_initiated_amount`
    columns (00300). Phase 3 contract: set immediately after the Razorpay
    refund API call; a gateway-initiated pending refund is IMMUTABLE.
  - `create_full_item_refund_records` now reconciles per item:
    no pending record → insert the full remainder; pending record not yet
    handed to the gateway → TOP IT UP (single gateway refund, no duplicate);
    pending record already handed to the gateway → record the uncovered
    remainder durably in the NEW `payment_items.refund_due_amount` column.
  - NEW `convert_refund_due_to_pending_refund(uuid)` (00700), automatically
    invoked by `mark_refund_result` on every processed AND failed result:
    once the blocking refund settles and frees the unique index slot, the
    deferred remainder becomes a fresh PENDING refund record (gateway-neutral).
  - `initiate_item_refund` / `initiate_full_payment_refund` subtract
    `refund_due_amount` from the remaining refundable amount, so the
    deferred obligation can never be double-recorded.
  - Lock ordering documented and aligned: `payment_refunds` before
    `payment_items` in `create_full_item_refund_records` (same as
    `mark_refund_result`) so the two cannot deadlock — a deadlock there
    would roll back a verified capture.

### 16.4 Orphan reservations could live indefinitely without pg_cron

- `init_rental_checkout` (and `init_trial_checkout`) called only
  `expire_stale_checkouts()`; `expire_orphan_reservations()` depended on the
  OPTIONAL pg_cron schedule.
- **Fix:** both init functions now call `expire_orphan_reservations()` lazily
  (its 1-day grace period keeps this harmless), and two partial indexes
  (`rentals_pending_created_idx`, `trial_requests_pending_created_idx`) keep
  the lazy scans cheap as tables grow. Orphan cleanup no longer depends on
  pg_cron at all; migration 00900 remains a pure convenience layer.

### 16.5 Authorized-but-never-captured payments — Phase 3 contract documented

- Documented in design doc **§5.1**: authorized payments are never auto-
  expired; the Phase 3 reconciliation job (every 5–10 min, after
  `expires_at` + grace) must (1) fetch the AUTHORITATIVE gateway state via
  the Razorpay payment-fetch API, (2) for `captured` run the normal confirm
  flow (confirmable → confirmed, else late-capture full refund), (3) for
  still-`authorized` capture-or-cancel at the gateway (Razorpay allows
  cancelling authorized payments — endpoint to be verified against current
  docs at Phase 3 build time), (4) release inventory via
  `expire_stale_checkouts()` ONLY after the gateway state is terminal, (5)
  route any late capture after release through the recorded-capture +
  full-refund outcome, (6) keep every step idempotent/re-runnable.

### 16.6 Recheck results (round 2)

- **Constraints:** `seller_payable_amount`/`platform_subsidy` on
  `payment_items` consistent with the `seller_payables` CHECK and the
  `confirm_razorpay_payment` payable INSERT; `refund_due_amount >= 0` cannot
  go negative (clamped increments + cleared when over-covered);
  `gateway_amount_paise` recomputed on top-up so the paise CHECK holds.
- **Function signatures:** `create_full_item_refund_records` still
  `(uuid, text)` (now `returns jsonb` with created/topped-up/deferred counts
  — `perform` callers unaffected); NEW
  `convert_refund_due_to_pending_refund(uuid)` added to grants and rollback;
  all other signatures unchanged.
- **Trigger behaviour:** `trg_payment_items_updated_at` fires on the new
  `refund_due_amount`/`subsidy` updates (updated_at column present);
  `trg_trial_rejection_refund` unaffected; trial-rejection refunds can now be
  safely topped up by a later full-refund requirement.
- **Grants:** revoke/grant pairs present for all 14 definer functions
  (13 previous + the conversion helper); 00800 still intentionally
  unmodified; owners retain implicit execute for nested definer calls.
- **Rollback instructions:** 00400 header gains the two index drops; 00600
  header unchanged signatures + round-2 notes; 00700 rollback adds the
  conversion helper; 00200/00300 corrections documented in headers (tables
  dropped wholly, so no per-column rollback needed).

### 16.7 Final Phase 2 state

- 9 migration files, all consistent with `RAZORPAY_DATABASE_DESIGN.md`
  (§2.1 security, §4.1 outcome persistence/replay, §5.1 authorized-payment
  reconciliation, §7 refund architecture + reconciliation, §7.1 fee>gross
  alternatives, §9 risks, §10 test plan D1–D47, §11 Phase 3 duties).
- 14 SECURITY DEFINER functions, all backend-only with explicit
  revoke/grant and safe search_path.
- Verified money can never be lost to: payable CHECK violations, concurrent
  seller rejections, booking-count races, immutable-pending-refund
  collisions, orphan reservations without cron, or authorized-then-expired
  payments.
- **Remaining product decisions unchanged from §15.9** (fee>gross policy,
  partial confirmation, optional migrations 00800/00900, expired-trial
  dashboard handling).
- **Phase 2 is complete and awaits final approval. No SQL has been executed;
  no backend/Flutter code has been changed; Phase 3 not started.**
