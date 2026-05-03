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
<<<<<<< HEAD
                export TESTING=True
=======
>>>>>>> 335367bce4862bcee773245d2158619efa92ea73
                venv/bin/pytest -v
                '''
            }
        }

        stage('Deploy') {
            steps {
<<<<<<< HEAD
                echo "Deploy stage (simulated for CI/CD pipeline)"
=======
                echo "Deploy stage (simulated)"
>>>>>>> 335367bce4862bcee773245d2158619efa92ea73
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