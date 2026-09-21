from collections.abc import Iterable, Mapping
from typing import Any

from app.services.job_sources.base import JobSourceAdapter


class MockJobSource(JobSourceAdapter):
    """Deterministic development fixture; it performs no network requests."""

    name = "Mock Campus"
    base_url = "https://mock-campus.example"

    def fetch_jobs(self) -> Iterable[Mapping[str, Any]]:
        return [
            {"role": "Software Engineer Intern", "organization": "Nimbus Labs", "city": "Bengaluru, India", "details": "Build reliable services with Python and PostgreSQL.", "compensation": "₹30,000/month", "employment": "Internship", "url": "https://mock-campus.example/jobs/nimbus-swe-intern", "published": "2026-09-18T09:00:00Z", "technologies": ["Python", "PostgreSQL", "Git"]},
            {"role": "Full Stack Developer Intern", "organization": "Orbit Commerce", "city": "Remote, India", "details": "Help deliver React and FastAPI features for a growing marketplace.", "compensation": "₹25,000/month", "employment": "Internship", "url": "https://mock-campus.example/jobs/orbit-full-stack-intern", "published": "2026-09-17T09:00:00Z", "technologies": ["React", "FastAPI", "TypeScript"]},
            {"role": "Frontend Developer", "organization": "Pixel Forge", "city": "Mumbai, India", "details": "Create accessible, responsive product interfaces.", "compensation": "₹8–12 LPA", "employment": "Full-time", "url": "https://mock-campus.example/jobs/pixel-frontend", "published": "2026-09-16T09:00:00Z", "technologies": ["React", "CSS", "JavaScript"]},
            {"role": "Backend Developer", "organization": "Data Harbor", "city": "Pune, India", "details": "Design APIs and data pipelines for analytics products.", "compensation": "₹10–14 LPA", "employment": "Full-time", "url": "https://mock-campus.example/jobs/data-harbor-backend", "published": "2026-09-15T09:00:00Z", "technologies": ["Python", "FastAPI", "SQLAlchemy"]},
            {"role": "Machine Learning Engineer", "organization": "Signal AI", "city": "Hyderabad, India", "details": "Develop and evaluate machine-learning models for document intelligence.", "compensation": "₹12–16 LPA", "employment": "Full-time", "url": "https://mock-campus.example/jobs/signal-ml-engineer", "published": "2026-09-14T09:00:00Z", "technologies": ["Python", "PyTorch", "Machine Learning"]},
        ]


class MockPartnerJobSource(JobSourceAdapter):
    """Second mock source containing one cross-source duplicate listing."""

    name = "Mock Partner Board"
    base_url = "https://mock-partner.example"

    def fetch_jobs(self) -> Iterable[Mapping[str, Any]]:
        return [{"position": "Backend Developer", "employer": "Data Harbor", "place": "Pune, India", "description_text": "Design APIs and data pipelines for analytics products.", "apply_url": "https://mock-partner.example/listings/data-harbor-backend", "kind": "Full-time", "skills": ["Python", "FastAPI", "SQLAlchemy"]}]
