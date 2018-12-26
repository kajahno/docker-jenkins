FROM jenkins/jenkins:lts
MAINTAINER Karl Jahn <kajahno@gmail.com>

# Suppress apt installation warnings
ENV DEBIAN_FRONTEND=noninteractive

# Change to root user
USER root

# Used to set the docker group ID
# Set to 497 by default, which is the group ID used by AWS Linux ECS Instance
ARG DOCKER_GID=497

# Create Docker Group with GID
RUN groupadd -g ${DOCKER_GID:-497} docker

# Used to control Docker and Docker Compose versions installed
# NOTE: worth checking which version of AWS Linux ECS is supported in Docker 1.9.1
ARG DOCKER_ENGINE=18.06.1
ARG DOCKER_COMPOSE=1.22.0

# Install base packages
RUN apt-get update -y && \
    apt-get install -yq apt-transport-https python-dev python-setuptools gcc make libssl-dev \
        ca-certificates \
        curl \
        software-properties-common && \
    easy_install pip

# Install Docker Engine
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) \
        stable" && \
    apt-get update -y && \
    apt-get install -y docker-ce=${DOCKER_ENGINE:-18.06.1}~ce~3-0~debian && \
    usermod -aG docker jenkins && \
    usermod -aG users jenkins

# Instal Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE:-1.22.0}/docker-compose-$(uname -s)-$(uname -m)" \ 
    -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    pip install ansible boto boto3

# give jenkins docker rights
RUN usermod -aG docker jenkins

# Change to jenkins user
USER jenkins

# Add Jenkins plugins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

