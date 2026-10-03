from datetime import datetime
from pydantic import BaseModel, ConfigDict, field_validator


class NotificationCreate(BaseModel):
    title: str
    message: str
    notification_type: str = "general"
    related_entity_type: str | None = None
    related_entity_id: str | None = None

    @field_validator("title")
    @classmethod
    def validate_title(cls, v: str) -> str:
        s = v.strip()
        if not s:
            raise ValueError("Title must not be empty.")
        if len(s) > 255:
            raise ValueError("Title must not exceed 255 characters.")
        return s

    @field_validator("message")
    @classmethod
    def validate_message(cls, v: str) -> str:
        s = v.strip()
        if not s:
            raise ValueError("Message must not be empty.")
        if len(s) > 5000:
            raise ValueError("Message must not exceed 5000 characters.")
        return s

    @field_validator("notification_type")
    @classmethod
    def validate_notification_type(cls, v: str) -> str:
        s = v.strip().lower()
        if not s:
            raise ValueError("Notification type must not be empty.")
        if len(s) > 64:
            raise ValueError("Notification type must not exceed 64 characters.")
        return s

    @field_validator("related_entity_type")
    @classmethod
    def validate_related_entity_type(cls, v: str | None) -> str | None:
        if v is None:
            return None
        s = v.strip().lower()
        if not s:
            return None
        if len(s) > 64:
            raise ValueError("Related entity type must not exceed 64 characters.")
        return s

    @field_validator("related_entity_id")
    @classmethod
    def validate_related_entity_id(cls, v: str | None) -> str | None:
        if v is None:
            return None
        s = v.strip()
        if not s:
            return None
        if len(s) > 36:
            raise ValueError("Related entity ID must not exceed 36 characters.")
        return s


class NotificationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    notification_type: str
    title: str
    message: str
    is_read: bool
    related_entity_type: str | None = None
    related_entity_id: str | None = None
    created_at: datetime
    updated_at: datetime


class NotificationListResponse(BaseModel):
    items: list[NotificationRead]
    total: int
    limit: int
    offset: int


class NotificationUnreadCountResponse(BaseModel):
    unread_count: int


class NotificationReadAllResponse(BaseModel):
    updated_count: int
