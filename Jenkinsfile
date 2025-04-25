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

                    // Fetch the ECR repository URL dynamically from AWS
                    env.ECR_REGISTRY = sh(
                        script: 'aws ecr describe-repositories --query "repositories[0].repositoryUri" --output text',
                        returnStdout: true
                    ).trim()

                    env.REPOSITORY = sh(
                        script: 'aws ecr describe-repositories --query "repositories[0].repositoryName" --output text',
                        returnStdout: true
                    ).trim()

                    echo "ECR_REGISTRY=${env.ECR_REGISTRY}"
                    echo "REPOSITORY=${env.REPOSITORY}"

                    // AWS ECR login
                    sh """
                        aws ecr get-login --region ${env.AWS_DEFAULT_REGION} --no-include-email | \
                        docker login --username AWS --password-stdin ${env.ECR_REGISTRY}
                    """

                    dir('nodeapp') {
                        script {
                            // Docker build
                            sh """
                                docker build -t ${env.ECR_REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG} .
                            """

                            // Docker push
                            sh """
                                docker push ${env.ECR_REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG}
                            """
                        }
                    }
                }
            }
        }
    }
}
