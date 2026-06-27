        stage('Update GitOps Image Tags') {
            steps {
                sh '''
                    set -eu

                    git config user.email "jenkins@platform-lab.local"
                    git config user.name "Platform Lab Jenkins"

                    echo "Checking out main branch instead of detached HEAD..."
                    git fetch origin main
                    git checkout -B main origin/main

                    python3 - <<'PY'
from pathlib import Path
import os

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
        new_lines.append(f"{indentation}tag: {os.environ['IMAGE_TAG']}")
        inside_image = False
        continue

    new_lines.append(line)

values_path.write_text("\\n".join(new_lines) + "\\n")
PY

                    git status
                    git add kubernetes/helm/platform-lab/environments/gke-values.yaml

                    if git diff --cached --quiet; then
                        echo "No GitOps changes to commit."
                    else
                        git commit --message "Update image tag to ${IMAGE_TAG}"
                        git push origin main
                    fi
                '''
            }
        }