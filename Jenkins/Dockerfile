FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        git \
        gnupg \
        lsb-release \
        python3 \
    && install --mode=0755 --directory /etc/apt/keyrings \
    && curl --fail --silent --show-error --location https://download.docker.com/linux/debian/gpg --output /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list \
    && curl --fail --silent --show-error --location https://packages.cloud.google.com/apt/doc/apt-key.gpg --output /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        docker-ce-cli \
        docker-buildx-plugin \
        google-cloud-cli \
    && apt-get clean \
    && rm --recursive --force /var/lib/apt/lists/*

USER jenkins