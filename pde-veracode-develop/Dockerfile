ARG DOCKER_CDN

# New
FROM ${DOCKER_CDN}/ubuntu:20.04
USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# RUN dpkg --purge --force-depends ca-certificates-java

RUN apt-get -qq update && apt-get install -y \
	ca-certificates \
    wget \
    curl \
	tar \
    zip \
    jq \
	python3 \
    python3-pip \
	maven \
    gradle \
	git \
	openjdk-8-jdk \
	openjdk-11-jdk \
    apt-transport-https \
    software-properties-common \
    default-jdk \
	build-essential \
	libssl-dev \
    # ca-certificates-java \
    && rm -rf /var/lib/apt/lists/*

COPY / /veracode
RUN pip3 install -r /veracode/python/requirements.txt

ARG VERACODE_API_KEY_ID
ARG VERACODE_API_KEY_SECRET
ARG SENDER_SMTP
ARG SENDER_NAME_SMTP
ARG USERNAME_SMTP
ARG PASSWORD_SMTP
ARG HOST_SMTP
ARG ARTIFACTORY_API_KEY
ARG ARTIFACTORY_EMAIL
ARG VERACODE_ID
ARG VERACODE_KEY
ARG VERACODE_WRAPPER_VERSION
ARG VERACODE_BOT_TOKEN
ARG GITLAB_HOST_URL
ARG GITLAB_PRIVATE_TOKEN

ENV VERACODE_API_KEY_ID=${VERACODE_API_KEY_ID}
ENV VERACODE_API_KEY_SECRET=${VERACODE_API_KEY_SECRET}
ENV SENDER_SMTP=${SENDER_SMTP}
ENV SENDER_NAME_SMTP=${SENDER_NAME_SMTP}
ENV USERNAME_SMTP=${USERNAME_SMTP}
ENV PASSWORD_SMTP=${PASSWORD_SMTP}
ENV HOST_SMTP=${HOST_SMTP}
ENV ARTIFACTORY_API_KEY=${ARTIFACTORY_API_KEY}
ENV ARTIFACTORY_EMAIL=${ARTIFACTORY_EMAIL}
ENV VERACODE_ID=${VERACODE_ID}
ENV VERACODE_KEY=${VERACODE_KEY}
ENV VERACODE_WRAPPER_VERSION=${VERACODE_WRAPPER_VERSION}
ENV VERACODE_BOT_TOKEN=${VERACODE_BOT_TOKEN}
ENV GITLAB_HOST_URL=${GITLAB_HOST_URL}
ENV GITLAB_PRIVATE_TOKEN=${GITLAB_PRIVATE_TOKEN}

WORKDIR /veracode/scripts
RUN chmod +x pde_veracode
RUN find . -type f -iname "*.sh" -exec chmod +x {} \;

RUN ["mv", "pde_veracode", "/usr/local/bin/"]

# Install nvm locally
ENV INIT_NODE_VERSION 12.20.1
RUN touch ~/.profile
RUN /bin/bash /veracode/scripts/nvm_install.sh

RUN echo "source ~/.bashrc && \
	source ~/.nvm/nvm.sh && \
    nvm install $INIT_NODE_VERSION && \
    nvm alias default $INIT_NODE_VERSION && \
    nvm use default" | bash

ENV NODE_PATH ~/.nvm/v$INIT_NODE_VERSION/lib/node_modules`
ENV PATH ~/.nvm/versions/node/v$INIT_NODE_VERSION/bin:$PATH
