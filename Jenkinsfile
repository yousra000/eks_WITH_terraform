podTemplate(
    label: 'jenkins_label',
    containers: [
        containerTemplate(
            name: 'dockerimage',
            image: 'yousra000/dind-aws-terraform:latest',
            command: '/bin/sh',
            args: '-c "dockerd-entrypoint.sh & sleep infinity"',
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
                    git --version
                    aws --version
                '''
            }
        }

        stage('Clone Repo') {
            container('dockerimage') {
                // Remove existing directory if it exists
                sh 'rm -rf eks_WITH_terraform'
                sh 'git clone https://github.com/yousra000/eks_WITH_terraform.git'
                dir('eks_WITH_terraform') {
                    sh 'git remote -v'
                    sh 'git status'
                    sh 'ls -lr'
                }
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
                        aws configure set region us-east-1
                    '''

                    script {
                        env.REGISTRY = sh(
                            script: 'aws ecr describe-repositories --query "repositories[0].repositoryUri" --output text | cut -d "/" -f1',
                            returnStdout: true
                        ).trim()

                        env.REPOSITORY = sh(
                            script: 'aws ecr describe-repositories --query "repositories[0].repositoryName" --output text',
                            returnStdout: true
                        ).trim()

                        echo "REGISTRY=${env.REGISTRY}"
                        echo "REPOSITORY=${env.REPOSITORY}"
                    }

                    dir('eks_WITH_terraform/nodeapp') {
                        sh """
                            echo "Current Directory: \$(pwd)"
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
