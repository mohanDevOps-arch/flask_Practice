pipeline {
    agent any

    stages {

        stage('Build') {
            steps {
                echo 'Installing dependencies...'
                sh 'pip3 install -r requirements.txt'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'pytest'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying app...'
                sh 'nohup python3 app.py &'
            }
        }
    }

    post {
        success {
            echo 'Build Successful'
        }
        failure {
            echo 'Build Failed'
        }
    }
}
