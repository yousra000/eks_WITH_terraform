podTemplate(
    label: 'jenkins_label',
    containers: [
        containerTemplate(
            name: 'dockerimage',
            image: 'maeltohamy/jenkins-agent',
            command: 'sh',
            args: '-c "dockerd & sleep 99999"', // Start Docker daemon in the background and keep container alive
            ttyEnabled: true,
            privileged: true
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
                    '''

                    script {
                        def registry = sh(
                            script: 'aws ecr describe-repositories --query "repositories[0].repositoryUri" --output text | cut -d "/" -f1',
                            returnStdout: true
                        ).trim()

                        def repository = sh(
                            script: 'aws ecr describe-repositories --query "repositories[0].repositoryName" --output text',
                            returnStdout: true
                        ).trim()

                        env.REGISTRY = registry
                        env.REPOSITORY = repository

                        echo "REGISTRY=${env.REGISTRY}"
                        echo "REPOSITORY=${env.REPOSITORY}"
                    }

                    dir('nodeapp') {
                        sh """
                            aws ecr get-login-password | docker login --username AWS --password-stdin ${env.REGISTRY}
                            docker build -t ${env.REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG} .
                            docker push ${env.REGISTRY}/${env.REPOSITORY}:${env.DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }
    }
}
