podTemplate(
    label: 'jenkins_label',
    containers: [
        containerTemplate(
            name: 'dockerimage',
            image: 'yousra000/dind-aws-terraform:latest',
            command: 'sleep',
            args: '9999999',
            ttyEnabled: true
        )
    ],
    volumes: [
        hostPathVolume(
            mountPath: '/var/run/docker.sock',
            hostPath: '/var/run/docker.sock'
        )
    ]
) {
    node('jenkins_label') {
        // Define environment variables
        env.AWS_DEFAULT_REGION = 'us-east-1'
        env.DOCKER_IMAGE_TAG = 'latest'

        stage('Prepare Environment') {
            container('dockerimage') {
                sh '''
                    echo "=== Versions ==="
                    docker --version
                    aws --version
                    terraform --version
                '''
            }
        }

        stage('Run Pipeline') {
            container('dockerimage') {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        # Configure AWS CLI
                        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
                        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
                        aws configure set region us-east-1
                        
                        # Verify credentials
                        aws sts get-caller-identity
                    '''
                    
                    // Verify Terraform files exist
                    sh 'ls -la terraform/ || echo "No terraform directory found"'
                    
                    dir('terraform') {
                        // Initialize Terraform
                        sh 'terraform init -input=false'
                        
                        // Get outputs (with error handling)
                        script {
                            try {
                                env.REGISTRY = sh(
                                    script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f1',
                                    returnStdout: true
                                ).trim()
                                env.REPOSITORY = sh(
                                    script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f2',
                                    returnStdout: true
                                ).trim()
                                
                                if (!env.REGISTRY || !env.REPOSITORY) {
                                    error "Failed to get ECR repository information from Terraform outputs"
                                }
                            } catch (Exception e) {
                                error "Terraform output failed: ${e.getMessage()}"
                            }
                        }
                    }

                    dir('nodeapp') {
                        sh """
                            # Login to ECR
                            aws ecr get-login-password | docker login --username AWS --password-stdin ${env.REGISTRY}
                            
                            # Build and push image
                            docker build -t ${env.REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG} .
                            docker push ${env.REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }
    }
}
