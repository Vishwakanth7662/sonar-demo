#!/bin/bash

#Include npm-shrinkwrap.json, package-lock.json, or a node_modules directory in the root of your ZIP archive.
#Note: If you include a node_modules directory without either npm-shrinkwrap.json or package-lock.json,
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

#######################################################

# if there's a client/
if [ -d "client" ]; then

    cd client
    if [ -f "package-lock.json" ]; then
        echo "Found package-lock.json, zip the project..."
        zip_project "../$VERACODE_FILE_NAME"
    else
        echo "Cannot find package-lock.json, exit out"
        exit 1
    fi
    cd ..

#if there's no client/, it means project is in root directory
else
    if [ -f "package-lock.json" ]; then
        echo "Found package-lock.json, zip the project..."
        zip_project "$VERACODE_FILE_NAME"
    else
        echo "Cannot find package-lock.json, exit out"
        exit 1
    fi
fi
