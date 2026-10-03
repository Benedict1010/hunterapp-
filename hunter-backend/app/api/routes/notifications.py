from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import (
    NotificationCreate,
    NotificationListResponse,
    NotificationReadAllResponse,
    NotificationRead,
    NotificationUnreadCountResponse,
)
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("", response_model=NotificationRead, status_code=status.HTTP_201_CREATED)
def create_notification(
    payload: NotificationCreate,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Notification:
    return NotificationService.create_notification(
        db=database,
        user_id=current_user.id,
        title=payload.title,
        message=payload.message,
        notification_type=payload.notification_type,
        related_entity_type=payload.related_entity_type,
        related_entity_id=payload.related_entity_id,
    )


@router.get("", response_model=NotificationListResponse)
def list_notifications(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    is_read: bool | None = Query(None),
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> NotificationListResponse:
    items, total = NotificationService.get_user_notifications(
        db=database,
        user_id=current_user.id,
        limit=limit,
        offset=offset,
        is_read=is_read,
    )
    return NotificationListResponse(
        items=[NotificationRead.model_validate(item) for item in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/unread-count", response_model=NotificationUnreadCountResponse)
def get_unread_count(
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> NotificationUnreadCountResponse:
    count = NotificationService.get_unread_count(
        db=database,
        user_id=current_user.id,
    )
    return NotificationUnreadCountResponse(unread_count=count)


@router.patch("/read-all", response_model=NotificationReadAllResponse)
def read_all_notifications(
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> NotificationReadAllResponse:
    updated_count = NotificationService.mark_all_as_read(
        db=database,
        user_id=current_user.id,
    )
    return NotificationReadAllResponse(updated_count=updated_count)


@router.get("/{notification_id}", response_model=NotificationRead)
def get_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Notification:
    notification = NotificationService.get_notification_by_id(
        db=database,
        notification_id=notification_id,
    )
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found.",
        )
    if notification.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )
    return notification


@router.patch("/{notification_id}/read", response_model=NotificationRead)
def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Notification:
    notification = NotificationService.get_notification_by_id(
        db=database,
        notification_id=notification_id,
    )
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found.",
        )
    if notification.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )
    return NotificationService.mark_as_read(
        db=database,
        notification=notification,
    )
