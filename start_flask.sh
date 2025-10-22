#!/bin/bash
cd ~/flask_Practice

# Create venv if not exists
if [ ! -d venv ]; then
    python3 -m venv venv
fi

# Activate venv
source venv/bin/activate

# Upgrade pip and install dependencies
pip install --upgrade pip
pip install -r requirements.txt black pylint bandit pytest pytest-html

# Ensure .env exists
echo -e "MONGO_URI=mongodb+srv://mohan:Herovired123@herovired.f3do4.mongodb.net/studentDB\nSECRET_KEY=your-secret-key" > .env

# Run app
nohup python3 app.py --host=0.0.0.0 --port=5000 > flask.log 2>&1 &
