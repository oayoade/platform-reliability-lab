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

        stage('Prepare Docker Builder') {
            steps {
                sh '''
                    set -eu

                    docker buildx version

                    docker buildx create \
                        --name platform-lab-builder \
                        --use || docker buildx use platform-lab-builder

                    docker buildx inspect --bootstrap
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

        stage('Build and Push Backend Image') {
            steps {
                sh '''
                    set -eu

                    docker buildx build \
                        --file app/backend/Dockerfile \
                        --tag "${BACKEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64" \
                        --platform linux/amd64 \
                        --push \
                        app/backend
                '''
            }
        }

        stage('Build and Push Frontend Image') {
            steps {
                sh '''
                    set -eu

                    docker buildx build \
                        --file app/frontend/Dockerfile \
                        --tag "${FRONTEND_IMAGE_REPOSITORY}:${IMAGE_TAG}-amd64" \
                        --platform linux/amd64 \
                        --push \
                        app/frontend
                '''
            }
        }

        stage('Update GitOps Image Tags') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-write-token', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh '''
                        set -eu

                        git config user.email "jenkins@platform-lab.local"
                        git config user.name "Platform Lab Jenkins"

                        python3 - <<'PY'
from pathlib import Path

values_path = Path("kubernetes/helm/platform-lab/environments/gke-values.yaml")
content = values_path.read_text()

old_lines = content.splitlines()
new_lines = []

inside_backend = False
inside_frontend = False
inside_image = False

for line in old_lines:
    stripped = line.strip()

    if line.startswith("backend:"):
        inside_backend = True
        inside_frontend = False
        inside_image = False
        new_lines.append(line)
        continue

    if line.startswith("frontend:"):
        inside_backend = False
        inside_frontend = True
        inside_image = False
        new_lines.append(line)
        continue

    if stripped == "image:" and (inside_backend or inside_frontend):
        inside_image = True
        new_lines.append(line)
        continue

    if inside_image and stripped.startswith("tag:"):
        indentation = line[: len(line) - len(line.lstrip())]
        new_lines.append(f"{indentation}tag: {__import__('os').environ['IMAGE_TAG']}")
        inside_image = False
        continue

    new_lines.append(line)

values_path.write_text("\\n".join(new_lines) + "\\n")
PY

                        git status
                        git add kubernetes/helm/platform-lab/environments/gke-values.yaml

                        if git diff --cached --quiet; then
                            echo "No Gitops changes to commit"
                        else
                            git commit --message "Update image tag to ${IMAGE_TAG}"
                            git remote set-url origin "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/oayoade/platform-reliability-lab.git"
                            git push origin HEAD:main
                        fi
                    '''
                }
            }
        }
    }
}