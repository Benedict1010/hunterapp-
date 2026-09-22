import io
import os
import pytest
from fastapi.testclient import TestClient

from app.core.config import settings


@pytest.fixture(autouse=True)
def setup_test_upload_dir(monkeypatch, tmp_path):
    # Isolated test storage directory
    test_upload_dir = tmp_path / "test_uploads"
    monkeypatch.setattr(settings, "resume_upload_dir", str(test_upload_dir))
    return test_upload_dir


def create_auth_header(client, email="resume_user@example.com"):
    reg_payload = {
        "email": email,
        "password": "mypassword123",
        "full_name": "Resume Owner"
    }
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "mypassword123"})
    token = login_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_resume_upload_pdf_docx_and_unauthenticated(client):
    # 3. Unauthenticated upload is rejected
    res = client.post("/resumes", files={"file": ("resume.pdf", b"pdf content", "application/pdf")})
    assert res.status_code == 401

    headers = create_auth_header(client, "user1@example.com")

    # 1. Authenticated user can upload PDF
    res_pdf = client.post(
        "/resumes",
        headers=headers,
        files={"file": ("my_resume.pdf", b"valid pdf content", "application/pdf")}
    )
    assert res_pdf.status_code == 201
    pdf_data = res_pdf.json()
    assert pdf_data["filename"] == "my_resume.pdf"
    # 9. First resume automatically becomes primary
    assert pdf_data["is_primary"] is True
    assert pdf_data["file_url"].endswith(".pdf")

    # 2. Authenticated user can upload DOCX
    res_docx = client.post(
        "/resumes",
        headers=headers,
        files={"file": ("my_resume.docx", b"valid docx content", "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
    )
    assert res_docx.status_code == 201
    docx_data = res_docx.json()
    assert docx_data["filename"] == "my_resume.docx"
    # 10. Second resume does not automatically replace primary
    assert docx_data["is_primary"] is False


def test_resume_upload_validation_filters(client):
    headers = create_auth_header(client, "user_val@example.com")

    # 4. Unsupported file type is rejected
    res = client.post("/resumes", headers=headers, files={"file": ("resume.txt", b"text content", "text/plain")})
    assert res.status_code == 400
    assert "Unsupported file type" in res.json()["detail"]

    # 6. Empty file is rejected
    res_empty = client.post("/resumes", headers=headers, files={"file": ("resume.pdf", b"", "application/pdf")})
    assert res_empty.status_code == 400
    assert "empty" in res_empty.json()["detail"]


def test_resume_oversized_file(client, monkeypatch):
    monkeypatch.setattr(settings, "max_resume_file_size", 10) # 10 bytes limit
    headers = create_auth_header(client, "user_large@example.com")

    # 5. Oversized file is rejected
    res = client.post("/resumes", headers=headers, files={"file": ("resume.pdf", b"this content is too long for 10 bytes limit", "application/pdf")})
    assert res.status_code == 413


def test_resume_primary_behavior_and_listing(client):
    headers = create_auth_header(client, "user_primary@example.com")

    r1 = client.post("/resumes", headers=headers, files={"file": ("r1.pdf", b"r1 bytes", "application/pdf")}).json()
    r2 = client.post("/resumes", headers=headers, files={"file": ("r2.pdf", b"r2 bytes", "application/pdf")}).json()

    assert r1["is_primary"] is True
    assert r2["is_primary"] is False

    # 11. User can change primary resume
    patch_res = client.patch(f"/resumes/{r2['id']}/primary", headers=headers)
    assert patch_res.status_code == 200
    assert patch_res.json()["is_primary"] is True

    # 12. Only one primary resume exists per user
    # Verify via listing
    # 13. User can list their resumes
    list_res = client.get("/resumes", headers=headers)
    assert list_res.status_code == 200
    items = list_res.json()
    assert len(items) == 2

    primary_items = [item for item in items if item["is_primary"] is True]
    assert len(primary_items) == 1
    assert primary_items[0]["id"] == r2["id"]


def test_resume_get_download_replace_delete_and_cross_user_protection(client):
    headers1 = create_auth_header(client, "owner@example.com")
    headers2 = create_auth_header(client, "attacker@example.com")

    # Upload owner resume
    resume = client.post("/resumes", headers=headers1, files={"file": ("owner.pdf", b"owner content", "application/pdf")}).json()
    r_id = resume["id"]

    # 14. User can retrieve their own resume
    res_get = client.get(f"/resumes/{r_id}", headers=headers1)
    assert res_get.status_code == 200
    assert res_get.json()["filename"] == "owner.pdf"

    # 15. User can download their own resume
    res_dl = client.get(f"/resumes/{r_id}/download", headers=headers1)
    assert res_dl.status_code == 200
    assert res_dl.content == b"owner content"

    # 18. User cannot access another user's resume
    res_bad_get = client.get(f"/resumes/{r_id}", headers=headers2)
    assert res_bad_get.status_code == 403

    # 19. User cannot download another user's resume
    res_bad_dl = client.get(f"/resumes/{r_id}/download", headers=headers2)
    assert res_bad_dl.status_code == 403

    # 16. User can replace their own resume
    res_rep = client.put(f"/resumes/{r_id}", headers=headers1, files={"file": ("replaced.pdf", b"new content", "application/pdf")})
    assert res_rep.status_code == 200
    assert res_rep.json()["filename"] == "replaced.pdf"

    # Download again to confirm content replaced
    assert client.get(f"/resumes/{r_id}/download", headers=headers1).content == b"new content"

    # 20. User cannot delete another user's resume
    res_bad_del = client.delete(f"/resumes/{r_id}", headers=headers2)
    assert res_bad_del.status_code == 403

    # 17. User can delete their own resume
    res_del = client.delete(f"/resumes/{r_id}", headers=headers1)
    assert res_del.status_code == 204

    # Verify not found anymore
    assert client.get(f"/resumes/{r_id}", headers=headers1).status_code == 404
