#!/bin/bash


##### Team portion
if [[ "$VERACODE_APP_NAME" == *"Raven"* ]]; then
    mkdir -p /root/.ssh && echo "${SSH_KEY}" | base64 -d > /root/.ssh/id_rsa && chmod 400 /root/.ssh/id_rsa
    ssh-keyscan gitlab.spectrumflow.net > /root/.ssh/known_hosts
fi

if [[ "$VERACODE_APP_NAME" == *"SpectrumEnterprise"* ]]; then

    mkdir -p .m2
    mkdir -p ~/.m2
    echo ${MAVEN_PASSWORD} | base64 -d > .m2/settings.xml
    echo ${MAVEN_PASSWORD} | base64 -d > ~/.m2/settings.xml
    echo ${MAVEN_MASTER_PASSWORD} | base64 -d > .m2/settings-security.xml
    echo ${MAVEN_MASTER_PASSWORD} | base64 -d > ~/.m2/settings-security.xml
fi
