import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, JSON, Integer, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


def new_uuid() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    preferences: Mapped[list["JobPreference"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    resumes: Mapped[list["Resume"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    notifications: Mapped[list["Notification"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    job_sources: Mapped[list["UserJobSource"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    job_views: Mapped[list["UserJobView"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class JobPreference(Base):
    __tablename__ = "job_preferences"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    preferred_roles: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    preferred_locations: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    min_salary: Mapped[int | None] = mapped_column(Integer, nullable=True)
    job_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    work_mode: Mapped[str | None] = mapped_column(String(100), nullable=True)
    min_match_threshold: Mapped[int | None] = mapped_column(Integer, nullable=True)

    user: Mapped[User] = relationship(back_populates="preferences")


class UserJobSource(Base):
    __tablename__ = "user_job_sources"
    __table_args__ = (
        UniqueConstraint("user_id", "source_id", name="uq_user_job_sources_user_source"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    source_id: Mapped[str] = mapped_column(ForeignKey("job_sources.id", ondelete="CASCADE"), index=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped[User] = relationship(back_populates="job_sources")
