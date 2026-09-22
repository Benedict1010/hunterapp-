"""add filename and updated at to resumes

Revision ID: 20260922_01
Revises: 20260921_01
Create Date: 2026-09-22
"""

from alembic import op
import sqlalchemy as sa

revision = "20260922_01"
down_revision = "20260921_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "resumes",
        sa.Column("filename", sa.String(255), nullable=False, server_default="uploaded_resume")
    )
    op.add_column(
        "resumes",
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False)
    )


def downgrade() -> None:
    op.drop_column("resumes", "updated_at")
    op.drop_column("resumes", "filename")
