def test_list_job_sources_unauthenticated(client):
    response = client.get("/job-sources")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 6
    names = [item["name"] for item in data]
    assert "LinkedIn" in names
    assert "Unstop" in names
    assert "Mock Job Source" in names


def test_user_job_sources_authentication_and_persistence(client):
    # Unauthenticated access to /job-sources/selected should fail (401)
    response = client.get("/job-sources/selected")
    assert response.status_code == 401

    update_resp = client.put("/job-sources/selected", json={"source_ids": []})
    assert update_resp.status_code == 401

    # Register user 1
    u1_reg = {
        "email": "source_u1@example.com",
        "password": "password123",
        "full_name": "Source User One",
    }
    client.post("/auth/register", json=u1_reg)
    token1 = client.post(
        "/auth/login", json={"email": u1_reg["email"], "password": u1_reg["password"]}
    ).json()["access_token"]
    headers1 = {"Authorization": f"Bearer {token1}"}

    # Fetch available sources to get valid IDs
    sources = client.get("/job-sources").json()
    s1_id = sources[0]["id"]
    s2_id = sources[1]["id"]

    # Initial selections for user 1 should be empty
    sel1 = client.get("/job-sources/selected", headers=headers1)
    assert sel1.status_code == 200
    assert sel1.json()["selected_source_ids"] == []

    # Update selections for user 1
    save1 = client.put(
        "/job-sources/selected",
        json={"source_ids": [s1_id, s2_id]},
        headers=headers1,
    )
    assert save1.status_code == 200
    assert set(save1.json()["selected_source_ids"]) == {s1_id, s2_id}

    # Verify persistence
    sel1_again = client.get("/job-sources/selected", headers=headers1)
    assert set(sel1_again.json()["selected_source_ids"]) == {s1_id, s2_id}

    # Register user 2 and check cross-user isolation
    u2_reg = {
        "email": "source_u2@example.com",
        "password": "password123",
        "full_name": "Source User Two",
    }
    client.post("/auth/register", json=u2_reg)
    token2 = client.post(
        "/auth/login", json={"email": u2_reg["email"], "password": u2_reg["password"]}
    ).json()["access_token"]
    headers2 = {"Authorization": f"Bearer {token2}"}

    sel2 = client.get("/job-sources/selected", headers=headers2)
    assert sel2.status_code == 200
    assert sel2.json()["selected_source_ids"] == []


def test_invalid_source_id_rejected(client):
    u_reg = {
        "email": "source_inv@example.com",
        "password": "password123",
        "full_name": "Invalid Source User",
    }
    client.post("/auth/register", json=u_reg)
    token = client.post(
        "/auth/login", json={"email": u_reg["email"], "password": u_reg["password"]}
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = client.put(
        "/job-sources/selected",
        json={"source_ids": ["invalid-uuid-12345"]},
        headers=headers,
    )
    assert resp.status_code == 400
    assert "Invalid job source IDs" in resp.json()["detail"]
