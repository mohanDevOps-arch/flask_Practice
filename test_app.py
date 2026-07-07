import pytest
import mongomock
from bson.objectid import ObjectId

# ✅ Proper patching BEFORE importing app
import pymongo
pymongo.MongoClient = mongomock.MongoClient

from app import app, mongo


@pytest.fixture
def client():
    app.config["TESTING"] = True

    client = app.test_client()

    # Setup test data
    with app.app_context():
        mongo.db.students.delete_many({})
        mongo.db.students.insert_one({
            "_id": ObjectId("66fddff25f4b5f6a0a123456"),
            "name": "Test Student",
            "email": "test@student.com",
            "course": "Flask"
        })

    yield client

    # Cleanup
    with app.app_context():
        mongo.db.students.delete_many({})


def test_home_page(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b"Test Student" in response.data


def test_add_student(client):
    data = {
        "name": "New User",
        "email": "new@user.com",
        "course": "Python"
    }

    response = client.post('/add', data=data, follow_redirects=True)

    assert response.status_code == 200
    assert b"New User" in response.data


def test_update_student(client):
    student_id = "66fddff25f4b5f6a0a123456"

    data = {
        "name": "Updated Name",
        "email": "updated@student.com",
        "course": "Updated Course"
    }

    response = client.post(f'/update/{student_id}', data=data, follow_redirects=True)

    assert response.status_code == 200
    assert b"Updated Name" in response.data


def test_delete_student(client):
    with app.app_context():
        temp_id = mongo.db.students.insert_one({
            "name": "Temp User",
            "email": "temp@user.com",
            "course": "Temp Course"
        }).inserted_id

    response = client.get(f'/delete/{temp_id}', follow_redirects=True)

    assert response.status_code == 200
    assert b"Temp User" not in response.data
