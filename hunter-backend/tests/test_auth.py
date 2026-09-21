def test_registration_and_duplicate(client):
    # Test valid registration
    reg_payload = {
        "email": "test@example.com",
        "password": "securepassword123",
        "full_name": "Test User"
    }
    response = client.post("/auth/register", json=reg_payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["full_name"] == "Test User"
    assert "id" in data
    assert "hashed_password" not in data

    # Test duplicate registration
    response2 = client.post("/auth/register", json=reg_payload)
    assert response2.status_code == 400
    assert "already exists" in response2.json()["detail"]


def test_login_valid_and_invalid(client):
    # Setup user
    reg_payload = {
        "email": "login@example.com",
        "password": "mypassword",
        "full_name": "Login User"
    }
    client.post("/auth/register", json=reg_payload)

    # Test invalid login (wrong password)
    login_payload = {
        "email": "login@example.com",
        "password": "wrongpassword"
    }
    response = client.post("/auth/login", json=login_payload)
    assert response.status_code == 401

    # Test valid login
    login_payload["password"] = "mypassword"
    response2 = client.post("/auth/login", json=login_payload)
    assert response2.status_code == 200
    token_data = response2.json()
    assert "access_token" in token_data
    assert token_data["token_type"] == "bearer"


def test_users_me_authenticated_and_unauthenticated(client):
    # Test unauthenticated /users/me
    response = client.get("/users/me")
    assert response.status_code == 401

    # Setup user and login
    reg_payload = {
        "email": "me@example.com",
        "password": "mypassword",
        "full_name": "Me User"
    }
    client.post("/auth/register", json=reg_payload)

    login_payload = {
        "email": "me@example.com",
        "password": "mypassword"
    }
    login_res = client.post("/auth/login", json=login_payload)
    token = login_res.json()["access_token"]

    # Test authenticated /users/me
    headers = {"Authorization": f"Bearer {token}"}
    response2 = client.get("/users/me", headers=headers)
    assert response2.status_code == 200
    me_data = response2.json()
    assert me_data["email"] == "me@example.com"
    assert me_data["full_name"] == "Me User"
    assert "hashed_password" not in me_data
