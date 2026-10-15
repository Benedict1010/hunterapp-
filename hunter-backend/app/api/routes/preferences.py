from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import JobPreference, User, new_uuid
from app.schemas.job_preference import JobPreferenceRead, JobPreferenceUpdate

router = APIRouter(prefix="/preferences", tags=["preferences"])


@router.get("", response_model=JobPreferenceRead)
def get_preferences(
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> JobPreferenceRead:
    pref = database.scalar(
        select(JobPreference).where(JobPreference.user_id == current_user.id)
    )
    if pref is None:
        return JobPreferenceRead(
            id=None,
            user_id=current_user.id,
            preferred_roles=[],
            job_type=None,
            work_mode=None,
            min_salary=None,
            preferred_locations=[],
            min_match_threshold=None,
        )
    return JobPreferenceRead.model_validate(pref)


@router.put("", response_model=JobPreferenceRead)
def update_preferences(
    payload: JobPreferenceUpdate,
    current_user: User = Depends(get_current_user),
    database: Session = Depends(get_db),
) -> JobPreferenceRead:
    if payload.min_salary is not None and payload.min_salary < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Minimum salary cannot be negative.",
        )
    if payload.min_match_threshold is not None and (
        payload.min_match_threshold < 0 or payload.min_match_threshold > 100
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Minimum match threshold must be between 0 and 100.",
        )

    pref = database.scalar(
        select(JobPreference).where(JobPreference.user_id == current_user.id)
    )

    if pref is None:
        pref = JobPreference(
            id=new_uuid(),
            user_id=current_user.id,
            preferred_roles=payload.preferred_roles,
            job_type=payload.job_type,
            work_mode=payload.work_mode,
            min_salary=payload.min_salary,
            preferred_locations=payload.preferred_locations,
            min_match_threshold=payload.min_match_threshold,
        )
        database.add(pref)
    else:
        pref.preferred_roles = payload.preferred_roles
        pref.job_type = payload.job_type
        pref.work_mode = payload.work_mode
        pref.min_salary = payload.min_salary
        pref.preferred_locations = payload.preferred_locations
        pref.min_match_threshold = payload.min_match_threshold

    database.commit()
    database.refresh(pref)

    return JobPreferenceRead.model_validate(pref)
