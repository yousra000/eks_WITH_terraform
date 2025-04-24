pipeline {
    agent any
    tools { 
        terraform 'terraform' 
    } 
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'
        DOCKER_IMAGE_TAG      = 'latest'
    }

    options {
        skipDefaultCheckout(false)
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        // STAGE 1: Checkout SCM
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install Tools') {
            steps {
                sh '''
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip awscliv2.zip
                    sudo ./aws/install

                    sudo apt-get update
                    sudo apt-get install -y docker.io
                '''
            }
        }
        stage('Use Tools') {
            steps {
                sh 'aws --version'
                sh 'docker --version'
            }
        }

        // STAGE 2: Terraform Init & Output
        stage('Get Terraform Output') {
            steps {
                dir('terraform') {
                    script {
                        // Initialize Terraform (if needed)
                        sh 'terraform init'

                        // Fetch ECR registry URL
                        REGISTRY = sh(
                            script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f1',
                            returnStdout: true
                        ).trim()
                        
                        // Fetch ECR repository name
                        REPOSITORY = sh(
                            script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f2',
                            returnStdout: true
                        ).trim()

                        env.REPOSITORY = REPOSITORY
                        env.REGISTRY = REGISTRY
                    }
                }
            }
        }

        // STAGE 3: Build & Push Docker Image
        stage('Build and Push Docker Image') {
            steps {
                dir('nodeapp') {
                    script {
                        // Login to ECR
                        sh """
                            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
                            docker login --username AWS --password-stdin ${env.REGISTRY}
                        """

                        // Build and push
                        sh """
                            docker build -t ${env.REGISTRY}/${env.REPOSITORY}:${DOCKER_IMAGE_TAG} .
                            docker push ${env.REGISTRY}/${env.REPOSITORY}:${DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }
    }
}
