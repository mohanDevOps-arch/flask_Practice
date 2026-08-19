pipeline {
  agent any
 
  environment {
    ECR_REGISTRY   = credentials('ecr-registry')
    ECR_REPO       = credentials('ecr-repo-name')
    EC2_HOST       = credentials('ec2-app-host')
    MONGO_URI      = credentials('mongo-uri')
    NOTIFY_EMAIL   = credentials('notify-email')
    IMAGE_TAG      = "${env.GIT_COMMIT}"
    FAILED_STAGE   = ''
  }
 
  stages {
 
    stage('Checkout') {
      steps { checkout scm }
    }
 
    stage('Install dependencies') {
      steps {
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
              aws ecr get-login-password --region \$AWS_REGION | \\
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
                aws ecr get-login-password --region \$AWS_REGION | \\
                  docker login --username AWS --password-stdin ${ECR_REGISTRY} &&
                docker pull ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} &&
                docker stop flask-app || true &&
                docker rm flask-app || true &&
                docker run -d --name flask-app --restart unless-stopped \\
                  -p 5000:5000 \\
                  -e MONGO_URI="${MONGO_URI}" \\
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
            sleep 8
            STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://${EC2_HOST}:5000/health)
            echo "Health check returned \$STATUS"
            [ "\$STATUS" = "200" ]
          """
        }
      }
    }
  }
 
  post {
    success {
      emailext(
        subject: "[SUCCESS] flask_Practice deployed - ${env.GIT_COMMIT}",
        to: "${env.NOTIFY_EMAIL}",
        body: """
          Deployment succeeded.
 
          Branch:      main
          Commit SHA:  ${env.GIT_COMMIT}
          Image tag:   ${env.ECR_REGISTRY}/${env.ECR_REPO}:${env.IMAGE_TAG}
          EC2 target:  ${env.EC2_HOST}
          Run URL:     ${env.BUILD_URL}
        """
      )
    }
    failure {
      emailext(
        subject: "[FAILED] flask_Practice pipeline - ${env.GIT_COMMIT}",
        to: "${env.NOTIFY_EMAIL}",
        body: """
          Deployment failed.
 
          Branch:      main
          Commit SHA:  ${env.GIT_COMMIT}
          Failed stage: ${env.FAILED_STAGE}
          Run URL:      ${env.BUILD_URL}console
        """
      )
    }
  }
}

