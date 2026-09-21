from datetime import datetime

from pydantic import BaseModel, ConfigDict


class JobSkillRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str
    importance: float | None = None


class JobRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    company: str
    location: str | None = None
    description: str | None = None
    salary_range: str | None = None
    job_type: str | None = None
    external_url: str
    posted_at: datetime | None = None
    source: str
    skills: list[JobSkillRead]


class JobListResponse(BaseModel):
    items: list[JobRead]
    total: int
    limit: int
    offset: int


class IngestionSummary(BaseModel):
    received: int
    accepted: int
    inserted: int
    skipped_duplicates: int
    rejected_invalid: int
