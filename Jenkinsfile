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
                        echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
                        echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"

                        # Ensure the region is passed properly by using ${AWS_DEFAULT_REGION} 
                        aws sts get-caller-identity --region ${AWS_DEFAULT_REGION}
                    '''

                    dir('terraform') {
                        script {
                            REGISTRY = sh(
                                script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f1',
                                returnStdout: true
                            ).trim()
                            REPOSITORY = sh(
                                script: 'terraform output -raw aws_ecr_repository | cut -d "/" -f2',
                                returnStdout: true
                            ).trim()

                            env.REGISTRY = REGISTRY
                            env.REPOSITORY = REPOSITORY
                        }
                    }

                    dir('nodeapp') {
                        sh """
                            # Ensure the region is passed correctly to aws login and docker push
                            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REGISTRY}
                            docker build -t ${REGISTRY}/${REPOSITORY}:${DOCKER_IMAGE_TAG} .
                            docker push ${REGISTRY}/${REPOSITORY}:${DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }
    }
}
