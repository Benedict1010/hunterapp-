import urllib.parse
from datetime import datetime
from pydantic import BaseModel, ConfigDict, field_validator

from app.models.application import ApplicationStatus


def validate_application_url(v: str | None) -> str | None:
    if v is None:
        return None
    url_str = v.strip()
    if not url_str:
        return None
    if len(url_str) > 1000:
        raise ValueError("Application URL must not exceed 1000 characters.")
    try:
        parsed = urllib.parse.urlparse(url_str)
    except Exception:
        raise ValueError("Invalid URL format.")
    scheme = parsed.scheme.lower()
    if scheme not in ("http", "https"):
        raise ValueError("Application URL must start with http:// or https://")
    if not parsed.netloc:
        raise ValueError("Application URL must include a valid host/domain.")
    return url_str


def normalize_source(v: str | None) -> str | None:
    if v is None:
        return None
    source_str = v.strip().lower()
    if not source_str:
        return None
    if len(source_str) > 255:
        raise ValueError("Source must not exceed 255 characters.")
    return source_str


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

    @field_validator("application_url", mode="before")
    @classmethod
    def check_application_url(cls, v: str | None) -> str | None:
        return validate_application_url(v)

    @field_validator("source", mode="before")
    @classmethod
    def check_source(cls, v: str | None) -> str | None:
        return normalize_source(v)


class ApplicationUpdate(BaseModel):
    status: ApplicationStatus | None = None
    application_url: str | None = None
    source: str | None = None
    applied_at: datetime | None = None

    @field_validator("application_url", mode="before")
    @classmethod
    def check_application_url(cls, v: str | None) -> str | None:
        return validate_application_url(v)

    @field_validator("source", mode="before")
    @classmethod
    def check_source(cls, v: str | None) -> str | None:
        return normalize_source(v)


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


class ApplicationExternalLinkRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    application_id: str
    application_url: str
    source: str | None = None
