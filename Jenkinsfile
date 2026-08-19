pipeline {
  agent any

  environment {
    ECR_REGISTRY = credentials('ecr-registry')
    ECR_REPO     = credentials('ecr-repo-name')
    EC2_HOST     = credentials('ec2-app-host')
    MONGO_URI    = credentials('mongo-uri')
    NOTIFY_EMAIL = credentials('notify-email')
    IMAGE_TAG    = "${env.GIT_COMMIT.take(7)}"
    FAILED_STAGE = ''
    AWS_REGION   = 'us-east-1'
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install dependencies') {
      steps {
        script { env.FAILED_STAGE = 'Install' }
        sh 'pip install --break-system-packages -r requirements.txt'
      }
    }

    stage('Test') {
      steps {
        script { env.FAILED_STAGE = 'Test' }
        sh 'pytest -v'
      }
    }

    stage('Build image') {
      steps {
        script {
          env.FAILED_STAGE = 'Build'
          docker.build("${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}")
        }
      }
    }

    stage('Push to ECR') {
      steps {
        script {
          env.FAILED_STAGE = 'Push'
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                             credentialsId: 'aws-creds']]) {
            sh """
              aws ecr get-login-password --region ${AWS_REGION} | \
                docker login --username AWS --password-stdin ${ECR_REGISTRY}
              docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
            """
          }
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        script {
          env.FAILED_STAGE = 'Deploy'
          sshagent(credentials: ['ec2-ssh-key']) {
            sh """
              ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} '
                aws ecr get-login-password --region ${AWS_REGION} | \
                  docker login --username AWS --password-stdin ${ECR_REGISTRY} &&
                docker pull ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} &&
                docker stop flask-app || true &&
                docker rm flask-app || true &&
                docker run -d --name flask-app -p 5000:5000 \
                  --restart unless-stopped \
                  -e MONGO_URI="${MONGO_URI}" \
                  ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
              '
            """
          }
        }
      }
    }

    stage('Verify') {
      steps {
        script {
          env.FAILED_STAGE = 'Verify (health check)'
          sh """
            for i in 1 2 3 4 5; do
              sleep 5
              STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://${EC2_HOST}:5000/health)
              if [ "\$STATUS" = "200" ]; then exit 0; fi
            done
            echo "Health check failed after 5 attempts"
            exit 1
          """
        }
      }
    }
  }

  post {
    success {
      emailext(
        subject: "✅ SUCCESS : flask-mongo-cicd #${env.BUILD_NUMBER}",
        to: "${NOTIFY_EMAIL}",
        mimeType: 'text/html',
        body: """
          <h2 style='color:#1E7B4D;'>Deployment Succeeded</h2>
          <p><b>Commit:</b> ${env.GIT_COMMIT}</p>
          <p><b>Image:</b> ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}</p>
          <p><b>Deployed to:</b> ${EC2_HOST}</p>
          <p><b>Pipeline run:</b> <a href='${env.BUILD_URL}'>${env.BUILD_URL}</a></p>
        """
      )
    }
    failure {
      emailext(
        subject: "❌ FAILURE: flask-mongo-cicd #${env.BUILD_NUMBER} — ${env.FAILED_STAGE} stage",
        to: "${NOTIFY_EMAIL}",
        mimeType: 'text/html',
        body: """
          <h2 style='color:#B3261E;'>Deployment Failed</h2>
          <p><b>Failed stage:</b> ${env.FAILED_STAGE}</p>
          <p><b>Commit:</b> ${env.GIT_COMMIT}</p>
          <p><b>Logs:</b> <a href='${env.BUILD_URL}console'>${env.BUILD_URL}console</a></p>
        """
      )
    }
  }
}
