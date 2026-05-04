# Flask App CI/CD Pipeline in 2 ways (with Github Actions & Jenkins)
# PART 1 — Flask CI/CD Pipeline (GitHub Actions + EC2 Staging Deployment)
# Project Overview
This project demonstrates a complete CI/CD pipeline for a Flask web application using:

# GitHub Actions for Continuous Integration (CI)
Automated testing (pytest)
Code quality checks (pylint, bandit)
Deployment to an AWS EC2 staging environment using SSH
# Tech Stack
Python 3.10 → Core programming language for application development
Flask → Web framework used to build the application’s backend services
MongoDB → NoSQL database used for storing and managing data
GitHub Actions → CI/CD platform used to automate testing and deployment workflows
EC2 → AWS Ubuntu Server for Staging Environment
Gunicorn → Production-grade WSGI server used to run the Flask application
Nginx → Reverse proxy server used to handle client requests and forward them to Gunicorn
systemd → Service manager used to run and manage the Flask application as a background service
# Repository Structure
flask_Practice/
│
├── app.py
├── requirements.txt
├── test_app.py
├── .github/
│   └── workflows/
│       └── ci-cd.yaml
├── templates/
├── static/
└── README.md
# CI/CD Pipeline Architecture
GitHub Push (staging branch)
        ↓
GitHub Actions Trigger
        ↓
CI Job (Test + Lint + Security Scan)
        ↓
If Success → SSH into EC2
        ↓
Pull latest code
        ↓
Install dependencies
        ↓
Restart Flask service (systemd)
        ↓
Nginx serves application
# ARCHITECTURE DIAGRAM
<img width="7392" height="2835" alt="image" src="https://github.com/user-attachments/assets/e02d0ad1-f436-4bb8-8a34-70e618b1b1d8" />

# CONTINUOUS INTEGRATION (CI)
# Runs automatically on every push to:

staging and main
CI Steps:
Checkout repository
Setup Python environment
Install dependencies
Run linting (pylint)
Run security scan (bandit)
Execute test suite (pytest)
CI Tools Used
pytest → unit testing
pylint → code quality check
bandit → security analysis
HOW TO RUN TESTS LOCALLY
# Create virtual environment
python -m venv venv

# Activate environment
# Windows:
venv\Scripts\activate

# Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest -v
First Things First
# STEP-1: Fork the Source Code from Github Repo
Source Code Repo Link ---> Fork ---> My own Repo Name ---> Fork only the main branch
Click Fork
Clone it locally:
git clone https://github.com/Saima-Devops/Flask-App-CI-CD-Pipeline.git
cd Flask-App-CI-CD-Pipeline
# STEP-2: Run & Test the App Locally
Open the project folder in 'VSCode'
<img width="1891" height="993" alt="image" src="https://github.com/user-attachments/assets/89630a32-8eff-42c6-a4fc-73aacab9bdd8" />
# Connect with MongoDB and get the URI
<img width="1474" height="726" alt="image" src="https://github.com/user-attachments/assets/3b8521ee-8dfe-431a-ab40-0149e90b7f91" />
# Set Environment Variables
Create .env file:

MONGO_URI=<your mongodb_connection_string_here>
Local Setup
Create a Virtual Environment first
python -m venv venv
# Activate venv
# Windows:
venv\Scripts\activate
# Linux / Mac:
source venv/bin/activate
Install all dependencies
pip install -r requirements.txt
python3 app.py
<img width="1314" height="647" alt="image" src="https://github.com/user-attachments/assets/624333dd-d707-4800-8616-f15c1b2e1667" />
<img width="1919" height="595" alt="image" src="https://github.com/user-attachments/assets/0372b6a1-46f5-4b10-83de-b2001b93242f" />
# Everything is working fine 👍

# Run Pytest on local:
<img width="1570" height="413" alt="image" src="https://github.com/user-attachments/assets/13aaa1ec-2efe-42cd-9007-77b7c49d3adf" />
# CONTINUOUS DEPLOYMENT (CD) - STAGING ON EC2
# Deployment happens only when code is pushed to:

# staging branch

# STEP-3 Github Branching Setup
git checkout -b staging
git push origin staging
git checkout main
# STEP-4 AWS EC2 STAGING ENVIRONMENT SETUP
Create an EC2 Instance with:
Ubuntu 22.04
Open ports:
22 (SSH)
80 (HTTP)
Install dependencies on EC2
sudo apt update -y
sudo apt install -y python3-pip python3-venv nginx git
Create application directory
sudo mkdir -p /var/www/flask_Practice

sudo chown -R ubuntu:ubuntu /var/www/flask_Practice
Gunicorn Setup
pip install gunicorn
gunicorn -w 3 -b 127.0.0.1:5000 app:app
Systemd Service
Create file:

sudo nano /etc/systemd/system/flask_Practice.service
Service Config
[Unit]
Description=flask_Practice
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/var/www/
Environment="PATH=/var/www/flask_Practice/venv/bin"
ExecStart=/var/www/flask_Practice/venv/bin/gunicorn -w 3 -b 127.0.0.1:5000 app:app

[Install]
WantedBy=multi-user.target
Start Service
sudo systemctl daemon-reload
sudo systemctl enable flask_Practice
sudo systemctl start flask_Practice
<img width="1229" height="572" alt="image" src="https://github.com/user-attachments/assets/6aab4a1a-0406-44cf-a054-dd51b6a3c674" />

# Nginx Configuration
sudo nano /etc/nginx/sites-available/flask-app
Config
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
Enable
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/flask-app /etc/nginx/sites-enabled

sudo nginx -t
sudo systemctl restart nginx
<img width="1240" height="382" alt="image" src="https://github.com/user-attachments/assets/473b4953-fb0f-4dd4-ba70-5cdce76fc8bb" />
STEP-5 Now Create Workflow Folder for GitHub Actions
Create Folders:

.github/workflows/
Create ci-cd.yaml inside folders as: .github/workflows/ci-cd.yaml

nano ci-cd.yaml

name: Flask CI/CD Pipeline

on:
  push:
    branches: [master, staging]

permissions:
  contents: read

jobs:

# ----------- CI -----------
  ci:
    runs-on: ubuntu-latest

    services:
      mongo:
        image: mongo:6
        ports:
          - 27017:27017

    env:
      MONGO_URI: mongodb://localhost:27017/testdb

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.10"

      - name: Install & Test
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt pytest pylint bandit

          pylint app.py || true
          bandit -r . -s B104,B101
          pytest -v


# ----------- STAGING -----------
  deploy-staging:
    needs: ci
    if: github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest

    steps:
      - uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.STAGING_SSH_KEY }}

      - name: Deploy Staging
        env:
          MONGO_URI: ${{ secrets.MONGO_URI }}
        run: |
          ssh -o StrictHostKeyChecking=no ${{ secrets.STAGING_USER }}@${{ secrets.STAGING_HOST }} \
          "MONGO_URI='${MONGO_URI}' bash -s" << EOF
          set -e

          APP_DIR="/var/www/flask-app"
          echo "🚀 Staging Deploy"

          sudo rm -rf \$APP_DIR
          sudo mkdir -p \$APP_DIR
          sudo chown -R \$USER:\$USER \$APP_DIR
          cd \$APP_DIR

          git clone -b staging https://github.com/Saima-Devops/Flask-App-CI-CD-Pipeline.git .

          echo "MONGO_URI=\$MONGO_URI" > .env

          sudo apt update -y
          sudo apt install -y python3-venv python3-pip nginx

          python3 -m venv venv
          source venv/bin/activate

          pip install --upgrade pip
          pip install -r requirements.txt
          pip install gunicorn

          sudo systemctl daemon-reload
          sudo systemctl enable flask-app
          sudo systemctl restart flask-app

          sudo systemctl restart nginx

          echo "✅ Staging Done"
          EOF


# ----------- PRODUCTION -----------
  deploy-production:
    needs: ci
    if: github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest

    steps:
      - uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.PROD_SSH_KEY }}

      - name: Deploy Production
        env:
          MONGO_URI: ${{ secrets.MONGO_URI }}
        run: |
          ssh -o StrictHostKeyChecking=no ${{ secrets.PROD_USER }}@${{ secrets.PROD_HOST }} \
          "MONGO_URI='${MONGO_URI}' bash -s" << EOF
          set -e

          APP_DIR="/var/www/flask-app"
          echo "🚀 Production Deploy"

          sudo rm -rf \$APP_DIR
          sudo mkdir -p \$APP_DIR
          sudo chown -R \$USER:\$USER \$APP_DIR
          cd \$APP_DIR

          git clone -b master https://github.com/Saima-Devops/Flask-App-CI-CD-Pipeline.git .

          echo "MONGO_URI=\$MONGO_URI" > .env

          sudo apt update -y
          sudo apt install -y python3-venv python3-pip nginx

          python3 -m venv venv
          source venv/bin/activate

          pip install --upgrade pip
          pip install -r requirements.txt
          pip install gunicorn

          sudo systemctl daemon-reload
          sudo systemctl enable flask-app
          sudo systemctl restart flask-app

          sudo systemctl restart nginx

          echo "✅ Production Done!"
          EOF



<img width="1914" height="941" alt="image" src="https://github.com/user-attachments/assets/ba1c9db8-c3bb-4066-af86-f789504ea515" />
# STEP-6: Add Github Secrets (Required)
Go to Github Repo:

Repo → Settings → Secrets → Actions

Add:

MONGO_URI
STAGING_HOST = (EC2 public ip)
STAGING_USER = (ec2 username, ubuntu in my case)
STAGING_SSH_KEY = (.pem file)
<img width="1854" height="433" alt="image" src="https://github.com/user-attachments/assets/b1ae11c6-893c-4e9f-816b-6fb27fb979b8" />
Deployment Flow
Push to staging branch
GitHub Actions runs CI
Deploys to EC2
Restarts Flask service
Nginx serves the app
# STEP-7: Push Code to Github from the Staging Branch
git add .
git commit -m "Added GitHub Actions CI/CD pipeline"
git push origin staging
This triggers:

Install dependencies
Run tests
Build
<img width="1887" height="778" alt="image" src="https://github.com/user-attachments/assets/3aad04e6-7144-43cb-8359-396666407f28" />
<img width="1891" height="939" alt="image" src="https://github.com/user-attachments/assets/b6e2d112-6795-4cde-9edf-2f7023e50a9a" />
# What This Pipeline Does
main : Runs CI only (test, lint, security)
staging : Runs CI + deploys to EC2
<img width="1509" height="708" alt="image" src="https://github.com/user-attachments/assets/a2e9adc6-1660-4a80-801e-e49caca51306" />
# STEP-8: Access the App
http://<EC2-PUBLIC-IP>
<img width="2821" height="659" alt="image" src="https://github.com/user-attachments/assets/6ec11dcf-58b8-403d-9cbe-54dbe44337c9" />
<img width="1919" height="522" alt="image" src="https://github.com/user-attachments/assets/d2c2c2db-729f-4e32-a218-1b7cd6f050e5" />
<img width="1545" height="438" alt="image" src="https://github.com/user-attachments/assets/a0a2f3c3-8a9a-489d-94c5-6c86a01c30f5" />
Final Output
✔ CI/CD fully automated
✔ Flask app deployed
✔ Nginx reverse proxy working
# PART:2 CI/CD Pipeline Automation with Jenkins
Stages
Install Dependencies
Lint & Security (pylint + bandit)
Run Tests (pytest)
Deploy Staging (branch: staging)
# ARCHITECTURE DIAGRAM
<img width="9117" height="2723" alt="image" src="https://github.com/user-attachments/assets/7d667150-ef10-4d48-ba83-25ed9d1500e5" />
<img width="1561" height="1001" alt="image" src="https://github.com/user-attachments/assets/095da1a1-7550-44e3-abe7-0fd1d31ed475" />
<img width="1912" height="946" alt="image" src="https://github.com/user-attachments/assets/fa699eff-a2bd-493a-909c-df4a37467303" />
# Create Jenkinsfile

pipeline {
    agent any

    environment {
        MONGO_URI = credentials('MONGO_URI')
        EC2_HOST = '54.221.90.160'
        EC2_USER = 'ubuntu'
        APP_DIR  = '/home/ubuntu/flask-app'
    }

    options {
        timestamps()
    }

    stages {

        stage('Clone') {
            steps {
                git branch: 'staging', url: 'https://github.com/Saima-Devops/Flask-App-CI-CD-Pipeline.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                set -e
                python3 -m venv venv
                . venv/bin/activate

                pip install --upgrade pip
                pip install -r requirements.txt

                # Dev tools
                pip install pytest pylint bandit
                '''
            }
        }

        stage('Code Quality') {
            steps {
                sh '''
                set -e
                . venv/bin/activate

                echo "🔍 Running pylint..."
                pylint app.py || true

                echo "🔐 Running bandit (only scanning app code)..."
                bandit app.py -s B104,B101
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                set -e
                . venv/bin/activate
                pytest -v
                '''
            }
        }

        stage('Deploy to EC2 (Staging)') {
            steps {
                sshagent(['ec2-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST '
                        set -e

                        echo "🚀 Starting Deployment"

                        if [ -d "$APP_DIR/.git" ]; then
                            cd $APP_DIR
                            git fetch origin
                            git reset --hard origin/staging
                        else
                            git clone -b staging https://github.com/Saima-Devops/Flask-App-CI-CD-Pipeline.git $APP_DIR
                            cd $APP_DIR
                        fi

                        echo "📦 Setting ENV"
                        echo "MONGO_URI=$MONGO_URI" > .env

                        echo "🐍 Setting up Python env"
                        python3 -m venv venv
                        source venv/bin/activate

                        pip install --upgrade pip
                        pip install -r requirements.txt
                        pip install gunicorn

                        echo "🔄 Restarting services"
                        sudo systemctl daemon-reload
                        sudo systemctl restart flask-app
                        sudo systemctl restart nginx

                        echo "✅ Deployment Successful"
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline succeeded'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}



<img width="908" height="515" alt="image" src="https://github.com/user-attachments/assets/76741c20-e7cf-4975-8b6b-eb40b5076ee6" />
<img width="926" height="636" alt="image" src="https://github.com/user-attachments/assets/b4e664a1-b0fb-4b02-9fd2-bf65ce247a46" />
<img width="950" height="520" alt="image" src="https://github.com/user-attachments/assets/9a444026-73be-4a47-8d24-85e1008a7936" />
<img width="921" height="644" alt="image" src="https://github.com/user-attachments/assets/bc173159-5f96-4e07-8510-4a18a52c8817" />
<img width="923" height="754" alt="image" src="https://github.com/user-attachments/assets/e9fbee7c-0651-41fa-b420-ae916d007149" />
<img width="1413" height="780" alt="image" src="https://github.com/user-attachments/assets/8ebdc57b-35c6-4bb1-9bad-1534e90c74f6" />
<img width="1918" height="947" alt="image" src="https://github.com/user-attachments/assets/fffbc211-4782-4a31-bd98-38e7f6110a0b" />

# Hurrey!! ✅🎉

# Troubleshooting
Fixed the Jenkinsfile Code Quality Stage as it was scanning the venv folder also, so I excluded that from scanning and tests. Here's the change:

stage("Code Quality") {
    steps {
        sh '''
        source .venv/bin/activate
        pylint app.py || true
        bandit -r . --exclude .venv
        '''
    }
}

# All Errors Fixed!!








