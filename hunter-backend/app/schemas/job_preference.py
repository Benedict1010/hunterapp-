from pydantic import BaseModel, ConfigDict, Field


class JobPreferenceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str | None = None
    user_id: str | None = None
    preferred_roles: list[str] = Field(default_factory=list)
    job_type: str | None = None
    work_mode: str | None = None
    min_salary: int | None = None
    preferred_locations: list[str] = Field(default_factory=list)
    min_match_threshold: int | None = None


class JobPreferenceUpdate(BaseModel):
    preferred_roles: list[str] = Field(default_factory=list)
    job_type: str | None = None
    work_mode: str | None = None
    min_salary: int | None = Field(default=None, ge=0)
    preferred_locations: list[str] = Field(default_factory=list)
    min_match_threshold: int | None = Field(default=None, ge=0, le=100)
