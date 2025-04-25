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

            dir('nodeapp') {
                sh """
                    aws ecr get-login-password | docker login --username AWS --password-stdin ${REGISTRY}
                    docker build -t ${REGISTRY}/${REPOSITORY}:latest .
                    docker push ${REGISTRY}/${REPOSITORY}:latest
                """
            }
        }
    }
}
    }
}

