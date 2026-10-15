def test_preferences_authentication_required(client):
    get_resp = client.get("/preferences")
    assert get_resp.status_code == 401

    put_resp = client.put(
        "/preferences",
        json={
            "preferred_roles": ["Frontend Engineer"],
            "job_type": "Full-time",
            "work_mode": "Remote",
            "min_salary": 30000,
            "preferred_locations": ["Remote"],
            "min_match_threshold": 80,
        },
    )
    assert put_resp.status_code == 401


def test_preferences_defaults_and_crud(client):
    # Register user A
    u_reg = {
        "email": "pref_a@example.com",
        "password": "password123",
        "full_name": "Pref User A",
    }
    client.post("/auth/register", json=u_reg)
    token = client.post(
        "/auth/login", json={"email": u_reg["email"], "password": u_reg["password"]}
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Default preferences when none are saved
    initial = client.get("/preferences", headers=headers)
    assert initial.status_code == 200
    init_data = initial.json()
    assert init_data["preferred_roles"] == []
    assert init_data["job_type"] is None

    # Create/Update preferences
    payload = {
        "preferred_roles": ["Product Designer", "Frontend Engineer"],
        "job_type": "Full-time",
        "work_mode": "Remote",
        "min_salary": 25000,
        "preferred_locations": ["Bangalore, KA", "Remote"],
        "min_match_threshold": 85,
    }
    updated = client.put("/preferences", json=payload, headers=headers)
    assert updated.status_code == 200
    up_data = updated.json()
    assert up_data["preferred_roles"] == ["Product Designer", "Frontend Engineer"]
    assert up_data["job_type"] == "Full-time"
    assert up_data["work_mode"] == "Remote"
    assert up_data["min_salary"] == 25000
    assert up_data["preferred_locations"] == ["Bangalore, KA", "Remote"]
    assert up_data["min_match_threshold"] == 85

    # Verify persistence
    persisted = client.get("/preferences", headers=headers).json()
    assert persisted["preferred_roles"] == ["Product Designer", "Frontend Engineer"]
    assert persisted["min_match_threshold"] == 85


def test_preferences_validation_and_isolation(client):
    # Register user 1
    u1_reg = {
        "email": "pref_u1@example.com",
        "password": "password123",
        "full_name": "Pref U1",
    }
    client.post("/auth/register", json=u1_reg)
    token1 = client.post(
        "/auth/login", json={"email": u1_reg["email"], "password": u1_reg["password"]}
    ).json()["access_token"]
    headers1 = {"Authorization": f"Bearer {token1}"}

    # Test invalid salary
    bad_salary = client.put(
        "/preferences",
        json={"min_salary": -500},
        headers=headers1,
    )
    assert bad_salary.status_code in (400, 422)

    # Test invalid threshold (>100)
    bad_thresh = client.put(
        "/preferences",
        json={"min_match_threshold": 150},
        headers=headers1,
    )
    assert bad_thresh.status_code in (400, 422)

    # Save valid preferences for U1
    client.put(
        "/preferences",
        json={
            "preferred_roles": ["Data Scientist"],
            "job_type": "Contract",
            "work_mode": "Hybrid",
            "min_salary": 40000,
            "preferred_locations": ["Mumbai, MH"],
            "min_match_threshold": 90,
        },
        headers=headers1,
    )

    # Register user 2 and verify isolation
    u2_reg = {
        "email": "pref_u2@example.com",
        "password": "password123",
        "full_name": "Pref U2",
    }
    client.post("/auth/register", json=u2_reg)
    token2 = client.post(
        "/auth/login", json={"email": u2_reg["email"], "password": u2_reg["password"]}
    ).json()["access_token"]
    headers2 = {"Authorization": f"Bearer {token2}"}

    u2_prefs = client.get("/preferences", headers=headers2).json()
    assert u2_prefs["preferred_roles"] == []
    assert u2_prefs["job_type"] is None
