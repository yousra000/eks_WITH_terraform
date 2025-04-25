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
                        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
                        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
                        aws configure set region $AWS_DEFAULT_REGION
                        aws sts get-caller-identity
                    '''

                    // Get ECR repository info with ANSI color codes stripped
                    dir('terraform') {
                        script {
                            sh 'terraform init'
                            
                            // Strip ANSI colors using sed
                            def rawOutput = sh(
                                script: 'terraform output -raw aws_ecr_repository',
                                returnStdout: true
                            ).trim()
                            
                            // Clean output and set environment variables
                            env.REGISTRY = rawOutput.replaceAll(/\[[\d;]+[mK]/, '').split('/')[0]
                            env.REPOSITORY = rawOutput.replaceAll(/\[[\d;]+[mK]/, '').split('/')[1]
                            
                            // Verify values
                            echo "Cleaned REGISTRY: ${env.REGISTRY}"
                            echo "Cleaned REPOSITORY: ${env.REPOSITORY}"
                        }
                    }

                    // Build and push Docker image
                    dir('nodeapp') {
                        script {
                            sh """
                                # Get ECR login token and login
                                aws ecr get-login-password --region $AWS_DEFAULT_REGION | \
                                docker login --username AWS --password-stdin ${env.REGISTRY}
                                
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
}
