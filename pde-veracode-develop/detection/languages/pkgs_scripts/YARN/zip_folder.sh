#!/bin/bash

zip_function() {
	zip -rq "$1" ./ -x \
		"*node_modules*" \
		"*.vscode*" \
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

#####################################################################################################
### if I rezip and save as veracode.zip, it doens't overwrite the old zip file
if [[ -f "${1}" ]]; then
    rm -f $1
fi

if [ -f "yarn.lock" ]; then
	echo "Found yarn.lock, zip the project..."
	zip_function "$1"
else
	echo "Cannot find yarn.lock, exit out"
	exit 1
fi
