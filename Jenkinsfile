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
        ),
        // Mount the workspace to use the Terraform state file if needed
        hostPathVolume(
            mountPath: '/workspace',
            hostPath: '/path/to/your/terraform/directory'
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

                    // Terraform Init to ensure state is loaded and backend is configured
                    dir('terraform') {
                        sh 'terraform init'
                    }

                    // Retrieve the ECR registry and repository from Terraform outputs
                    dir('terraform') {
                        env.REGISTRY = sh(
                            script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f1',
                            returnStdout: true
                        ).trim()
                        env.REPOSITORY = sh(
                            script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f2',
                            returnStdout: true
                        ).trim()
                    }

                    // Output the REGISTRY and REPOSITORY to verify
                    echo "REGISTRY=${env.REGISTRY}"
                    echo "REPOSITORY=${env.REPOSITORY}"

                    // Perform Docker login, build, and push steps
                    dir('nodeapp') {
                        script {
                            // AWS ECR login (AWS CLI v1 compatible)
                            sh """
                                aws ecr get-login --region ${env.AWS_DEFAULT_REGION} --no-include-email | \
                                docker login --username AWS --password-stdin ${env.REGISTRY}
                            """

                            // Docker build
                            sh """
                                docker build -t ${env.REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG} .
                            """

                            // Docker push
                            sh """
                                docker push ${env.REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG}
                            """
                        }
                    }
                }
            }
        }
    }
}
