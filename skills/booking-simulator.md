# Skill: Booking Simulator

> Load this skill when working on `backend/app/graph/nodes/booking.py`, `tools/availability.py`, `tools/bookings.py` or `tools/notifier.py`.
> Owner: `backend-engineer`.

## Purpose

Simulate a real-world booking end-to-end (this is the critical 15% rubric item):
1. Atomically hold a slot (no double-bookings).
2. Persist the booking to SQLite.
3. Generate a receipt.
4. Send a faux-WhatsApp confirmation.
5. Hand off to FollowupAgent.

## Database schema

```python
# backend/app/db/models.py
class Booking(Base):
    __tablename__ = "bookings"
    id: Mapped[str] = mapped_column(primary_key=True)   # ulid
    user_id: Mapped[str]
    provider_id: Mapped[str]
    service_type: Mapped[str]
    slot_start: Mapped[datetime]
    slot_end: Mapped[datetime]
    status: Mapped[str]                                  # PENDING | CONFIRMED | CANCELLED | COMPLETED | NO_SHOW
    price_estimate: Mapped[int]
    created_at: Mapped[datetime] = mapped_column(default=func.now())
    receipt_png_path: Mapped[Optional[str]]

    __table_args__ = (
        UniqueConstraint("provider_id", "slot_start", name="uq_provider_slot"),
    )
```

The `UNIQUE(provider_id, slot_start)` constraint is the **only** mechanism that prevents double-booking. Trust the DB.

## Atomic hold pattern

```python
# backend/app/tools/availability.py
class SlotConflict(Exception): ...

async def check_and_hold(provider_id: str, slot_start: datetime, slot_end: datetime, user_id: str) -> Booking:
    async with session.begin():
        booking = Booking(
            id=str(ulid.new()),
            user_id=user_id,
            provider_id=provider_id,
            slot_start=slot_start,
            slot_end=slot_end,
            status="PENDING",
            ...
        )
        session.add(booking)
        try:
            await session.flush()           # triggers the UNIQUE constraint
        except IntegrityError as e:
            raise SlotConflict(provider_id, slot_start) from e
    return booking
```

Never check-then-insert with two separate queries: that's the race condition the resolver was built to catch, but we shouldn't rely on the resolver as a happy-path mechanism.

## BookingAgent flow

```python
# backend/app/graph/nodes/booking.py
async def run(state: RequestSession) -> RequestSession:
    async with emit_trace(state, agent="BookingAgent", phase="act", input={"provider_id": state.chosen.id}) as t:
        try:
            booking = await availability.check_and_hold(
                provider_id=state.chosen.id,
                slot_start=state.chosen.slot_start,
                slot_end=state.chosen.slot_end,
                user_id=state.user_id,
            )
            t.add_tool_call("Availability.check_and_hold", {...}, {"booking_id": booking.id})
        except SlotConflict as e:
            t.add_tool_call("Availability.check_and_hold", {...}, {"error": "SlotConflict"})
            await bus.publish("slot_conflict", {"session_id": state.id, "provider_id": e.provider_id})
            raise

        booking.status = "CONFIRMED"
        receipt_path = await bookings.render_receipt(booking, state.chosen)
        booking.receipt_png_path = receipt_path
        await bookings.persist(booking)
        t.add_tool_call("Bookings.create", {...}, {"booking_id": booking.id, "status": "CONFIRMED"})

        msg = build_whatsapp_message(booking, state.chosen, state.parsed_intent.language)
        await notifier.send(channel="whatsapp_mock", to=state.user_phone, message=msg)
        t.add_tool_call("Notifier.send", {"channel": "whatsapp_mock"}, {"sent": True})

        state.booking = booking
        t.set_output({"booking_id": booking.id, "slot": booking.slot_start.isoformat()})
        t.set_reasoning(f"Booked {state.chosen.name} for {booking.slot_start.strftime('%H:%M')}; receipt #{booking.id[:8]}")

    return state
```

## Receipt rendering

`backend/app/tools/bookings.py::render_receipt` produces a PNG at `backend/runtime/receipts/<booking_id>.png` using PIL. Layout (text-only, no logos to keep dependencies minimal):

```
KARIGAR: BOOKING CONFIRMATION
-----------------------------------
Booking ID:   {booking.id[:8]}
Service:      {ServiceType.pretty(booking.service_type)}   # "AC Technician", not "ac_technician"
Provider:     {provider.name}
Phone:        {provider.phone}        # synthetic 03XX-XXXXXXX
Date:         {slot_start.strftime('%a, %d %b %Y')}
Time:         {slot_start.strftime('%H:%M')} - {slot_end.strftime('%H:%M')}
Location:     {location_hint}
Price (est):  Rs. {price_estimate}
-----------------------------------
Status:       CONFIRMED
Issued at:    {now.strftime('%H:%M, %d %b')}
```

The path is returned to the Flutter app via the booking response; the app fetches it from `GET /receipts/{booking_id}.png`.

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
PENDING -> CONFIRMED -> COMPLETED
PENDING -> CONFIRMED -> NO_SHOW
PENDING -> CONFIRMED -> CANCELLED
```

State transitions live in `backend/app/tools/bookings.py::transition`. Only `CONFIRMED` → anything is reachable from production code; `PENDING` is transient (only exists inside `check_and_hold`).

## API endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/bookings/{id}/cancel?rebook={true|false}` | User cancels. If `rebook=true`, publishes `user_cancellation` event so the resolver finds an alternative. |
| `GET` | `/bookings` | List bookings for the current user (optional filter by status). |
| `GET` | `/receipts/{booking_id}.png` | Serves the receipt PNG. |
| `POST` | `/bookings/{id}/arrived` | Marks the provider as arrived (cancels the no-show watchdog). |
| `POST` | `/bookings/{id}/complete` | Marks `COMPLETED`; APScheduler also triggers this if no one calls it within `T+2h`. |

## Edge cases

- **`SlotConflict` on first try** → see Conflict Resolver skill. Treat it like any other conflict event.
- **Provider phone missing in mock data** → never happens with our seed, but if it does, fall back to `"0300-000-0000"` and log a warning.
- **Receipt render fails** → still persist the booking; `receipt_png_path = None`; Flutter shows a fallback receipt rendered client-side.
- **Notifier send fails** → log + emit a `tool_call` with `result={"error": "..."}`; booking is still `CONFIRMED`. We do **not** roll back (confirmation can be re-sent).
