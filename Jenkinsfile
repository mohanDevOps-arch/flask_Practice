pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh '''
                if [ ! -d "venv" ]; then
                    python3 -m venv venv
                fi
                venv/bin/pip install --upgrade pip
                venv/bin/pip install -r requirements.txt
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
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
