# Skill: Booking Simulator

> Load this skill when working on `backend/app/graph/nodes/booking.py`, `tools/availability.py`, `tools/bookings.py` or `tools/notifier.py`.
> Owner: `backend-engineer`.

## Purpose

Simulate a real-world booking end-to-end (this is the critical 15% rubric item):
1. Atomically hold a slot (no double-bookings).
2. Persist the booking to Supabase.
3. Generate a receipt and upload it to Supabase Storage.
4. Send a faux-WhatsApp confirmation.
5. Hand off to FollowupAgent.

## Database schema

```sql
-- Supabase: bookings table
-- Unique constraint: uq_worker_slot ON bookings(worker_id, slot_start)
CREATE TABLE bookings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id),
    worker_id   UUID REFERENCES workers(id),
    session_id  TEXT,
    service_type TEXT,
    slot_start  TIMESTAMPTZ NOT NULL,
    slot_end    TIMESTAMPTZ NOT NULL,
    status      TEXT NOT NULL,   -- worker_assigned | worker_accepted | en_route | arrived | in_progress | completed | cancelled | no_show
    price_estimate INT,
    final_price INT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    receipt_url TEXT
);

CREATE UNIQUE INDEX uq_worker_slot ON bookings(worker_id, slot_start)
    WHERE status NOT IN ('cancelled', 'no_show');
```

The `UNIQUE(worker_id, slot_start)` partial index is the **only** mechanism that prevents double-booking. Trust the DB.

## Atomic hold pattern

```python
# backend/app/tools/availability.py
class SlotConflict(Exception): ...

async def check_and_hold(worker_id: str, slot_start: datetime, slot_end: datetime, ...) -> BookingRecord:
    supabase = await get_supabase()
    try:
        result = await supabase.table("bookings").insert({
            "id": str(uuid4()),
            "worker_id": worker_id,
            "slot_start": slot_start.isoformat(),
            "slot_end": slot_end.isoformat(),
            "status": "worker_assigned",
            ...
        }).execute()
    except Exception as exc:
        err = str(exc)
        if "uq_worker_slot" in err or "23505" in err:
            raise SlotConflict(worker_id=worker_id, slot_start=slot_start) from exc
        # Non-slot-conflict errors are logged and fall through (best-effort write)
        import logging
        logging.getLogger(__name__).warning("Booking INSERT skipped (non-fatal): %s", exc)
    return BookingRecord(...)
```

Never check-then-insert with two separate queries: that's the race condition the resolver was built to catch, but we shouldn't rely on the resolver as a happy-path mechanism.

## BookingAgent flow

```python
# backend/app/graph/nodes/booking.py
async def run(state: RequestSession) -> RequestSession:
    async with emit_trace(state, agent="BookingAgent", phase="act", input={"provider_id": state.chosen.id}) as t:
        try:
            booking = await availability.check_and_hold(
                worker_id=state.chosen.id,
                slot_start=state.chosen.slot_start,
                slot_end=state.chosen.slot_end,
                user_id=state.user_id,
            )
            t.add_tool_call("Availability.check_and_hold", {...}, {"booking_id": booking.id})
        except SlotConflict as e:
            t.add_tool_call("Availability.check_and_hold", {...}, {"error": "SlotConflict"})
            await bus.publish("slot_conflict", {"session_id": state.id, "provider_id": e.worker_id})
            raise

        booking.status = "worker_accepted"
        receipt_url = await bookings.render_and_upload_receipt(booking, state.chosen, state.parsed_intent.location_hint)
        booking.receipt_url = receipt_url
        await bookings.persist(booking)
        t.add_tool_call("Bookings.create", {...}, {"booking_id": booking.id, "status": "worker_accepted"})

        msg = build_whatsapp_message(booking, state.chosen, state.parsed_intent.language)
        await notifier.send(channel="whatsapp_mock", to=state.user_phone, message=msg)
        t.add_tool_call("Notifier.send", {"channel": "whatsapp_mock"}, {"sent": True})

        state.booking = booking
        t.set_output({"booking_id": booking.id, "slot": booking.slot_start.isoformat()})
        t.set_reasoning(f"Booked {state.chosen.name} for {booking.slot_start.strftime('%H:%M')}; receipt #{booking.id[:8]}")

    return state
```

## Receipt rendering

`backend/app/tools/bookings.py::render_and_upload_receipt` produces a PNG using PIL, uploads it to the Supabase Storage `receipts` bucket and returns the public URL. The URL is stored in `bookings.receipt_url`. Layout (text-only, no logos to keep dependencies minimal):

```
KARIGAR: BOOKING CONFIRMATION
-----------------------------------
Booking ID:   {booking.id[:8]}
Service:      {ServiceType.pretty(booking.service_type)}   # "AC Technician", not "ac_technician"
Provider:     {provider.name}
Phone:        {provider.phone}        # synthetic 03XX-XXXXXXX (row omitted if empty)
Date:         {slot_start.strftime('%a, %d %b %Y')}
Time:         {slot_start.strftime('%H:%M')} - {slot_end.strftime('%H:%M')}
Location:     {location_hint}
Price (est):  Rs. {price_estimate}
-----------------------------------
Status:       CONFIRMED
Issued at:    {now.strftime('%H:%M, %d %b')}
```

The public URL is returned in the booking response body. The Flutter app loads it directly from Supabase Storage.

## Faux-WhatsApp message format

Always respond in `state.parsed_intent.language`. Template (Roman Urdu example):

```
*Karigar Booking Confirmed* ✅

Aap ka {service_type} {provider.name} ke saath book ho gaya hai.

🗓 *Date:* {date}
⏰ *Time:* {time}
📍 *Location:* {location_hint}
💰 *Price (est):* Rs. {price}
📞 *Provider:* {phone}

Booking ID: {booking.id[:8]}

Reply *CANCEL {booking.id[:8]}* to cancel.
```

Urdu and English variants live in `backend/app/tools/notifier.py::TEMPLATES`. Each template is short and has the same placeholders.

The Flutter app renders this exact string inside its faux-WhatsApp `screens/confirmation.dart` screen (green bubble, send-tick icons, "today" timestamp).

## Booking statuses + transitions

```
worker_assigned -> worker_accepted -> arrived -> in_progress -> completed
worker_assigned -> worker_accepted -> cancelled
worker_assigned -> worker_accepted -> no_show
```

State transitions live in `backend/app/tools/bookings.py::transition`. Only `worker_accepted` onwards is reachable from production code; `worker_assigned` is transient (only exists inside `check_and_hold`).

## API endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/bookings/{id}/cancel?rebook={true|false}` | User cancels. If `rebook=true`, publishes `user_cancellation` event so the resolver finds an alternative. |
| `GET` | `/bookings` | List bookings for the current user (optional filter by status). |
| `POST` | `/bookings/{id}/arrived` | Marks the provider as arrived (cancels the no-show watchdog). |
| `POST` | `/bookings/{id}/complete` | Marks `completed`; APScheduler also triggers this if no one calls it within `T+2h`. |

Receipts are served directly from Supabase Storage via `bookings.receipt_url`.

## Edge cases

- **`SlotConflict` on first try** -> see Conflict Resolver skill. Treat it like any other conflict event.
- **Provider phone missing** -> skip the Phone row on the receipt rather than printing a placeholder. Log a warning.
- **Receipt render fails** -> still persist the booking; `receipt_url = None`; Flutter shows a fallback receipt rendered client-side.
- **Notifier send fails** -> log + emit a `tool_call` with `result={"error": "..."}`; booking is still confirmed. We do **not** roll back (confirmation can be re-sent).
