from datetime import datetime
from pydantic import BaseModel, ConfigDict

from app.models.application import ApplicationStatus


class JobSummaryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    company: str
    location: str | None = None


class ApplicationCreate(BaseModel):
    job_id: str
    resume_version_id: str
    application_url: str | None = None
    source: str | None = None
    status: ApplicationStatus | None = ApplicationStatus.APPLIED
    applied_at: datetime | None = None


class ApplicationUpdate(BaseModel):
    status: ApplicationStatus | None = None
    application_url: str | None = None
    source: str | None = None
    applied_at: datetime | None = None


class ApplicationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    job_id: str
    resume_version_id: str
    status: ApplicationStatus
    application_url: str | None = None
    source: str | None = None
    applied_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
    job: JobSummaryRead | None = None
