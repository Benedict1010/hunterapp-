from datetime import datetime
from pydantic import BaseModel, ConfigDict


class ResumeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    filename: str
    file_url: str | None = None
    content_text: str | None = None
    is_primary: bool
    created_at: datetime
    updated_at: datetime


class ResumeUpdate(BaseModel):
    is_primary: bool | None = None


class ResumeVersionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    resume_id: str
    user_id: str
    job_id: str | None = None
    version_type: str
    content_text: str
    changes_made: list[str] | None = None
    warnings: list[str] | None = None
    created_at: datetime
    updated_at: datetime

