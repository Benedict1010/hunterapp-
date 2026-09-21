import hashlib
import re
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.job import Job, JobSkill, JobSource
from app.services.job_normalizer import NormalizedJob, normalize_job
from app.services.job_sources.base import JobSourceAdapter


@dataclass
class IngestionResult:
    received: int = 0
    accepted: int = 0
    inserted: int = 0
    skipped_duplicates: int = 0
    rejected_invalid: int = 0


def deduplication_key(job: NormalizedJob) -> str:
    """Stable cross-source key based on canonical company and title."""
    canonical = "|".join(re.sub(r"\s+", " ", value.strip().casefold()) for value in (job.company or "", job.title or ""))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def is_valid_job(job: NormalizedJob) -> bool:
    return all((job.title, job.company, job.external_url, job.source_name))


class JobIngestionService:
    """Source-independent orchestration for fetching, validation, and persistence."""

    def __init__(self, database: Session):
        self.database = database

    def ingest(self, adapter: JobSourceAdapter) -> IngestionResult:
        result = IngestionResult()
        source: JobSource | None = None
        for raw in adapter.fetch_jobs():
            result.received += 1
            normalized = normalize_job(dict(raw), source_name=adapter.name, source_base_url=adapter.base_url)
            if not is_valid_job(normalized):
                result.rejected_invalid += 1
                continue
            result.accepted += 1
            key = deduplication_key(normalized)
            duplicate = self.database.scalar(select(Job.id).where((Job.external_url == normalized.external_url) | (Job.deduplication_key == key)))
            if duplicate:
                result.skipped_duplicates += 1
                continue
            if source is None:
                source = self.database.scalar(select(JobSource).where(JobSource.name == adapter.name))
                if source is None:
                    source = JobSource(name=adapter.name, base_url=adapter.base_url)
                    self.database.add(source)
                    self.database.flush()
            job = Job(title=normalized.title, company=normalized.company, location=normalized.location, description=normalized.description, salary_range=normalized.salary_range, job_type=normalized.job_type, external_url=normalized.external_url, deduplication_key=key, posted_at=normalized.posted_at, source=source)
            job.skills = [JobSkill(name=skill) for skill in normalized.skills]
            self.database.add(job)
            self.database.flush()
            result.inserted += 1
        self.database.commit()
        return result
