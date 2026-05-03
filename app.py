from flask import Flask, render_template, request, redirect, url_for
import os

app = Flask(__name__)

# Secret key
app.secret_key = "mysecretkey"

# Detect testing mode
TESTING = os.getenv("TESTING", "False") == "True"

# Only connect Mongo if NOT testing
if not TESTING:
    from flask_pymongo import PyMongo
    from bson.objectid import ObjectId
    import certifi

    app.config["MONGO_URI"] = os.getenv(
        "MONGO_URI",
        "mongodb+srv://FANCYKEJRIWAL:F%4015051996cy@cluster0.xxxxx.mongodb.net/testdb?retryWrites=true&w=majority"
    )

    mongo = PyMongo(app, tlsCAFile=certifi.where())
else:
    mongo = None


# ---------------- ROUTES ---------------- #

# Home page
@app.route('/')
def index():
    if mongo:
        students = mongo.db.students.find()
        return render_template('index.html', students=students)
    else:
        return "Hello, Jenkins CI/CD!"


# Add student
@app.route('/add', methods=['GET', 'POST'])
def add_student():
    if not mongo:
        return "DB not available in CI"

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
    if not mongo:
        return "DB not available in CI"

    student = mongo.db.students.find_one({"_id": ObjectId(student_id)})

    if request.method == 'POST':
        mongo.db.students.update_one(
            {"_id": ObjectId(student_id)},
            {"$set": {
                "name": request.form['name'],
                "email": request.form['email'],
                "course": request.form['course']
            }}
        )
        return redirect(url_for('index'))

    return render_template('update_student.html', student=student)


# Delete student
@app.route('/delete/<student_id>')
def delete_student(student_id):
    if not mongo:
        return "DB not available in CI"

    mongo.db.students.delete_one({"_id": ObjectId(student_id)})
    return redirect(url_for('index'))


# Run app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)