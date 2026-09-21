from dataclasses import dataclass
from datetime import datetime
from typing import Any


@dataclass(frozen=True)
class NormalizedJob:
    title: str | None
    company: str | None
    location: str | None
    description: str | None
    salary_range: str | None
    job_type: str | None
    external_url: str | None
    posted_at: datetime | None
    skills: tuple[str, ...]
    source_name: str | None
    source_base_url: str | None


def _text(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _posted_at(value: Any) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def normalize_job(raw: dict[str, Any], *, source_name: str | None, source_base_url: str | None) -> NormalizedJob:
    """Map known source field aliases to the application's source-neutral record."""
    skills = raw.get("technologies", raw.get("skills", []))
    if not isinstance(skills, list):
        skills = []
    return NormalizedJob(
        title=_text(raw.get("role", raw.get("position", raw.get("title")))),
        company=_text(raw.get("organization", raw.get("employer", raw.get("company")))),
        location=_text(raw.get("city", raw.get("place", raw.get("location")))),
        description=_text(raw.get("details", raw.get("description_text", raw.get("description")))),
        salary_range=_text(raw.get("compensation", raw.get("salary_range", raw.get("salary")))),
        job_type=_text(raw.get("employment", raw.get("kind", raw.get("job_type")))),
        external_url=_text(raw.get("url", raw.get("apply_url", raw.get("external_url")))),
        posted_at=_posted_at(raw.get("published", raw.get("posted_at"))),
        skills=tuple(skill for item in skills if (skill := _text(item)) is not None),
        source_name=source_name,
        source_base_url=source_base_url,
    )
