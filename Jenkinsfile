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
        // Define environment variables inside node
        environment {
            AWS_DEFAULT_REGION = 'us-east-1'
            DOCKER_IMAGE_TAG   = 'latest'
        }

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
                    
                    // Terraform steps
                    dir('terraform') {
                        sh 'terraform init'
                        REGISTRY = sh(
                            script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f1',
                            returnStdout: true
                        ).trim()
                        REPOSITORY = sh(
                            script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f2',
                            returnStdout: true
                        ).trim()
                    }

                    // Docker steps
                    dir('nodeapp') {
                        sh """
                            aws ecr get-login-password | docker login --username AWS --password-stdin ${REGISTRY}
                            docker build -t ${REGISTRY}/${REPOSITORY}:${DOCKER_IMAGE_TAG} .
                            docker push ${REGISTRY}/${REPOSITORY}:${DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }
    }  // This closes the node block
}  // This closes the podTemplate block
