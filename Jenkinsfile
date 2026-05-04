pipeline {
    agent any

    environment {
      MONGO_URI = "mongodb://localhost:27017/testdb"
    }

    stages {

        stage('Build') {
            steps {
                sh '''
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
                . venv/bin/activate
                pytest
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                echo "Deploying application..."
                . venv/bin/activate
		nohup python app.py &
                '''
            }
        }
    }

    post {
        success {
		echo "sucess"
            //mail to: 'hanusaimadhava@gmail.com',
                // subject: "SUCCESS: Jenkins Pipeline",
              //   body: "Build and deployment successful."
        }
        failure {
		echo "fail"
            //mail to: 'hanusaimadhava@gmail.com',
                 //subject: "FAILED: Jenkins Pipeline",
                 //body: "Build failed"
        }
    }
}



