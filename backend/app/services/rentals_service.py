
from datetime import timedelta
from uuid import uuid4

from fastapi import HTTPException

from app.core.supabase import supabase_admin


ACTIVE_STATUSES = ["pending", "accepted", "handed_over"]

PLATFORM_FEE_PER_OUTFIT = 50


# ==========================================================
# CHECK OUTFIT AVAILABILITY
# ==========================================================

def check_rental_availability(items):

    results = []

    for item in items:

        outfit_id = str(item.outfit_id)
        selected_size = item.selected_size.strip()

        start_date = item.rental_start_date
        rental_days = item.rental_days

        return_date = start_date + timedelta(
            days=rental_days - 1
        )

        # Fetch outfit
        outfit_response = (
            supabase_admin
            .table("outfits")
            .select("id, name, sizes")
            .eq("id", outfit_id)
            .limit(1)
            .execute()
        )

        if not outfit_response.data:

            results.append({
                "outfit_id": item.outfit_id,
                "selected_size": selected_size,
                "rental_start_date": start_date,
                "rental_return_date": return_date,
                "rental_days": rental_days,
                "available": False,
                "message": "Outfit not found"
            })

            continue

        outfit = outfit_response.data[0]

        available_sizes = outfit.get("sizes") or []

        if selected_size not in available_sizes:

            results.append({
                "outfit_id": item.outfit_id,
                "selected_size": selected_size,
                "rental_start_date": start_date,
                "rental_return_date": return_date,
                "rental_days": rental_days,
                "available": False,
                "message": "Selected size is unavailable"
            })

            continue

        # Check overlapping rental records
        existing_rental = (
            supabase_admin
            .table("rentals")
            .select("id")
            .eq("outfit_id", outfit_id)
            .eq("selected_size", selected_size)
            .in_("status", ACTIVE_STATUSES)
            .lte(
                "rental_start_date",
                return_date.isoformat()
            )
            .gte(
                "rental_return_date",
                start_date.isoformat()
            )
            .limit(1)
            .execute()
        )

        is_available = not bool(existing_rental.data)

        results.append({
            "outfit_id": item.outfit_id,
            "selected_size": selected_size,
            "rental_start_date": start_date,
            "rental_return_date": return_date,
            "rental_days": rental_days,
            "available": is_available,
            "message": (
                "Outfit is available"
                if is_available
                else "Outfit is already booked for these dates"
            )
        })

    return {
        "all_available": all(
            item["available"] for item in results
        ),
        "items": results
    }


# ==========================================================
# CREATE RENTAL BOOKING - PARTIAL BOOKING
# ==========================================================

def create_rental_booking(user_id, request):

    booking_reference = str(uuid4())

    # One demo transaction reference for the complete checkout.
    transaction_reference = f"DEMO-{uuid4()}"

    successful_items = []
    failed_items = []
    rental_ids = []

    for item in request.items:

        outfit_id = str(item.outfit_id)
        selected_size = item.selected_size.strip()

        item_details = {
            "outfit_id": outfit_id,
            "selected_size": selected_size,
            "rental_start_date": item.rental_start_date.isoformat(),
            "rental_days": item.rental_days,
        }

        try:

            # IMPORTANT:
            # Send exactly ONE outfit per RPC call.
            # Each RPC call has its own database transaction.
            response = supabase_admin.rpc(
                "create_rental_booking",
                {
                    "p_user_id": str(user_id),
                    "p_booking_reference": booking_reference,

                    # Send only the current outfit.
                    "p_items": [item_details],

                    "p_payment_method": request.payment_method,

                    # Use the transaction reference generated at checkout.
                    "p_transaction_reference": transaction_reference,

                    "p_platform_fee_per_outfit": PLATFORM_FEE_PER_OUTFIT,

                    "p_delivery_address": request.delivery_address
                }
            ).execute()


            result = response.data

            if not result or not result.get("success"):
                raise Exception(
                    "Rental booking was not confirmed by the database."
                )

            created_ids = result.get("rental_ids") or []

            if not created_ids:
                raise Exception(
                    "The database did not return a rental ID."
                )

            rental_id = str(created_ids[0])

            rental_ids.append(rental_id)

            successful_items.append({
                **item_details,
                "rental_id": rental_id,
                "status": "pending",
                "message": "Rental request successfully placed.",
            })

        except Exception as error:

            print(
                f"RENTAL BOOKING FAILED FOR OUTFIT {outfit_id}:",
                repr(error)
            )

            failed_items.append({
                **item_details,
                "status": "failed",
                "message": _get_rental_failure_message(error),
            })

            # Continue processing the remaining outfits.
            continue

    successful_count = len(successful_items)
    failed_count = len(failed_items)

    # At least one outfit must be booked for success=True.
    success = successful_count > 0

    partial_success = (
        successful_count > 0 and failed_count > 0
    )

    if successful_count == 0:
        message = "No outfits could be booked. Please review the failures."

    elif partial_success:
        message = (
            f"{successful_count} outfit(s) booked successfully. "
            f"{failed_count} outfit(s) could not be booked."
        )

    else:
        message = "All rental requests were successfully placed."

    return {
        "success": success,
        "partial_success": partial_success,
        "booking_reference": booking_reference,
        "transaction_reference": transaction_reference,
        "total_outfits": len(request.items),
        "successful_count": successful_count,
        "failed_count": failed_count,
        "rental_ids": rental_ids,
        "successful_items": successful_items,
        "failed_items": failed_items,
        "message": message,
    }


# ==========================================================
# CUSTOMER RENTALS
# ==========================================================

def get_customer_rentals(user_id):

    response = (
        supabase_admin
        .table("rentals")
        .select("*")
        .eq("user_id", str(user_id))
        .order("created_at", desc=True)
        .execute()
    )

    return response.data or []


# ==========================================================
# VENDOR RENTAL REQUESTS
# ==========================================================

def get_vendor_rentals(vendor_id):

    response = (
        supabase_admin
        .table("rentals")
        .select("*")
        .eq("vendor_id", str(vendor_id))
        .order("created_at", desc=True)
        .execute()
    )

    return response.data or []


# ==========================================================
# OUTFIT OWNER RENTAL REQUESTS
# ==========================================================

def get_owner_rentals(owner_user_id):

    owner_user_id = str(owner_user_id)

    # ---------------------------------------------
    # 1. Fetch individual-owner bookings
    # ---------------------------------------------

    owner_response = (
        supabase_admin
        .table("rentals")
        .select("*")
        .eq("outfit_owner_user_id", owner_user_id)
        .order("created_at", desc=True)
        .execute()
    )

    owner_rentals = owner_response.data or []

    # ---------------------------------------------
    # 2. Find vendor profile belonging to this user
    # ---------------------------------------------

    vendor_response = (
        supabase_admin
        .table("vendors")
        .select("id")
        .eq("auth_user_id", owner_user_id)
        .limit(1)
        .execute()
    )

    vendor_rentals = []

    if vendor_response.data:

        vendor_id = str(vendor_response.data[0]["id"])

        # -----------------------------------------
        # 3. Fetch registered-vendor bookings
        # -----------------------------------------

        vendor_booking_response = (
            supabase_admin
            .table("rentals")
            .select("*")
            .eq("vendor_id", vendor_id)
            .order("created_at", desc=True)
            .execute()
        )

        vendor_rentals = vendor_booking_response.data or []

    # ---------------------------------------------
    # 4. Merge bookings without duplicates
    # ---------------------------------------------

    combined = {
        rental["id"]: rental
        for rental in owner_rentals
    }

    for rental in vendor_rentals:
        combined[rental["id"]] = rental

    rentals = list(combined.values())

    rentals.sort(
        key=lambda rental: rental.get("created_at") or "",
        reverse=True
    )

    # ---------------------------------------------
    # 5. Fetch customer details
    # ---------------------------------------------

    customer_ids = list({
        rental["user_id"]
        for rental in rentals
        if rental.get("user_id")
    })

    customers = {}

    if customer_ids:

        users_response = (
            supabase_admin
            .table("users")
            .select("id, full_name, phone_number")
            .in_("id", customer_ids)
            .execute()
        )

        customers = {
            user["id"]: user
            for user in (users_response.data or [])
        }

    # ---------------------------------------------
    # 6. Attach customer details
    # ---------------------------------------------

    for rental in rentals:

        customer = customers.get(
            rental.get("user_id"),
            {}
        )

        address = rental.get("delivery_address") or {}

        rental["customer_name"] = (
            customer.get("full_name")
            or address.get("full_name")
            or "Customer"
        )

        rental["customer_phone"] = (
            customer.get("phone_number")
            or address.get("mobile")
            or ""
        )

    return rentals
# ==========================================================
# MANAGE RENTAL STATUS
# ==========================================================


def manage_rental_status(
    rental_id,
    actor_user_id,
    action,
    reason=None,
    rent_method=None
):
    expected_statuses = {
        "accept": "accepted",
        "reject": "rejected",
        "cancel": "cancelled",
        "handover": "handed_over",
        "complete": "completed",
    }

    expected_status = expected_statuses.get(action)

    if not expected_status:
        raise HTTPException(
            status_code=400,
            detail="Invalid rental action"
        )

    try:
        # Execute the database function.
        # Do not depend on response.data being a JSON dictionary.
        supabase_admin.rpc(
            "manage_rental_status",
            {
                "p_rental_id": str(rental_id),
                "p_actor_user_id": str(actor_user_id),
                "p_action": action,
                "p_reason": reason,
                "p_rent_method": rent_method,
            }
        ).execute()

    except Exception as e:
        print("RENTAL RPC RESPONSE ERROR:", repr(e))

        # The RPC may have updated the database successfully
        # even if its response could not be parsed.
        try:
            verification = (
                supabase_admin
                .table("rentals")
                .select("id, status, rent_method")
                .eq("id", str(rental_id))
                .limit(1)
                .execute()
            )

            rows = verification.data or []

            if (
                rows
                and rows[0].get("status") == expected_status
                and (
                    action != "accept"
                    or rows[0].get("rent_method") == rent_method
                )
            ):
                print(
                    f"RENTAL STATUS VERIFIED: "
                    f"{rental_id} -> {expected_status}"
                )

                return {
                    "success": True,
                    "rental_id": str(rental_id),
                    "action": action,
                    "status": expected_status,
                    "message": "Rental status updated successfully",
                }

        except Exception as verify_error:
            print(
                "RENTAL STATUS VERIFICATION ERROR:",
                repr(verify_error)
            )

        # If the database was not updated, handle the original error.
        error_message = str(e)
        lower_error = error_message.lower()

        if "rental not found" in lower_error:
            raise HTTPException(
                status_code=404,
                detail="Rental not found"
            )

        if (
            "not authorized" in lower_error
            or "only outfit owner" in lower_error
        ):
            raise HTTPException(
                status_code=403,
                detail=error_message
            )

        if (
            "only pending" in lower_error
            or "only accepted" in lower_error
            or "only handed-over" in lower_error
            or "only handed over" in lower_error
            or "only active" in lower_error
            or "return date" in lower_error
            or "rental return date" in lower_error
        ):
            raise HTTPException(
                status_code=409,
                detail=error_message
            )

        if (
            "reason is required" in lower_error
            or "invalid rental action" in lower_error
        ):
            raise HTTPException(
                status_code=400,
                detail=error_message
            )

        raise HTTPException(
            status_code=500,
            detail="Failed to update rental status"
        )

    # Verify the final database status after the RPC.
    try:
        verification = (
            supabase_admin
            .table("rentals")
            .select("id, status, rent_method")
            .eq("id", str(rental_id))
            .limit(1)
            .execute()
        )

        rows = verification.data or []

        if not rows:
            raise HTTPException(
                status_code=404,
                detail="Rental not found after status update"
            )

        actual_status = rows[0].get("status")

        if actual_status != expected_status:
            raise HTTPException(
                status_code=409,
                detail=f"Rental status is {actual_status}, "
                       f"expected {expected_status}"
            )
        if action == "accept" and rows[0].get("rent_method") != rent_method:
            raise HTTPException(
                status_code=409,
                detail="Rental method was not saved correctly"
            )

        return {
            "success": True,
            "rental_id": str(rental_id),
            "action": action,
            "status": actual_status,
            "message": "Rental status updated successfully",
        }

    except HTTPException:
        raise

    except Exception as e:
        print("RENTAL STATUS VERIFICATION ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Rental was updated, but status verification failed"
        )



def _get_rental_failure_message(error):
    """Convert database errors into readable messages."""

    error_message = str(error)
    lower_error = error_message.lower()

    if (
        "prevent_overlapping_rentals" in lower_error
        or "exclusion constraint" in lower_error
        or "conflicting key" in lower_error
    ):
        return (
            "This outfit and selected size are already "
            "booked for these dates."
        )

    if "selected size" in lower_error or "size" in lower_error:
        return "The selected size is unavailable."

    if "outfit" in lower_error and "not found" in lower_error:
        return "This outfit no longer exists."

    if "vendor profile not found" in lower_error:
        return "The outfit owner's vendor profile could not be found."

    if "customer account not found" in lower_error:
        return "Your customer account could not be found."

    if "invalid rental details" in lower_error:
        return "The rental details are invalid."

    if "invalid outfit ownership role" in lower_error:
        return "The outfit owner information is invalid."

    return "Unable to book this outfit. Please try again."



# def _get_rental_failure_message(error):
#     """Convert database errors into readable outfit-level messages."""

#     error_message = str(error)
#     lower_error = error_message.lower()

#     if (
#         "prevent_overlapping_rentals" in lower_error
#         or "exclusion constraint" in lower_error
#         or "conflicting key" in lower_error
#     ):
#         return "This outfit and selected size are already booked for these dates."

#     if "selected size" in lower_error or "size" in lower_error:
#         return "The selected size is unavailable."

#     if "outfit" in lower_error and "not found" in lower_error:
#         return "This outfit no longer exists."

#     if "vendor profile not found" in lower_error:
#         return "The outfit owner's vendor profile could not be found."

#     if "customer account not found" in lower_error:
#         return "Your customer account could not be found."

#     if "invalid rental details" in lower_error:
#         return "The rental details are invalid."

#     if "invalid outfit ownership role" in lower_error:
#         return "The outfit owner information is invalid."

#     return "Unable to book this outfit. Please try again."


# # ==========================================================
# # CREATE RENTAL BOOKING - PARTIAL BOOKING
# # ==========================================================

# def create_rental_booking(user_id, request):

#     booking_reference = str(uuid4())

#     # One demo transaction reference for the complete checkout.
#     transaction_reference = f"DEMO-{uuid4()}"

#     successful_items = []
#     failed_items = []
#     rental_ids = []

#     for item in request.items:

#         outfit_id = str(item.outfit_id)
#         selected_size = item.selected_size.strip()

#         item_details = {
#             "outfit_id": outfit_id,
#             "selected_size": selected_size,
#             "rental_start_date": item.rental_start_date.isoformat(),
#             "rental_days": item.rental_days,
#         }

#         try:

#             # IMPORTANT:
#             # Send exactly ONE outfit per RPC call.
#             # Each RPC call has its own database transaction.
#             response = supabase_admin.rpc(
#                 "create_rental_booking",
#                 {
#                     "p_user_id": str(user_id),
#                     "p_booking_reference": booking_reference,
#                     "p_items": [item_details],
#                     "p_payment_method": request.payment_method,
#                     "p_transaction_reference": transaction_reference,
#                     "p_platform_fee_per_outfit": (
#                         PLATFORM_FEE_PER_OUTFIT
#                     ),
#                 }
#             ).execute()

#             result = response.data

#             if not result or not result.get("success"):
#                 raise Exception(
#                     "Rental booking was not confirmed by the database."
#                 )

#             created_ids = result.get("rental_ids") or []

#             if not created_ids:
#                 raise Exception(
#                     "The database did not return a rental ID."
#                 )

#             rental_id = str(created_ids[0])

#             rental_ids.append(rental_id)

#             successful_items.append({
#                 **item_details,
#                 "rental_id": rental_id,
#                 "status": "pending",
#                 "message": "Rental request successfully placed.",
#             })

#         except Exception as error:

#             print(
#                 f"RENTAL BOOKING FAILED FOR OUTFIT {outfit_id}:",
#                 repr(error)
#             )

#             failed_items.append({
#                 **item_details,
#                 "status": "failed",
#                 "message": _get_rental_failure_message(error),
#             })

#             # Continue processing the remaining outfits.
#             continue

#     successful_count = len(successful_items)
#     failed_count = len(failed_items)

#     # At least one outfit must be booked for success=True.
#     success = successful_count > 0

#     partial_success = (
#         successful_count > 0 and failed_count > 0
#     )

#     if successful_count == 0:
#         message = "No outfits could be booked. Please review the failures."

#     elif partial_success:
#         message = (
#             f"{successful_count} outfit(s) booked successfully. "
#             f"{failed_count} outfit(s) could not be booked."
#         )

#     else:
#         message = "All rental requests were successfully placed."

#     return {
#         "success": success,
#         "partial_success": partial_success,
#         "booking_reference": booking_reference,
#         "transaction_reference": transaction_reference,
#         "total_outfits": len(request.items),
#         "successful_count": successful_count,
#         "failed_count": failed_count,
#         "rental_ids": rental_ids,
#         "successful_items": successful_items,
#         "failed_items": failed_items,
#         "message": message,
#     }
