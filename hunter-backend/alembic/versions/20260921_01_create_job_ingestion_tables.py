"""create job ingestion tables

Revision ID: 20260921_01
Revises:
Create Date: 2026-09-21
"""

from alembic import op
import sqlalchemy as sa

revision = "20260921_01"
down_revision = "20260920_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table("job_sources", sa.Column("id", sa.String(36), primary_key=True), sa.Column("name", sa.String(100), nullable=False), sa.Column("base_url", sa.String(500)), sa.UniqueConstraint("name"))
    op.create_index("ix_job_sources_name", "job_sources", ["name"])
    op.create_table("jobs", sa.Column("id", sa.String(36), primary_key=True), sa.Column("title", sa.String(255), nullable=False), sa.Column("company", sa.String(255), nullable=False), sa.Column("location", sa.String(255)), sa.Column("description", sa.Text()), sa.Column("salary_range", sa.String(255)), sa.Column("job_type", sa.String(100)), sa.Column("source_id", sa.String(36), sa.ForeignKey("job_sources.id"), nullable=False), sa.Column("external_url", sa.String(1000), nullable=False), sa.Column("deduplication_key", sa.String(64), nullable=False), sa.Column("posted_at", sa.DateTime(timezone=True)), sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()), sa.UniqueConstraint("external_url", name="uq_jobs_external_url"), sa.UniqueConstraint("deduplication_key", name="uq_jobs_deduplication_key"))
    for name in ("title", "company", "source_id", "external_url", "deduplication_key"):
        op.create_index(f"ix_jobs_{name}", "jobs", [name])
    op.create_table("job_skills", sa.Column("id", sa.String(36), primary_key=True), sa.Column("job_id", sa.String(36), sa.ForeignKey("jobs.id"), nullable=False), sa.Column("name", sa.String(100), nullable=False), sa.Column("importance", sa.Float()))
    op.create_index("ix_job_skills_job_id", "job_skills", ["job_id"])


def downgrade() -> None:
    op.drop_table("job_skills")
    op.drop_table("jobs")
    op.drop_table("job_sources")
