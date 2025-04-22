pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'  // Change to your region
        DOCKER_IMAGE_TAG     = 'latest'
        DB_PASSWORD        = credentials('DB_PASSWORD')  // Assuming you have a Jenkins credential for DB password
        DB_USERNAME       = credentials('DB_USERNAME')  // Assuming you have a Jenkins credential for DB password
    }

    options {
        skipDefaultCheckout(false)  // enable automatic SCM checkout
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }


    stages {
        
        // STAGE 2: Terraform (init & apply)
        stage('Terraform Apply') {
            options {
        timeout(time: 30, unit: 'MINUTES')  // Increase from default
    }
            steps {
                dir('terraform') {  // Changes directory to terraform/
                    script {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
}

        // STAGE 3: Get terraform output and set environment variables
        stage('Get terraform output') {
            steps {
                dir('terraform') {  // Changes directory to terraform/
                script {
                    // Fetch ECR registry URL from Terraform output
                    REGISTRY = sh(
                        script: 'terraform  output -raw aws_ecr_repository | cut -d "/" -f1',
                        returnStdout: true
                    ).trim()
                    
                    // Fetch ECR repository name from Terraform output
                    REPOSITORY = sh(
                        script: 'terraform  output -raw aws_ecr_repository | cut -d "/" -f2',
                        returnStdout: true
                    ).trim()
                    

                    env.REPOSITORY = REPOSITORY
                    env.REGISTRY = REGISTRY
                }
            }
        }
        }

        // STAGE 4: Login to ECR, Build & Push Docker Image
        stage('Build and Push Docker Image') {
            steps {
                dir('nodeapp') {  // Changes directory to terraform/
                script {
                    // Login to AWS ECR
                    sh  "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | sudo docker login --username AWS --password-stdin ${env.REGISTRY}"

                    // Build Docker image
                    sh "sudo docker build -t ${env.REGISTRY}/${env.REPOSITORY}:${DOCKER_IMAGE_TAG} ."

                    // Push to ECR
                    sh "sudo docker push ${env.REGISTRY}/${env.REPOSITORY}:${DOCKER_IMAGE_TAG}"
                }
            }
        }
        }

    }


}