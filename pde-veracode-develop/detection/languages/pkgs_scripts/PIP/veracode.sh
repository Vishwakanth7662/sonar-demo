#!/bin/bash

isFileExist () {
    if [ -f "$1" ]; then
        # 0 = true
        return 0
    else
        # 1 = false
        return 1
    fi
}

zip_project () {
	zip -rq "$1" ./ -i \
		"*.py" \
		"*.html" \
		"*.htm" \
        "requirements.txt" \
        "Pipfile.lock"
}

isDirectoryExist () {
    if [ -d "$1" ]; then
        # 0 = true
        return 0
    else
        # 1 = false
        return 1
    fi
}

if isFileExist "$VERACODE_FILE_NAME"; then
    rm -f $VERACODE_FILE_NAME
fi

# if there's a client/
if isDirectoryExist "client"; then
    echo "Found client folder, cd into it"
    cd client
	zip_project "../$VERACODE_FILE_NAME"
    cd ..
#if there's no client/, it means project is in root directory
else
	zip_project "$VERACODE_FILE_NAME"
fi
