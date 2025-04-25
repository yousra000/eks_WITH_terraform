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
        // Environment setup
        env.AWS_DEFAULT_REGION = 'us-east-1'
        env.DOCKER_IMAGE_TAG = 'latest'

        // STAGE 1: Prepare Environment
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

        // STAGE 2: Run Pipeline
        stage('Run Pipeline') {
            container('dockerimage') {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    // Configure AWS and verify credentials
                    sh '''
                        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
                        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
                        aws configure set region $AWS_DEFAULT_REGION
                        aws sts get-caller-identity
                    '''

                    // STAGE 2.1: Terraform Init & Output
                    dir('terraform') {
                        script {
                            sh 'terraform init'
                            
                            env.REGISTRY = sh(
                                script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f1',
                                returnStdout: true
                            ).trim()
                            
                            env.REPOSITORY = sh(
                                script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f2',
                                returnStdout: true
                            ).trim()
                        }
                    }

                    // STAGE 2.2: Build & Push Docker Image
                    dir('nodeapp') {
                        script {
                            sh """
                                aws ecr get-login-password --region $AWS_DEFAULT_REGION | \
                                docker login --username AWS --password-stdin ${env.REGISTRY}
                                
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
