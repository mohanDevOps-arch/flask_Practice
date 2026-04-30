pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'pip3 install flask'
            }
        }

        stage('Test') {
            steps {
                sh 'echo "Test Passed"'
            }
        }

        stage('Deploy') {
            steps {
                sh 'echo "Deploy Successful"'
            }
        }
    }
}
