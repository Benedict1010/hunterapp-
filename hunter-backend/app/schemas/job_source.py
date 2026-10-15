from pydantic import BaseModel, ConfigDict


class JobSourceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    base_url: str | None = None
    is_available: bool = False
    description: str | None = None


class UserJobSourcesRead(BaseModel):
    selected_source_ids: list[str]


class UserJobSourcesUpdate(BaseModel):
    source_ids: list[str]
