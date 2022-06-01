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

isDirectoryExist () {
    if [ -d "$1" ]; then
        # 0 = true
        return 0
    else
        # 1 = false
        return 1
    fi
}

### if I rezip and save as veracode.zip, it doens't overwrite the old zip file
zip_project () {
    zip -rq "$1" ./ -i \
        "*.php" \
        "*.module" \
        "*.inc" \
        "*.html" \
        "*.htm" \
        "*.profile" \
        "*.install" \
        "*.engine" \
        "*.theme" \
        "*.php4" \
        "*.php5" \
        "*.php7" \
        "*.phtml" \
        "*.json" \
        "*.lock" \
        "*.htaccess"
}


if isFileExist "$VERACODE_FILE_NAME"; then
    rm -f $VERACODE_FILE_NAME
fi

# if there's a client/
if isDirectoryExist "code"; then
    echo "Found client folder, cd into it"
    cd code
	zip_project "../$VERACODE_FILE_NAME"
    cd ..
#if there's no client/, it means project is in root directory
else
	zip_project "$VERACODE_FILE_NAME"
fi
