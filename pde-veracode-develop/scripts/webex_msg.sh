#!/bin/bash

if [[ ! -z ${VERACODE_WEBEX_ROOM_NAME} ]]; then

    WEBEX_ROOM_ID=`curl https://webexapis.com/v1/rooms -H "Authorization: Bearer $VERACODE_BOT_TOKEN" \
        | jq ".items[] | select(.title == \"${VERACODE_WEBEX_ROOM_NAME}\") | .id" | tr -d '"'`

    if [[ -f ${CODE_FILE_LOCATION} ]]; then
        echo "Found ${CODE_FILE_LOCATION} file"
        echo ""

        curl -s -o /dev/null -X POST https://webexapis.com/v1/messages \
            -H "Authorization: Bearer ${VERACODE_BOT_TOKEN}" \
            --data-urlencode "roomId=${WEBEX_ROOM_ID}" \
            --data-urlencode "markdown=$(cat ${CODE_FILE_LOCATION})"
            
        echo "Veracode bot sent a message to ${VERACODE_WEBEX_ROOM_NAME} with code scan result!!"
    fi

    if [[ -f ${SCA_FILE_LOCATION} ]]; then
        echo "Found ${SCA_FILE_LOCATION} file"
        echo ""

        curl -s -o /dev/null -X POST https://webexapis.com/v1/messages \
            -H "Authorization: Bearer ${VERACODE_BOT_TOKEN}" \
            --form "roomId=${WEBEX_ROOM_ID}" \
            --form "text=Application: ${1}; Software Composition Analysis" \
            --form "files=@"${SCA_FILE_LOCATION}""
            
        echo "Veracode bot sent a message to ${VERACODE_WEBEX_ROOM_NAME} with SCA json file!!"
    fi

    if [[ -f ${DETAILED_PDF_FILE_LOCATION} ]]; then
        echo "Found ${DETAILED_PDF_FILE_LOCATION} file"
        echo ""

        curl -s -o /dev/null -X POST https://webexapis.com/v1/messages \
            -H "Authorization: Bearer ${VERACODE_BOT_TOKEN}" \
            --form "roomId=${WEBEX_ROOM_ID}" \
            --form "text=Application: ${1}; Detailed Report PDF" \
            --form "files=@"${DETAILED_PDF_FILE_LOCATION}""
            
        echo "Veracode bot sent a message to ${VERACODE_WEBEX_ROOM_NAME} with detailed pdf file!!"
    fi
else
    echo "Variable: VERACODE_WEBEX_ROOM_NAME not setup, skip..."
fi