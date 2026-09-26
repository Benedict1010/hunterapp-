from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.application import Application, ApplicationStatus
from app.models.job import Job
from app.models.resume import ResumeVersion
from app.models.user import User
from app.schemas.application import ApplicationCreate, ApplicationRead, ApplicationUpdate

router = APIRouter(prefix="/applications", tags=["applications"])


@router.post("", response_model=ApplicationRead, status_code=status.HTTP_201_CREATED)
def create_application(
    payload: ApplicationCreate,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> Application:
    job = database.scalar(select(Job).where(Job.id == payload.job_id))
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

    application = Application(
        user_id=current_user.id,
        job_id=payload.job_id,
        resume_version_id=payload.resume_version_id,
        status=status_val,
        application_url=payload.application_url,
        source=payload.source,
        applied_at=applied_at_val,
    )

    database.add(application)
    database.commit()
    database.refresh(application)
    return application


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

    database.commit()
    database.refresh(application)
    return application
