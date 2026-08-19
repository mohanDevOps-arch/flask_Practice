pipeline {
  agent any

  environment {
    ECR_REGISTRY = credentials('ecr-registry')
    ECR_REPO     = credentials('ecr-repo-name')
    EC2_HOST     = credentials('ec2-app-host')
    MONGO_URI    = credentials('mongo-uri')
    AWS_REGION   = 'us-east-1'
    NOTIFY_EMAIL = 'shabdadhankkb@gmail.com'
    FAILED_STAGE = ''
  }

  stages {

    stage('Checkout') {
      steps {
        script { env.FAILED_STAGE = 'Checkout' }
        checkout scm
        script {
          env.IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
          env.GIT_BRANCH = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
        }
      }
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
                docker run -d --name flask-app --restart unless-stopped \
                  -p 5000:5000 \
                  -e MONGO_URI="${MONGO_URI}" \
                  ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
              '
            """
          }
        }
      }
    }

    stage('Verify deployment') {
      steps {
        script {
          env.FAILED_STAGE = 'Verify'
          sh """
            for i in 1 2 3 4 5; do
              sleep 5
              STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://${EC2_HOST}:5000/health)
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
        subject: "✅ SUCCESS: flask_Practice #${env.BUILD_NUMBER} deployed",
        to: "${NOTIFY_EMAIL}",
        mimeType: 'text/html',
        body: """
          <h2 style='color:#1E7B4D;'>Deployment Succeeded</h2>
          <p><b>Branch:</b> ${env.GIT_BRANCH}</p>
          <p><b>Commit SHA:</b> ${env.GIT_COMMIT}</p>
          <p><b>Image Tag:</b> ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}</p>
          <p><b>EC2 Target:</b> ${EC2_HOST}</p>
          <p><b>Run URL:</b> <a href='${env.BUILD_URL}'>${env.BUILD_URL}</a></p>
        """
      )
    }
    failure {
      emailext(
        subject: "❌ FAILED: flask_Practice #${env.BUILD_NUMBER} — ${env.FAILED_STAGE} stage",
        to: "${NOTIFY_EMAIL}",
        mimeType: 'text/html',
        body: """
          <h2 style='color:#B3261E;'>Deployment Failed</h2>
          <p><b>Failed Stage:</b> ${env.FAILED_STAGE}</p>
          <p><b>Branch:</b> ${env.GIT_BRANCH}</p>
          <p><b>Commit SHA:</b> ${env.GIT_COMMIT}</p>
          <p><b>Run URL:</b> <a href='${env.BUILD_URL}console'>${env.BUILD_URL}console</a></p>
        """
      )
    }
  }
}
