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
