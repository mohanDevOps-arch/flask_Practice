pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/fancy1505/flask_Practice.git'
            }
        }

        stage('Build') {
            steps {
                sh '''
                python3 -m venv venv
                venv/bin/pip install --upgrade pip
                venv/bin/pip install -r requirements.txt
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                venv/bin/pytest
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploy stage (simulated for CI/CD pipeline)"
                sh '''
                nohup venv/bin/python app.py > app.log 2>&1 &
                '''
            }
        }
    }

    post {
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
