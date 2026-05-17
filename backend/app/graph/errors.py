"""Domain errors for the Karigar graph.

Raised by nodes and tools; caught by the Orchestrator which routes them to the
correct resolution path (e.g. SlotConflict → event bus → Conflict Resolver).
"""

from __future__ import annotations


class KarigarError(Exception):
    """Base for all Karigar domain errors."""


class SlotConflict(KarigarError):
    """Raised by Availability.check_and_hold when the UNIQUE constraint fires."""

    def __init__(self, provider_id: str, slot_start: str) -> None:
        self.provider_id = provider_id
        self.slot_start = slot_start
        super().__init__(f"Slot conflict: provider={provider_id} slot={slot_start}")


class ProviderNotFound(KarigarError):
    """Raised by DiscoveryAgent when no candidates match the query."""

    def __init__(self, service: str, location: str) -> None:
        self.service = service
        self.location = location
        super().__init__(f"No providers found for service={service} near {location}")


class LanguageNotSupported(KarigarError):
    """Raised when an unsupported language code is encountered."""

    def __init__(self, lang: str) -> None:
        self.lang = lang
        super().__init__(f"Language not supported: {lang}")


class ResolutionCapExceeded(KarigarError):
    """Raised when MAX_RESOLUTION_ATTEMPTS is hit."""

    def __init__(self, session_id: str, attempts: int) -> None:
        self.session_id = session_id
        self.attempts = attempts
        super().__init__(
            f"Resolution cap exceeded for session={session_id} after {attempts} attempts"
        )
