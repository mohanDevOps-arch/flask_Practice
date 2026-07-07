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
                export TESTING=True
                venv/bin/pytest -v
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploy stage (simulated)"
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
