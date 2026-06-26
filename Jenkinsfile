pipeline {
    agent any

    environment {
        GCP_PROJECT_ID = 'gke-sre-500509'
        GCP_REGION = 'europe-west3'
        ARTIFACT_REPOSITORY = 'platform-lab'

        BACKEND_IMAGE_REPOSITORY = "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REPOSITORY}/platform-lab-backend"
        FRONTEND_IMAGE_REPOSITORY = "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REPOSITORY}/platform-lab-frontend"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Image Tag') {
            steps {
                script {
                    env.SHORT_COMMIT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "jenkins-${env.BUILD_NUMBER}-${env.SHORT_COMMIT}"

                    echo "Image tag will be: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    set -eu

                    echo "Checking Docker..."
                    docker --version

                    echo "Checking gcloud..."
                    gcloud --version

                    echo "Checking Git..."
                    git --version
                '''
            }
        }

        stage('Authenticate to Google Cloud') {
            steps {
                withCredentials([file(credentialsId: 'gcp-artifact-registry-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        set -eu

                        gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
                        gcloud config set project "${GCP_PROJECT_ID}"
                        gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --quiet
                    '''
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        --file app/backend/Dockerfile \
                        --tag "${BACKEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64" \
                        --platform linux/amd64 \
                        app/backend
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        --file app/frontend/Dockerfile \
                        --tag "${FRONTEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64" \
                        --platform linux/amd64 \
                        app/frontend
                '''
            }
        }

        stage('Push Backend Image') {
            steps {
                sh '''
                    set -eu

                    docker push "${BACKEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64"
                '''
            }
        }

        stage('Push Frontend Image') {
            steps {
                sh '''
                    set -eu

                    docker push "${FRONTEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64"
                '''
            }
        }

        stage('Deployment Instructions') {
            steps {
                echo """
                Images pushed successfully.

                Backend:
                ${BACKEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64

                Frontend:
                ${FRONTEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64

                Temporary manual deployment command:

                helm upgrade platform-lab kubernetes/helm/platform-lab \\
                  --namespace platform-lab-cloud \\
                  --values kubernetes/helm/platform-lab/environments/gke-values.yaml \\
                  --set backend.image.tag=${IMAGE_TAG}-amd64 \\
                  --set frontend.image.tag=${IMAGE_TAG}-amd64
                """
            }
        }
    }
}