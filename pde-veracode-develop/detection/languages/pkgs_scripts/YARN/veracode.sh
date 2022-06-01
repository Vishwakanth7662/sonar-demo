#!/bin/bash

#Include both package.json and yarn.lock or a node_modules directory in the root of your ZIP archive.
#Note: If you include a node_modules directory without both package.json and yarn.lock,
#your results may include development dependencies.

zip_project () {
    zip -rq "$1" ./ -x \
        "*node_modules*" \
        '*.git*' \
        "*.deploy*" \
        '*cypress*' \
        '*.cypress*' \
        '*dist*' \
        "*k8s*" \
        "*.dockerignore*" \
        "*.gitignore*" \
        "*.gitlab-ci*" \
        "*.yml*" \
        "*.yaml*" \
        "*Dockerfile" \
        "*README.md*" \
        "*.sh*" \
        "*.editor*" \
        "*.eslint*" \
        "*.DS_Store*" \
        "*.env*" \
        "*.log*" \
        "*__tests__*" \
        "*nginx*" \
		"*public*" \
        "*.md*" \
		"*fonts*" \
		"*images*" \
		"*.ico*" \
		"*.xml*" \
		"*.hbs*" \
        "*.tar*" \
        "*.gz*" \
        "*.zip*" \
        "*.tgz*" \
        "*.exe*" \
        "*.py*"
}

### if I rezip and save as veracode.zip, it doens't overwrite the old zip file
if [ -f "$VERACODE_FILE_NAME" ]; then
    rm -f $VERACODE_FILE_NAME
fi

# if there's a client/
if [[ -d "client" ]]; then

    cd client
    if [ -f "yarn.lock" ]; then
        echo "Found yarn.lock, zip the project..."
        zip_project "../$VERACODE_FILE_NAME"
    else
        echo "Cannot find yarn.lock, exit out"
        exit 1
    fi
    cd ..

#if there's no client/, it means project is in root directory
else
    if [[ "${CI_PROJECT_NAME}" == "distillery" ]] && [[ -f .deploy/deploy_key ]] && [[ -f .deploy/deploy_key.pub ]]; then
        if [[ ! -d "/path/to/dir" ]]; then
            mkdir /root/.ssh
        fi
        if [[ ! -f /root/.ssh/known_hosts ]]; then
            touch /root/.ssh/known_hosts
        fi
        ssh-keyscan -t rsa gitlab.spectrumflow.net >> /root/.ssh/known_hosts
        cp .deploy/deploy_key /root/.ssh/id_rsa
        cp .deploy/deploy_key.pub /root/.ssh/id_rsa.pub
        chmod -R 600 /root/.ssh
    fi

    if [ -f "yarn.lock" ]; then
        echo "Found yarn.lock, zip the project..."
        zip_project "$VERACODE_FILE_NAME"
    else
        echo "Cannot find yarn.lock, exit out"
        exit 1
    fi

fi