from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.application import Application, ApplicationStatus
from app.models.application_timeline import ApplicationTimeline
from app.models.job import Job
from app.models.resume import ResumeVersion
from app.models.user import User
from app.schemas.application import (
    ApplicationCreate,
    ApplicationExternalLinkRead,
    ApplicationRead,
    ApplicationUpdate,
)
from app.schemas.application_timeline import ApplicationTimelineCreate, ApplicationTimelineRead

router = APIRouter(prefix="/applications", tags=["applications"])


@router.post("", response_model=ApplicationRead, status_code=status.HTTP_201_CREATED)
def create_application(
    payload: ApplicationCreate,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Application:
    job = database.scalar(
        select(Job).options(joinedload(Job.source)).where(Job.id == payload.job_id)
    )
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found.",
        )

    resume_version = database.scalar(
        select(ResumeVersion).where(ResumeVersion.id == payload.resume_version_id)
    )
    if not resume_version:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Resume version not found.",
        )

    if resume_version.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Resume version does not belong to the authenticated user.",
        )

    status_val = (
        payload.status.value
        if payload.status
        else ApplicationStatus.APPLIED.value
    )
    applied_at_val = payload.applied_at or datetime.now(timezone.utc)
    now = datetime.now(timezone.utc)

    source_val = payload.source
    if source_val is None and job.source:
        source_val = job.source.name.lower()

    try:
        application = Application(
            user_id=current_user.id,
            job_id=payload.job_id,
            resume_version_id=payload.resume_version_id,
            status=status_val,
            application_url=payload.application_url,
            source=source_val,
            applied_at=applied_at_val,
        )

        database.add(application)
        database.flush()

        initial_timeline = ApplicationTimeline(
            application_id=application.id,
            status=status_val,
            note="Application created",
            created_at=now,
        )
        database.add(initial_timeline)

        database.commit()
        database.refresh(application)
        return application
    except Exception:
        database.rollback()
        raise


@router.get("", response_model=list[ApplicationRead])
def list_applications(
    status: ApplicationStatus | None = None,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> list[Application]:
    statement = select(Application).where(Application.user_id == current_user.id)
    if status is not None:
        statement = statement.where(Application.status == status.value)

    statement = statement.order_by(
        Application.applied_at.desc().nullslast(),
        Application.created_at.desc(),
    )
    return list(database.scalars(statement).all())


@router.get("/{application_id}", response_model=ApplicationRead)
def get_application(
    application_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Application:
    application = database.scalar(
        select(Application).where(Application.id == application_id)
    )
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found.",
        )
    if application.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )
    return application


@router.get("/{application_id}/external-link", response_model=ApplicationExternalLinkRead)
def get_application_external_link(
    application_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> ApplicationExternalLinkRead:
    application = database.scalar(
        select(Application).where(Application.id == application_id)
    )
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found.",
        )
    if application.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )
    if not application.application_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="External application URL not found for this application.",
        )

    return ApplicationExternalLinkRead(
        application_id=application.id,
        application_url=application.application_url,
        source=application.source,
    )


@router.patch("/{application_id}", response_model=ApplicationRead)
def update_application(
    application_id: str,
    payload: ApplicationUpdate,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Application:
    application = database.scalar(
        select(Application).where(Application.id == application_id)
    )
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found.",
        )
    if application.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )

    new_status_val = None
    if payload.status is not None:
        status_str = (
            payload.status.value
            if isinstance(payload.status, ApplicationStatus)
            else str(payload.status)
        )
        if status_str != application.status:
            new_status_val = status_str

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "status" and value is not None:
            application.status = (
                value.value if isinstance(value, ApplicationStatus) else str(value)
            )
        elif field == "application_url":
            application.application_url = value
        elif field == "source":
            application.source = value
        elif field == "applied_at":
            application.applied_at = value

    now = datetime.now(timezone.utc)
    try:
        if new_status_val is not None:
            timeline_event = ApplicationTimeline(
                application_id=application.id,
                status=new_status_val,
                note=f"Status updated to {new_status_val}",
                created_at=now,
            )
            database.add(timeline_event)

        database.commit()
        database.refresh(application)
        return application
    except Exception:
        database.rollback()
        raise


@router.post("/{application_id}/timeline", response_model=ApplicationTimelineRead, status_code=status.HTTP_201_CREATED)
def create_timeline_event(
    application_id: str,
    payload: ApplicationTimelineCreate,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> ApplicationTimeline:
    application = database.scalar(
        select(Application).where(Application.id == application_id)
    )
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found.",
        )
    if application.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )

    status_val = payload.status.value
    now = datetime.now(timezone.utc)

    try:
        timeline_event = ApplicationTimeline(
            application_id=application.id,
            status=status_val,
            note=payload.note,
            created_at=now,
        )
        database.add(timeline_event)
        application.status = status_val

        database.commit()
        database.refresh(timeline_event)
        return timeline_event
    except Exception:
        database.rollback()
        raise


@router.get("/{application_id}/timeline", response_model=list[ApplicationTimelineRead])
def list_timeline_events(
    application_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> list[ApplicationTimeline]:
    application = database.scalar(
        select(Application).where(Application.id == application_id)
    )
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found.",
        )
    if application.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )

    statement = (
        select(ApplicationTimeline)
        .where(ApplicationTimeline.application_id == application_id)
        .order_by(ApplicationTimeline.created_at.desc())
    )
    return list(database.scalars(statement).all())


@router.get("/{application_id}/timeline/{timeline_id}", response_model=ApplicationTimelineRead)
def get_timeline_event(
    application_id: str,
    timeline_id: str,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> ApplicationTimeline:
    application = database.scalar(
        select(Application).where(Application.id == application_id)
    )
    if not application:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Application not found.",
        )
    if application.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied.",
        )

    timeline_event = database.scalar(
        select(ApplicationTimeline).where(
            ApplicationTimeline.id == timeline_id,
            ApplicationTimeline.application_id == application_id,
        )
    )
    if not timeline_event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Timeline event not found.",
        )

    return timeline_event
