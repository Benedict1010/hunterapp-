from datetime import datetime
from pydantic import BaseModel, ConfigDict


class JobMatchRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    resume_id: str
    job_id: str
    match_score: float
    matched_skills: list[str]
    missing_skills: list[str]
    explanation: str | None = None
    created_at: datetime
    updated_at: datetime


class JobMatchRequest(BaseModel):
    resume_id: str
