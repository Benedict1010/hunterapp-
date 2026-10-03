from datetime import datetime, timezone
from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.models.notification import Notification


class NotificationService:
    @staticmethod
    def create_notification(
        db: Session,
        user_id: str,
        title: str,
        message: str,
        notification_type: str = "general",
        related_entity_type: str | None = None,
        related_entity_id: str | None = None,
    ) -> Notification:
        notification = Notification(
            user_id=user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            related_entity_type=related_entity_type,
            related_entity_id=related_entity_id,
            is_read=False,
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return notification

    @staticmethod
    def create_notifications_bulk(
        db: Session,
        notifications_data: list[dict],
    ) -> list[Notification]:
        notifications = [
            Notification(
                user_id=data["user_id"],
                title=data["title"],
                message=data["message"],
                notification_type=data.get("notification_type", "general"),
                related_entity_type=data.get("related_entity_type"),
                related_entity_id=data.get("related_entity_id"),
                is_read=False,
            )
            for data in notifications_data
        ]
        db.add_all(notifications)
        db.commit()
        for n in notifications:
            db.refresh(n)
        return notifications

    @staticmethod
    def get_user_notifications(
        db: Session,
        user_id: str,
        limit: int = 50,
        offset: int = 0,
        is_read: bool | None = None,
    ) -> tuple[list[Notification], int]:
        base_query = select(Notification).where(Notification.user_id == user_id)
        if is_read is not None:
            base_query = base_query.where(Notification.is_read == is_read)

        total_stmt = select(func.count()).select_from(base_query.subquery())
        total = db.scalar(total_stmt) or 0

        query = (
            base_query.order_by(Notification.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        items = list(db.scalars(query).all())
        return items, total

    @staticmethod
    def get_notification_by_id(
        db: Session,
        notification_id: str,
    ) -> Notification | None:
        return db.scalar(
            select(Notification).where(Notification.id == notification_id)
        )

    @staticmethod
    def mark_as_read(
        db: Session,
        notification: Notification,
    ) -> Notification:
        if not notification.is_read:
            notification.is_read = True
            notification.updated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(notification)
        return notification

    @staticmethod
    def mark_all_as_read(
        db: Session,
        user_id: str,
    ) -> int:
        stmt = (
            update(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.is_read == False,  # noqa: E712
            )
            .values(
                is_read=True,
                updated_at=datetime.now(timezone.utc),
            )
        )
        result = db.execute(stmt)
        db.commit()
        return result.rowcount

    @staticmethod
    def get_unread_count(
        db: Session,
        user_id: str,
    ) -> int:
        stmt = (
            select(func.count())
            .select_from(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.is_read == False,  # noqa: E712
            )
        )
        return db.scalar(stmt) or 0

    # Event Groundwork
    @staticmethod
    def notify_application_status_changed(
        db: Session,
        user_id: str,
        application_id: str,
        old_status: str,
        new_status: str,
    ) -> Notification:
        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            title="Application Status Updated",
            message=f"Your application status changed from {old_status} to {new_status}.",
            notification_type="application_status_change",
            related_entity_type="application",
            related_entity_id=application_id,
        )

    @staticmethod
    def notify_job_match_found(
        db: Session,
        user_id: str,
        job_id: str,
        job_title: str,
        match_score: float,
    ) -> Notification:
        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            title="New Job Match Found",
            message=f"Found a high match ({int(match_score * 100)}%) for '{job_title}'.",
            notification_type="job_match_found",
            related_entity_type="job",
            related_entity_id=job_id,
        )

    @staticmethod
    def notify_resume_tailored(
        db: Session,
        user_id: str,
        resume_version_id: str,
        job_title: str,
    ) -> Notification:
        return NotificationService.create_notification(
            db=db,
            user_id=user_id,
            title="Resume Tailoring Complete",
            message=f"Your resume has been tailored for '{job_title}'.",
            notification_type="resume_tailoring_completed",
            related_entity_type="resume_version",
            related_entity_id=resume_version_id,
        )
