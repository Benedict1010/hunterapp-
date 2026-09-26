from datetime import datetime
from pydantic import BaseModel, ConfigDict

from app.models.application import ApplicationStatus


class ApplicationTimelineCreate(BaseModel):
    status: ApplicationStatus
    note: str | None = None


class ApplicationTimelineRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    application_id: str
    status: ApplicationStatus
    note: str | None = None
    created_at: datetime
    updated_at: datetime
