"""create application timeline table

Revision ID: 20260925_02
Revises: 20260925_01
Create Date: 2026-09-25
"""

from alembic import op
import sqlalchemy as sa

revision = "20260925_02"
down_revision = "20260925_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "application_timeline",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("application_id", sa.String(36), sa.ForeignKey("applications.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(32), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_application_timeline_application_id", "application_timeline", ["application_id"])
    op.create_index("ix_application_timeline_status", "application_timeline", ["status"])


def downgrade() -> None:
    op.drop_index("ix_application_timeline_status", table_name="application_timeline")
    op.drop_index("ix_application_timeline_application_id", table_name="application_timeline")
    op.drop_table("application_timeline")
