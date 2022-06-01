#!/bin/bash

echo ""
echo "------------Running single app without framework-------------"
echo ""

### Check if customer has their own veracode script, if there is, run it and send to veracode and then exit out, otherwise, check version
. ${VERACODE_SCRIPTS_PATH}/run_client_veracode_bash.sh

if [[ -f "$VERACODE_FILE_NAME" ]]; then
    echo ""
    echo "Run customer's veracode.sh, and found $VERACODE_FILE_NAME, get ready to send to Veracode"
    echo ""

    . ${VERACODE_SCRIPTS_PATH}/send_file.sh \
        "${VERACODE_WRAPPER_VERSION}" \
        "${VERACODE_ID}" \
        "${VERACODE_KEY}" \
        "${VERACODE_APP_NAME}" \
        "${CI_JOB_ID}" \
        "${CI_PIPELINE_ID}" \
        "${VERACODE_FILE_NAME}"

    ### Only execute if customer's DL has set
    if [[ ! -z "${VERACODE_TO_DL_EMAIL}" ]]; then

        ### Only execute if VERACODE_SCAN_GITLAB_GROUP is set here
        ### VERACODE_SCAN_GITLAB_GROUP: either true or false
        if [[ ! -z "${VERACODE_SCAN_GITLAB_GROUP}" ]]; then
            ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}" "${VERACODE_TO_DL_EMAIL}" "${VERACODE_SCAN_GITLAB_GROUP}" ) &
        else
            ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}" "${VERACODE_TO_DL_EMAIL}" "" ) &
        fi
    
        # Store pid from last command into array
        PIDS+="$! "
        echo ""
        echo "Parallel processing: Fork process ($!)"
        echo ""
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

else

    echo "Cannot find ${CLIENT_VERACODE_PKG_SCRIPT_FILE_NAME} or ${VERACODE_FILE_NAME}, Execute Python to generate zip file based on programming language!"
    echo "............Python script started............"

    if [[ ${#VERACODE_TYPE_ARRAY[@]} == 3 ]]; then
        # ${VERACODE_TYPE_ARRAY[0]} : Programming language              Example: NODEJS
        # ${VERACODE_TYPE_ARRAY[1]} : Programming language version      Example: 10.22
        # ${VERACODE_TYPE_ARRAY[2]} : Package manager                   Example: YARN
        if [ ${VERACODE_TYPE_ARRAY[0]} == "" ] || [ ${VERACODE_TYPE_ARRAY[1]} == "" ] || [ ${VERACODE_TYPE_ARRAY[2]} == "" ]; then
            echo "Error: VERACODE_TYPE env variable format invalid!"
            echo "<PROGRAM_LANGUAGE>_<LANGUAGE_VERSION>_<PACKAGE_TYPE>"
            echo "Example: NODEJS_12_NPM"
            exit 1
        fi

    fi
    if [[ ${#VERACODE_TYPE_ARRAY[@]} == 5 ]]; then
        # ${VERACODE_TYPE_ARRAY[0]} : Programming language              Example: NODEJS
        # ${VERACODE_TYPE_ARRAY[1]} : Programming language version      Example: 10.22
        # ${VERACODE_TYPE_ARRAY[2]} : Framework      					Example: EXPRESS
        # ${VERACODE_TYPE_ARRAY[3]} : Framework version      			Example: 5.2
        # ${VERACODE_TYPE_ARRAY[4]} : Package manager                   Example: YARN
        if [ ${VERACODE_TYPE_ARRAY[0]} == "" ] || [ ${VERACODE_TYPE_ARRAY[1]} == "" ] || [ ${VERACODE_TYPE_ARRAY[2]} == "" ] || [ ${VERACODE_TYPE_ARRAY[3]} == "" ] || [ ${VERACODE_TYPE_ARRAY[4]} == "" ]; then
            echo "Error: VERACODE_TYPE env variable format invalid!"
            echo "<LANGUAGE>_<LANGUAGE_VERSION>_<FRAMEWORK>_<FRAMEWORK_VERSION>_<PACKAGE_TYPE>"
            echo "Example: NODEJS_12_REACT_16_NPM"
            exit 1
        fi
    fi

    ### Install what each language needs
    . ${VERACODE_SCRIPTS_PATH}/language_requirements.sh "${VERACODE_TYPE_ARRAY}" "${VERACODE_TYPE_ARRAY[1]}"

    ### Execute Version checking and build the project
    python3 -u ${VERACODE_DETECTION_PATH}/main.py

    ### source the veracode.sh for VERACODE_FILE_NAME in parent process on child process. Need to be after main.py
    if [[ "$EACH_APP_VERSION" == *"MAVEN"* ]]; then
        . ${VERACODE_DETECTION_PATH}/languages/pkgs_scripts/MAVEN/veracode.sh
    fi

    if [[ -f "$VERACODE_FILE_NAME" ]]; then
        echo ""
        echo "Python generated $VERACODE_FILE_NAME, get ready to send to Veracode"
        echo ""
    else
        echo "Error: Cannot generate $VERACODE_FILE_NAME file, exit out!"
        exit 1
    fi

    . ${VERACODE_SCRIPTS_PATH}/send_file.sh \
        "${VERACODE_WRAPPER_VERSION}" \
        "${VERACODE_ID}" \
        "${VERACODE_KEY}" \
        "${VERACODE_APP_NAME}" \
        "${CI_JOB_ID}" \
        "${CI_PIPELINE_ID}" \
        "${VERACODE_FILE_NAME}"

    ### Only execute if customer's DL has set
    if [[ ! -z "${VERACODE_TO_DL_EMAIL}" ]]; then

        ### Only execute if VERACODE_SCAN_GITLAB_GROUP is set here
        ### VERACODE_SCAN_GITLAB_GROUP: either true or false
        if [[ ! -z "${VERACODE_SCAN_GITLAB_GROUP}" ]]; then
            ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}" "${VERACODE_TO_DL_EMAIL}" "${VERACODE_SCAN_GITLAB_GROUP}" ) &
        else
            ( python3 -u /veracode/python/veracode_api.py "${VERACODE_APP_NAME}" "${VERACODE_TO_DL_EMAIL}" "" ) &
        fi
    
        # Store pid from last command into array
        PIDS+="$! "
        echo ""
        echo "Parallel processing: Fork process ($!)"
        echo ""
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

fi