import time
import pytest
import sqlalchemy as sa

from app.models.notification import Notification
from app.models.user import User
from app.services.notification_service import NotificationService


def create_auth_header(client, email="notif_user@example.com"):
    reg_payload = {"email": email, "password": "password123", "full_name": "Notification User"}
    client.post("/auth/register", json=reg_payload)
    login_res = client.post("/auth/login", json={"email": email, "password": "password123"})
    return {"Authorization": f"Bearer {login_res.json()['access_token']}"}


# 1. Notification creation and default unread state
def test_create_notification(client, database):
    headers = create_auth_header(client, "create_notif@example.com")

    payload = {
        "title": "Welcome to Hunter",
        "message": "Your account has been created successfully.",
        "notification_type": "welcome",
        "related_entity_type": "user",
        "related_entity_id": "u-123",
    }

    response = client.post("/notifications", headers=headers, json=payload)
    assert response.status_code == 201
    data = response.json()

    assert data["title"] == payload["title"]
    assert data["message"] == payload["message"]
    assert data["notification_type"] == payload["notification_type"]
    assert data["related_entity_type"] == payload["related_entity_type"]
    assert data["related_entity_id"] == payload["related_entity_id"]
    assert data["is_read"] is False
    assert "id" in data
    assert "created_at" in data
    assert "updated_at" in data


# 2 & 4. List notifications and newest-first ordering
def test_list_notifications_and_ordering(client, database):
    headers = create_auth_header(client, "list_notif@example.com")

    n1 = client.post(
        "/notifications",
        headers=headers,
        json={"title": "First Notif", "message": "Msg 1", "notification_type": "type_1"},
    ).json()

    time.sleep(0.01)

    n2 = client.post(
        "/notifications",
        headers=headers,
        json={"title": "Second Notif", "message": "Msg 2", "notification_type": "type_2"},
    ).json()

    time.sleep(0.01)

    n3 = client.post(
        "/notifications",
        headers=headers,
        json={"title": "Third Notif", "message": "Msg 3", "notification_type": "type_3"},
    ).json()

    list_res = client.get("/notifications", headers=headers)
    assert list_res.status_code == 200
    res_data = list_res.json()

    assert res_data["total"] == 3
    items = res_data["items"]
    assert len(items) == 3

    # Ordered newest first (n3, n2, n1)
    assert items[0]["id"] == n3["id"]
    assert items[1]["id"] == n2["id"]
    assert items[2]["id"] == n1["id"]


# 3. List notifications with is_read filter
def test_list_notifications_is_read_filter(client, database):
    headers = create_auth_header(client, "filter_notif@example.com")

    n1 = client.post(
        "/notifications",
        headers=headers,
        json={"title": "Notif 1", "message": "Msg 1"},
    ).json()
    n2 = client.post(
        "/notifications",
        headers=headers,
        json={"title": "Notif 2", "message": "Msg 2"},
    ).json()

    # Mark n1 as read
    client.patch(f"/notifications/{n1['id']}/read", headers=headers)

    # Filter unread (is_read=false)
    unread_res = client.get("/notifications?is_read=false", headers=headers)
    assert unread_res.status_code == 200
    unread_items = unread_res.json()["items"]
    assert len(unread_items) == 1
    assert unread_items[0]["id"] == n2["id"]

    # Filter read (is_read=true)
    read_res = client.get("/notifications?is_read=true", headers=headers)
    assert read_res.status_code == 200
    read_items = read_res.json()["items"]
    assert len(read_items) == 1
    assert read_items[0]["id"] == n1["id"]


# Pagination support
def test_notifications_pagination(client, database):
    headers = create_auth_header(client, "page_notif@example.com")

    for i in range(5):
        client.post(
            "/notifications",
            headers=headers,
            json={"title": f"Notif {i}", "message": f"Msg {i}"},
        )

    page1 = client.get("/notifications?limit=2&offset=0", headers=headers).json()
    assert page1["total"] == 5
    assert page1["limit"] == 2
    assert page1["offset"] == 0
    assert len(page1["items"]) == 2

    page2 = client.get("/notifications?limit=2&offset=2", headers=headers).json()
    assert page2["total"] == 5
    assert len(page2["items"]) == 2
    assert page2["items"][0]["id"] != page1["items"][0]["id"]


# 5. Detail endpoint
def test_get_notification_detail(client, database):
    headers = create_auth_header(client, "detail_notif@example.com")

    created = client.post(
        "/notifications",
        headers=headers,
        json={"title": "Detail Notif", "message": "Detail Message"},
    ).json()

    res = client.get(f"/notifications/{created['id']}", headers=headers)
    assert res.status_code == 200
    assert res.json()["id"] == created["id"]
    assert res.json()["title"] == "Detail Notif"


# 6 & 7. Mark one as read and idempotent repeated read
def test_mark_one_as_read_idempotent(client, database):
    headers = create_auth_header(client, "read_notif@example.com")

    created = client.post(
        "/notifications",
        headers=headers,
        json={"title": "Read Test", "message": "Read Message"},
    ).json()
    assert created["is_read"] is False

    # First mark read
    res1 = client.patch(f"/notifications/{created['id']}/read", headers=headers)
    assert res1.status_code == 200
    assert res1.json()["is_read"] is True

    # Repeated mark read (idempotent)
    res2 = client.patch(f"/notifications/{created['id']}/read", headers=headers)
    assert res2.status_code == 200
    assert res2.json()["is_read"] is True


# 8. Mark all as read
def test_mark_all_as_read(client, database):
    headers = create_auth_header(client, "read_all_notif@example.com")

    for i in range(3):
        client.post(
            "/notifications",
            headers=headers,
            json={"title": f"Unread {i}", "message": "Msg"},
        )

    # Check unread count before
    count_before = client.get("/notifications/unread-count", headers=headers).json()
    assert count_before["unread_count"] == 3

    # Read all
    read_all_res = client.patch("/notifications/read-all", headers=headers)
    assert read_all_res.status_code == 200
    assert read_all_res.json()["updated_count"] == 3

    # Check unread count after
    count_after = client.get("/notifications/unread-count", headers=headers).json()
    assert count_after["unread_count"] == 0


# 9 & 10. Unread count and empty unread count
def test_unread_count(client, database):
    headers = create_auth_header(client, "count_notif@example.com")

    # 10. Empty unread count for user with no notifications
    empty_res = client.get("/notifications/unread-count", headers=headers)
    assert empty_res.status_code == 200
    assert empty_res.json()["unread_count"] == 0

    # 9. Create 2 notifications, read 1
    n1 = client.post(
        "/notifications",
        headers=headers,
        json={"title": "N1", "message": "M1"},
    ).json()
    client.post(
        "/notifications",
        headers=headers,
        json={"title": "N2", "message": "M2"},
    )

    client.patch(f"/notifications/{n1['id']}/read", headers=headers)

    count_res = client.get("/notifications/unread-count", headers=headers)
    assert count_res.status_code == 200
    assert count_res.json()["unread_count"] == 1


# 11. Cross-user access blocked (IDOR)
def test_cross_user_access_blocked(client, database):
    headers1 = create_auth_header(client, "user1_notif@example.com")
    headers2 = create_auth_header(client, "user2_notif@example.com")

    n1 = client.post(
        "/notifications",
        headers=headers1,
        json={"title": "User 1 Secret Notif", "message": "Private"},
    ).json()

    # User 2 tries GET User 1's notification -> 403 Forbidden
    get_res = client.get(f"/notifications/{n1['id']}", headers=headers2)
    assert get_res.status_code == 403

    # User 2 tries PATCH read User 1's notification -> 403 Forbidden
    patch_res = client.patch(f"/notifications/{n1['id']}/read", headers=headers2)
    assert patch_res.status_code == 403

    # User 2 list notifications does not include User 1's notification
    list_res = client.get("/notifications", headers=headers2)
    assert list_res.status_code == 200
    assert list_res.json()["total"] == 0


# Unauthenticated requests blocked
def test_unauthenticated_requests_blocked(client):
    assert client.get("/notifications").status_code == 401
    assert client.post("/notifications", json={"title": "T", "message": "M"}).status_code == 401
    assert client.get("/notifications/unread-count").status_code == 401
    assert client.patch("/notifications/read-all").status_code == 401
    assert client.get("/notifications/some-id").status_code == 401
    assert client.patch("/notifications/some-id/read").status_code == 401


# Notification not found
def test_notification_not_found(client, database):
    headers = create_auth_header(client, "not_found_notif@example.com")

    assert client.get("/notifications/non-existent-id", headers=headers).status_code == 404
    assert client.patch("/notifications/non-existent-id/read", headers=headers).status_code == 404


# Invalid notification data
def test_invalid_notification_data(client, database):
    headers = create_auth_header(client, "invalid_notif@example.com")

    # Empty title
    res1 = client.post("/notifications", headers=headers, json={"title": "   ", "message": "Valid msg"})
    assert res1.status_code == 422

    # Empty message
    res2 = client.post("/notifications", headers=headers, json={"title": "Valid title", "message": "   "})
    assert res2.status_code == 422

    # Oversized title (>255 chars)
    res3 = client.post(
        "/notifications",
        headers=headers,
        json={"title": "A" * 256, "message": "Valid msg"},
    )
    assert res3.status_code == 422


# User deletion cascade
def test_user_deletion_cascade(database):
    if database.bind.dialect.name == "sqlite":
        database.execute(sa.text("PRAGMA foreign_keys=ON"))

    user = User(email="cascade_notif@example.com", hashed_password="pw", full_name="Cascade User")
    database.add(user)
    database.flush()

    notif = NotificationService.create_notification(
        db=database,
        user_id=user.id,
        title="Cascade Title",
        message="Cascade Message",
    )
    notif_id = notif.id

    database.delete(user)
    database.commit()

    assert database.get(Notification, notif_id) is None


# Service event groundwork
def test_service_event_groundwork(database):
    user = User(email="event_notif@example.com", hashed_password="pw", full_name="Event User")
    database.add(user)
    database.commit()

    n1 = NotificationService.notify_application_status_changed(
        db=database,
        user_id=user.id,
        application_id="app-1",
        old_status="applied",
        new_status="interview",
    )
    assert n1.notification_type == "application_status_change"
    assert n1.related_entity_type == "application"
    assert n1.related_entity_id == "app-1"

    n2 = NotificationService.notify_job_match_found(
        db=database,
        user_id=user.id,
        job_id="job-1",
        job_title="Senior Engineer",
        match_score=0.92,
    )
    assert n2.notification_type == "job_match_found"
    assert n2.related_entity_type == "job"
    assert "92%" in n2.message

    n3 = NotificationService.notify_resume_tailored(
        db=database,
        user_id=user.id,
        resume_version_id="rv-1",
        job_title="Senior Engineer",
    )
    assert n3.notification_type == "resume_tailoring_completed"
    assert n3.related_entity_type == "resume_version"
