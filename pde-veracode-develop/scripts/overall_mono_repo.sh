#!/bin/bash


check_empty_element_in_array() {
    # ${EACH_APP_VERSION_ARRAY[0]} : Programming language              Example: NODEJS
    # ${EACH_APP_VERSION_ARRAY[1]} : Programming language version      Example: 10.22
    # ${EACH_APP_VERSION_ARRAY[2]} : Framework      					Example: EXPRESS
    # ${EACH_APP_VERSION_ARRAY[3]} : Framework version      			Example: 5.2
    # ${EACH_APP_VERSION_ARRAY[4]} : Package manager                   Example: YARN
    if [[ ${1} == 3 ]]; then
        if [ ${1[0]} == "" ] || [ ${1[1]} == "" ] || [ ${1[2]} == "" ]; then
            echo "Error: VERACODE_TYPE env variable format invalid!"
            echo "<PROGRAM_LANGUAGE>_<LANGUAGE_VERSION>_<PACKAGE_TYPE>"
            echo "Example: NODEJS_12_NPM"
            exit 1
        fi
    fi
    if [[ ${1} == 5 ]]; then
        if [ ${1[0]} == "" ] || [ ${1[1]} == "" ] || [ ${1[2]} == "" ] || [ ${1[3]} == "" ] || [ ${1[4]} == "" ]; then
            echo "Error: VERACODE_TYPE env variable format invalid!"
            echo "<LANGUAGE>_<LANGUAGE_VERSION>_<FRAMEWORK>_<FRAMEWORK_VERSION>_<PACKAGE_TYPE>"
            echo "Example: NODEJS_12_REACT_16_NPM"
            exit 1
        fi
    fi
}


# Create a directory to holder all unnessary directories later
mkdir /tmp/dir_holder

if [[ "${VERACODE_MONO_REPO_SAME_LANGUAGE}" == "true" ]]; then

    if [[ "$VERACODE_TYPE_ARRAY" == *"MAVEN"* ]]; then
        export VERACODE_FILE_NAME="veracode.war"
     elif [[ "$VERACODE_TYPE_ARRAY" == *"GRADLE"* ]]; then
        export VERACODE_FILE_NAME="veracode.war"
    elif [[ "$VERACODE_TYPE_ARRAY" == *"NODEJS"* ]]; then
        export VERACODE_FILE_NAME="veracode.zip"
    elif [[ "$VERACODE_TYPE_ARRAY" == *"PYTHON"* ]]; then
        export VERACODE_FILE_NAME="veracode.zip"
    elif [[ "$VERACODE_TYPE_ARRAY" == *"PHP"* ]]; then
        export VERACODE_FILE_NAME="veracode.zip"
    fi


    ### Check if customer app has veracode.sh or veracode.zip/veracode.jar/veracode.war.
    ### It it has, send to veracode website and exit out
    . ${VERACODE_SCRIPTS_PATH}/run_client_veracode_bash.sh


    ### If customer app doesn't have veracode.sh or veracode.zip
    check_empty_element_in_array "${VERACODE_TYPE_ARRAY}"
    echo "Cannot find ${CLIENT_VERACODE_PKG_SCRIPT_FILE_NAME} or ${VERACODE_FILE_NAME}, I will execute zip script to generate zip file based on programming language!"

    ### Install language requirements before going to loop logic
    . ${VERACODE_SCRIPTS_PATH}/language_requirements.sh "${VERACODE_TYPE_ARRAY}" "${VERACODE_TYPE_ARRAY[1]}"


    for i in ${MULTI_APPS_ARRAY[@]}
    do

        ### Go into the mono repo entry
        cd ${VERACODE_MONO_REPO_ENTRY}


        ### Temporary move unnesscary folders to /tmp/dir_holder, so I will not package it/them
        mv `\ls ./ | grep -v $i` /tmp/dir_holder


        ### Go back one level(main repo) and zip up eveyrthing and send
        cd ..

        ### Package application here
        . ${VERACODE_DETECTION_PATH}/languages/pkgs_scripts/${VERACODE_TYPE_ARRAY[4]}/zip_folder.sh "${VERACODE_FILE_NAME}"

        ### source the veracode.sh for VERACODE_FILE_NAME in parent process on child process. Need to be after main.py
        if [[ "$EACH_APP_VERSION" == *"MAVEN"* ]]; then
            . ${VERACODE_DETECTION_PATH}/languages/pkgs_scripts/MAVEN/veracode.sh
        fi

        if [[ -f "${VERACODE_FILE_NAME}" ]]; then

            ### After send to veracode, delete it for the next one
            . ${VERACODE_SCRIPTS_PATH}/send_file.sh \
                "${VERACODE_WRAPPER_VERSION}" \
                "${VERACODE_ID}" \
                "${VERACODE_KEY}" \
                "${VERACODE_APP_NAME}-$i" \
                "${CI_JOB_ID}" \
                "${CI_PIPELINE_ID}" \
                "${VERACODE_FILE_NAME}"


            if [[ ! -z ${VERACODE_TO_DL_EMAIL} ]]; then
                # Localhost
                # ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}" "DL-EnterprisePortalFTE@charter.com" ) &
                # ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}-$i" "c-chenhao.cheng@charter.com" ) &

                ### Remote
                ### Only execute if VERACODE_SCAN_GITLAB_GROUP is set here
                ### VERACODE_SCAN_GITLAB_GROUP: either true or false
                if [[ ! -z "${VERACODE_SCAN_GITLAB_GROUP}" ]]; then
                    ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}-$i" "${VERACODE_TO_DL_EMAIL}" "${VERACODE_SCAN_GITLAB_GROUP}" ) &
                else
                    ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}-$i" "${VERACODE_TO_DL_EMAIL}" "" ) &
                fi

                # Store pid from last command into array
                PIDS+="$! "
                echo ""
                echo "Parallel processing: Fork process ($!)"
                echo "--------------------------------------------------------------------------------------------------"
            fi

            ### remove the veracode file first in case it has duplicate file
            rm -f ${VERACODE_FILE_NAME}

        else
            echo "Error: Cannot generate $VERACODE_FILE_NAME file, exit out!"
            exit 1
        fi

        mv /tmp/dir_holder/* ${VERACODE_MONO_REPO_ENTRY}
    done

fi

# Wait for all PID die
for PID in ${PIDS}; do
	wait $PID
	if [[ $? -eq 0 ]]; then
		echo "SUCCESS - Job $PID exited with a status of $?"
	else
		echo "FAILED - Job $PID exited with a status of $?"
	fi
done    