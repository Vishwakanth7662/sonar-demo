#!/bin/bash

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

if [[ -f "${1}" ]]; then
    rm -f $1
fi

if [ -f "package-lock.json" ]; then
    echo "Found package-lock.json, zip the project..."
    zip_project "$1"
else
    echo "Cannot find package-lock.json, exit out"
    exit 1
fi