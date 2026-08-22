from flask import Flask, render_template, request, redirect, url_for
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
from dotenv import load_dotenv
import certifi
import os

# Load env vars
load_dotenv()

app = Flask(__name__)
app.config["MONGO_URI"] = os.getenv("MONGO_URI")
app.secret_key = os.getenv("SECRET_KEY")

# Only pin certifi's CA bundle when the URI actually uses TLS. Passing
# tlsCAFile implicitly enables TLS on the pymongo client, which breaks
# plain mongodb:// connections (e.g. the local mongo:7 service used in CI).
_mongo_uri = os.getenv("MONGO_URI") or ""
_needs_tls = _mongo_uri.startswith("mongodb+srv://") or "tls=true" in _mongo_uri.lower()
_mongo_kwargs = {"tlsCAFile": certifi.where()} if _needs_tls else {}
mongo = PyMongo(app, **_mongo_kwargs)

# Health check -> verifies MongoDB connectivity (used as deploy verification gate)
@app.route('/health')
def health():
    try:
        mongo.cx.admin.command('ping')
        return {"status": "healthy", "mongo": "connected"}, 200
    except Exception as exc:
        return {"status": "unhealthy", "mongo": str(exc)}, 503


# Home page -> list students
@app.route('/')
def index():
    students = mongo.db.students.find()
    return render_template('index.html', students=students)

# Add student
@app.route('/add', methods=['GET', 'POST'])
def add_student():
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        course = request.form['course']
        mongo.db.students.insert_one({
            "name": name,
            "email": email,
            "course": course
        })
        return redirect(url_for('index'))
    return render_template('add_student.html')

# Update student
@app.route('/update/<student_id>', methods=['GET', 'POST'])
def update_student(student_id):
    student = mongo.db.students.find_one({"_id": ObjectId(student_id)})
    if request.method == 'POST':
        new_name = request.form['name']
        new_email = request.form['email']
        new_course = request.form['course']
        mongo.db.students.update_one(
            {"_id": ObjectId(student_id)},
            {"$set": {"name": new_name, "email": new_email, "course": new_course}}
        )
        return redirect(url_for('index'))
    return render_template('update_student.html', student=student)


# Delete student
@app.route('/delete/<student_id>')
def delete_student(student_id):
    mongo.db.students.delete_one({"_id": ObjectId(student_id)})
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host="0.0.0.0", debug=True, port=5000)


