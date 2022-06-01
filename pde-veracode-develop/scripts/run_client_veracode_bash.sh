#!/bin/bash

run_client_veracode_bash () {
	echo "Run Bash repo script..."
	echo "Path: $1"
	chmod +x $1
	$1
}

# Distinguish client application information and save into array
## example: NODEJS_10.22_REACT_16_NPM
# ${VERACODE_TYPE_ARRAY[0]} : Programming language              Example: NODEJS
# ${VERACODE_TYPE_ARRAY[1]} : Programming language version      Example: 10.22
# ${VERACODE_TYPE_ARRAY[2]} : Framework      					Example: EXPRESS
# ${VERACODE_TYPE_ARRAY[3]} : Framework version      			Example: 5.2
# ${VERACODE_TYPE_ARRAY[4]} : Package manager                   Example: YARN
if [[ "${VERACODE_TYPE}" != "" ]]; then
	export VERACODE_TYPE_ARRAY=(`echo ${VERACODE_TYPE} | tr '_' ' '`)
fi

### Install what each language needs
bash ${VERACODE_SCRIPTS_PATH}/language_requirements.sh "${VERACODE_TYPE_ARRAY}" "${VERACODE_TYPE_ARRAY[1]}"

if [[ -f "${CLIENT_VERACODE_PKG_SCRIPT_FILE_NAME}" ]]; then
	echo "Found $CLIENT_VERACODE_PKG_SCRIPT_FILE_NAME in client's repo. Run it and exit out"
	run_client_veracode_bash "./$CLIENT_VERACODE_PKG_SCRIPT_FILE_NAME"

elif [[ -f "${VERACODE_FILE_NAME}" ]]; then
	echo "Found $VERACODE_FILE_NAME, send to veracode directly!"
	. ${VERACODE_SCRIPTS_PATH}/send_file.sh \
		${VERACODE_WRAPPER_VERSION} \
		${VERACODE_ID} \
		${VERACODE_KEY} \
		${VERACODE_APP_NAME} \
		${CI_JOB_ID} \
		${CI_PIPELINE_ID} \
		${VERACODE_FILE_NAME}

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

	# Wait for all PIDs die if there's any
	for PID in ${PIDS}; do
		wait $PID
		if [[ $? -eq 0 ]]; then
			echo "SUCCESS - Job $PID exited with a status of $?"
		else
			echo "FAILED - Job $PID exited with a status of $?"
		fi
	done

	### Exit here if the customer has veracode script to run and send
	exit 1
fi



