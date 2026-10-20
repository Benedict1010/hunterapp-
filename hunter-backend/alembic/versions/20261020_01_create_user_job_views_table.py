"""create user job views table

Revision ID: 20261020_01
Revises: 20260927_01
Create Date: 2026-10-20
"""

from alembic import op
import sqlalchemy as sa

revision = "20261020_01"
down_revision = "20260927_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "user_job_views",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("job_id", sa.String(36), sa.ForeignKey("jobs.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("user_id", "job_id", name="uq_user_job_views_user_job"),
    )
    op.create_index("ix_user_job_views_user_id", "user_job_views", ["user_id"])
    op.create_index("ix_user_job_views_job_id", "user_job_views", ["job_id"])


def downgrade() -> None:
    op.drop_index("ix_user_job_views_job_id", table_name="user_job_views")
    op.drop_index("ix_user_job_views_user_id", table_name="user_job_views")
    op.drop_table("user_job_views")
