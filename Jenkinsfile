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
    AWS_REGION     = 'us-east-1'   // ✅ added region to avoid missing var
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
              aws ecr get-login-password --region $AWS_REGION | \
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
                aws ecr get-login-password --region $AWS_REGION | \
                  docker login --username AWS --password-stdin ${ECR_REGISTRY} &&
                docker pull ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE
