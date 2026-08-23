pipeline {
    agent any

    environment {
        MONGO_URI = "mongodb://localhost:27017/testdb"
    }

    stages {

        stage('Build') {
            steps {
                sh '''
                echo "Build Stage: Creating venv and installing dependencies"

                python3 -m venv venv
                . venv/bin/activate

                pip install --upgrade pip
                pip install -r requirements.txt
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                echo "Test Stage: Running pytest"
                . venv/bin/activate

                export MONGO_URI=${MONGO_URI}
                pytest -v
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh '''
                echo "Deploy Stage: Starting Flask app on staging"

                pkill -f "python3 app.py" || true

                nohup venv/bin/python3 app.py > flask.log 2>&1 &
                echo "Flask app deployed successfully ✅"
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS ✅"
        }
        failure {
            echo "Pipeline FAILED ❌"
        }
    }
}
