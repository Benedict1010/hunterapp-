from abc import ABC, abstractmethod
from collections.abc import Iterable, Mapping
from typing import Any


class JobSourceAdapter(ABC):
    """Boundary for a source-specific integration; adapters return raw records only."""

    name: str
    base_url: str | None = None

    @abstractmethod
    def fetch_jobs(self) -> Iterable[Mapping[str, Any]]:
        """Fetch source-native job records without persisting them."""
