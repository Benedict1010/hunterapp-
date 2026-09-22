import pytest
from app.services.skill_extractor import extract_skills_from_text
from app.services.skill_vocabulary import SKILL_VOCABULARY
from app.models.job import Job, JobSkill, JobSource
from app.models.resume import Resume
from app.models.match import JobMatch

def test_skill_extraction_deterministic():
    # 1. Exact skill matches
    text = "I have experience with Python and Java."
    skills = extract_skills_from_text(text)
    assert "Python" in skills
    assert "Java" in skills

    # 4. Case-insensitive matching
    text_lower = "python, java, javascript"
    skills_lower = extract_skills_from_text(text_lower)
    assert {"Python", "Java", "JavaScript"} == skills_lower

    # 5. Alias normalization
    text_aliases = "Expert in JS and Postgres and TS."
    skills_aliases = extract_skills_from_text(text_aliases)
    assert "JavaScript" in skills_aliases
    assert "PostgreSQL" in skills_aliases
    assert "TypeScript" in skills_aliases

    # 6. Duplicate skill handling
    text_dupes = "Python Python Python and Python."
    skills_dupes = extract_skills_from_text(text_dupes)
    assert len(skills_dupes) == 1
    assert "Python" in skills_dupes

    # 18. Missing/empty resume content
    assert extract_skills_from_text("") == set()
    assert extract_skills_from_text(None) == set()

def test_skill_extraction_boundaries():
    # Avoid unsafe substring matches (e.g. "Java" in "JavaScript" if not using boundaries)
    # Our implementation uses \b or non-alphanumeric boundaries
    text = "I love JavaScript"
    skills = extract_skills_from_text(text)
    assert "JavaScript" in skills
    assert "Java" not in skills # Should not match substring

    text2 = "Next.js is cool"
    skills2 = extract_skills_from_text(text2)
    assert "Next.js" in skills2

def create_auth_header(client, email="matcher@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "Match User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}

def test_job_match_api_flow(client, database):
    headers = create_auth_header(client, "user_match@example.com")
    user_id = client.get("/users/me", headers=headers).json()["id"]

    # Setup: Create a Job
    source = JobSource(name="Test Source")
    database.add(source)
    database.flush()

    job = Job(
        title="Python Developer",
        company="Tech Corp",
        description="Looking for Python and FastAPI expert.",
        external_url="https://example.com/job1",
        deduplication_key="job1",
        source_id=source.id
    )
    job.skills = [JobSkill(name="Python"), JobSkill(name="FastAPI"), JobSkill(name="Docker")]
    database.add(job)

    # Setup: Create a Resume
    resume = Resume(
        user_id=user_id,
        filename="resume.pdf",
        file_url="uuid.pdf",
        content_text="I am a Python and FastAPI developer with knowledge of Git.",
        is_primary=True
    )
    database.add(resume)
    database.commit()

    # 9. Score calculation (2 out of 3 matches: Python, FastAPI. Missing: Docker)
    # Expected score: (2/3) * 100 = 66.66...

    # 1. Generate match
    match_payload = {"resume_id": resume.id}
    response = client.post(f"/matches/jobs/{job.id}", headers=headers, json=match_payload)
    assert response.status_code == 200
    data = response.json()
    assert data["match_score"] == pytest.approx(66.666, 0.1)
    # 10. Matched skill list
    assert set(data["matched_skills"]) == {"Python", "FastAPI"}
    # 11. Missing skill list
    assert set(data["missing_skills"]) == {"Docker"}

    # 12. Match persistence
    match_id = data["id"]
    assert database.query(JobMatch).count() == 1

    # 13. Re-matching updates instead of duplicates
    # Change resume content to add Docker
    resume.content_text += " I also use Docker."
    database.commit()

    response2 = client.post(f"/matches/jobs/{job.id}", headers=headers, json=match_payload)
    assert response2.status_code == 200
    data2 = response2.json()
    assert data2["id"] == match_id # Same ID
    assert data2["match_score"] == 100.0
    assert "Docker" in data2["matched_skills"]
    assert not data2["missing_skills"]

def test_job_match_security_and_errors(client, database):
    headers1 = create_auth_header(client, "user1_match@example.com")
    headers2 = create_auth_header(client, "user2_match@example.com")

    # 17. Nonexistent job
    res_no_job = client.post("/matches/jobs/nonexistent-id", headers=headers1, json={"resume_id": "some-id"})
    assert res_no_job.status_code == 404

    # Setup a job
    source = JobSource(name="Secure Source")
    database.add(source)
    database.flush()
    job = Job(title="Dev", company="C", external_url="u", deduplication_key="k", source_id=source.id)
    database.add(job)
    database.commit()

    # Setup a resume for user 1
    user1_me = client.get("/users/me", headers=headers1).json()
    resume1 = Resume(user_id=user1_me["id"], filename="r1.pdf", file_url="u1.pdf", content_text="Skill")
    database.add(resume1)
    database.commit()

    # 15. Resume ownership protection (User 2 tries to use User 1's resume)
    res_bad_owner = client.post(f"/matches/jobs/{job.id}", headers=headers2, json={"resume_id": resume1.id})
    assert res_bad_owner.status_code == 404 # Or 403, we implemented as 404 via ValueError in service

    # 16. User match isolation
    # User 1 creates a match
    client.post(f"/matches/jobs/{job.id}", headers=headers1, json={"resume_id": resume1.id})

    # User 2 tries to list matches
    res_list2 = client.get("/matches", headers=headers2)
    assert res_list2.status_code == 200
    assert len(res_list2.json()) == 0

    # 14. Authentication protection
    res_unauth = client.get("/matches")
    assert res_unauth.status_code == 401
