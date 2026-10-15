"""add job preferences fields and user job sources table

Revision ID: 20260927_01
Revises: 20260926_01
Create Date: 2026-09-27
"""

from alembic import op
import sqlalchemy as sa

revision = "20260927_01"
down_revision = "20260926_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Update job_sources table
    op.add_column("job_sources", sa.Column("is_available", sa.Boolean(), nullable=False, server_default=sa.text("false")))
    op.add_column("job_sources", sa.Column("description", sa.Text(), nullable=True))

    # Update job_preferences table
    op.add_column("job_preferences", sa.Column("job_type", sa.String(100), nullable=True))
    op.add_column("job_preferences", sa.Column("work_mode", sa.String(100), nullable=True))
    op.add_column("job_preferences", sa.Column("min_match_threshold", sa.Integer(), nullable=True))

    # Create user_job_sources table
    op.create_table(
        "user_job_sources",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("source_id", sa.String(36), sa.ForeignKey("job_sources.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("user_id", "source_id", name="uq_user_job_sources_user_source"),
    )
    op.create_index("ix_user_job_sources_user_id", "user_job_sources", ["user_id"])
    op.create_index("ix_user_job_sources_source_id", "user_job_sources", ["source_id"])


def downgrade() -> None:
    op.drop_index("ix_user_job_sources_source_id", table_name="user_job_sources")
    op.drop_index("ix_user_job_sources_user_id", table_name="user_job_sources")
    op.drop_table("user_job_sources")

    op.drop_column("job_preferences", "min_match_threshold")
    op.drop_column("job_preferences", "work_mode")
    op.drop_column("job_preferences", "job_type")

    op.drop_column("job_sources", "description")
    op.drop_column("job_sources", "is_available")
