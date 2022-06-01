#!/bin/bash

run_client_veracode_bash () {
	echo "Found client veracode.sh"
	echo "Path: $1"
	chmod +x $1
	$1
}

check_empty_element_in_array() {
    # ${EACH_APP_VERSION_ARRAY[0]} : Programming language              Example: NODEJS
    # ${EACH_APP_VERSION_ARRAY[1]} : Programming language version      Example: 10.22
    # ${EACH_APP_VERSION_ARRAY[2]} : Framework      					Example: EXPRESS
    # ${EACH_APP_VERSION_ARRAY[3]} : Framework version      			Example: 5.2
    # ${EACH_APP_VERSION_ARRAY[4]} : Package manager                   Example: YARN
    if [[ ${1} == 3 ]]; then
        if [ ${EACH_APP_VERSION_ARRAY[0]} == "" ] || [ ${EACH_APP_VERSION_ARRAY[1]} == "" ] || [ ${EACH_APP_VERSION_ARRAY[2]} == "" ]; then
            echo "Error: VERACODE_TYPE env variable format invalid!"
            echo "<PROGRAM_LANGUAGE>_<LANGUAGE_VERSION>_<PACKAGE_TYPE>"
            echo "Example: NODEJS_12_NPM"
            exit 1
        fi
    fi
    if [[ ${1} == 5 ]]; then
        if [ ${EACH_APP_VERSION_ARRAY[0]} == "" ] || [ ${EACH_APP_VERSION_ARRAY[1]} == "" ] || [ ${EACH_APP_VERSION_ARRAY[2]} == "" ] || [ ${EACH_APP_VERSION_ARRAY[3]} == "" ] || [ ${EACH_APP_VERSION_ARRAY[4]} == "" ]; then
            echo "Error: VERACODE_TYPE env variable format invalid!"
            echo "<LANGUAGE>_<LANGUAGE_VERSION>_<FRAMEWORK>_<FRAMEWORK_VERSION>_<PACKAGE_TYPE>"
            echo "Example: NODEJS_12_REACT_16_NPM"
            exit 1
        fi
    fi
}

INDEX=0
for i in ${MULTI_APPS_ARRAY[@]}
do
    ### Go to each app directory
    cd ${i}
    echo "Found ${i} directory, enter in..."

    if [[ "${VARACODE_CAPTIALIZED_FIRST_LETTER}" == "true" ]]; then
        APP_NAME="${i^}"
    else
        APP_NAME="${i}"
    fi
    echo "After captialize the 1st letter; APP_NAME: ${APP_NAME}"


    export EACH_APP_VERSION=${VERACODE_TYPE_ARRAY[$INDEX]}
    ### This portion will look each app's version
    echo ""
    echo "Current project: ${VERACODE_TYPE_ARRAY[$INDEX]}"
    echo ""
    export EACH_APP_VERSION_ARRAY=(`echo ${EACH_APP_VERSION} | tr '_' ' '`)
    echo ""
    echo "EACH_APP_VERSION_ARRAY: ${EACH_APP_VERSION_ARRAY[@]}"
    echo ""


    if [[ "$EACH_APP_VERSION" == *"MAVEN"* ]]; then
        export VERACODE_FILE_NAME="veracode.war"
    elif [[ "$EACH_APP_VERSION" == *"NODEJS"* ]]; then
        export VERACODE_FILE_NAME="veracode.zip"
    elif [[ "$EACH_APP_VERSION" == *"PYTHON"* ]]; then
        export VERACODE_FILE_NAME="veracode.zip"
    elif [[ "$EACH_APP_VERSION" == *"PHP"* ]]; then
        export VERACODE_FILE_NAME="veracode.zip"
    fi

    ### Check if customer app has veracode.sh or veracode.zip/veracode.jar/veracode.war.
    ### It it has, send to veracode website and exit out
    . ${VERACODE_SCRIPTS_PATH}/run_client_veracode_bash.sh


    ### If customer app doesn't have veracode.sh or veracode.zip
    check_empty_element_in_array "${#EACH_APP_VERSION_ARRAY[@]}"
    echo "Cannot find ${CLIENT_VERACODE_PKG_SCRIPT_FILE_NAME} or ${VERACODE_FILE_NAME}, I will execute zip script to generate zip file based on programming language!"


    ### Install what each language needs
    . ${VERACODE_SCRIPTS_PATH}/language_requirements.sh "${EACH_APP_VERSION}" "${EACH_APP_VERSION_ARRAY[1]}"

    ### Check the version for each programming lanaugage. Package and send to veracode if pass
    python3 -u ${VERACODE_DETECTION_PATH}/main.py

    ### source the veracode.sh for VERACODE_FILE_NAME in parent process on child process. Need to be after main.py
    if [[ "$EACH_APP_VERSION" == *"MAVEN"* ]]; then
        . ${VERACODE_DETECTION_PATH}/languages/pkgs_scripts/MAVEN/veracode.sh
    fi

    if [[ -f "$VERACODE_FILE_NAME" ]]; then
        echo ""
        echo "Python generated $VERACODE_FILE_NAME, get ready to send to Veracode"
        echo ""

        echo "index here: ${VERACODE_SANDBOXNAMES_ARRAY[$INDEX]}"

        if [ -n ${VERACODE_SANDBOXNAMES} ]; then
            . ${VERACODE_SCRIPTS_PATH}/send_file.sh \
                "${VERACODE_WRAPPER_VERSION}" \
                "${VERACODE_ID}" \
                "${VERACODE_KEY}" \
                "${VERACODE_APP_NAME}-${APP_NAME}" \
                "${CI_JOB_ID}" \
                "${CI_PIPELINE_ID}" \
                "${VERACODE_FILE_NAME}" \
                "${VERACODE_SANDBOXNAMES_ARRAY[$INDEX]}"
        else
            . ${VERACODE_SCRIPTS_PATH}/send_file.sh \
                "${VERACODE_WRAPPER_VERSION}" \
                "${VERACODE_ID}" \
                "${VERACODE_KEY}" \
                "${VERACODE_APP_NAME}-${APP_NAME}" \
                "${CI_JOB_ID}" \
                "${CI_PIPELINE_ID}" \
                "${VERACODE_FILE_NAME}" 
        fi


        if [[ -n "${VERACODE_TO_DL_EMAIL}" ]]; then
            ### Only execute if VERACODE_SCAN_GITLAB_GROUP is set here
            ### VERACODE_SCAN_GITLAB_GROUP: either true or false
            if [[ ! -z "${VERACODE_SCAN_GITLAB_GROUP}" ]]; then
                ( python3 -u /veracode/python/veracode_api.py "$VERACODE_APP_NAME-$APP_NAME" "${VERACODE_TO_DL_EMAIL}" "${VERACODE_SCAN_GITLAB_GROUP}" ) &
            else
                ( python3 -u /veracode/python/veracode_api.py "$VERACODE_APP_NAME-$APP_NAME" "${VERACODE_TO_DL_EMAIL}" "" ) &
            fi

            # Store pid from last command into array
            PIDS+="$! "
            echo ""
            echo "Parallel processing: Fork process ($!)"
            echo "--------------------------------------------------------------------------------------------------"
        fi
    else
        echo "Error: Cannot generate $VERACODE_FILE_NAME file, exit out!"
        exit 1
    fi
    # if [[ -f "$VERACODE_FILE_NAME" ]]; then
    #     echo ""
    #     echo "Python generated $VERACODE_FILE_NAME, get ready to send to Veracode"
    #     echo ""

    #     . ${VERACODE_SCRIPTS_PATH}/send_file.sh \
    #         "${VERACODE_WRAPPER_VERSION}" \
    #         "${VERACODE_ID}" \
    #         "${VERACODE_KEY}" \
    #         "${VERACODE_APP_NAME}-${APP_NAME}" \
    #         "${CI_JOB_ID}" \
    #         "${CI_PIPELINE_ID}" \
    #         "${VERACODE_FILE_NAME}"

    #     if [[ -n "${VERACODE_TO_DL_EMAIL}" ]]; then
    #         ### Only execute if VERACODE_SCAN_GITLAB_GROUP is set here
    #         ### VERACODE_SCAN_GITLAB_GROUP: either true or false
    #         if [[ ! -z "${VERACODE_SCAN_GITLAB_GROUP}" ]]; then
    #             ( python3 -u /veracode/python/veracode_api.py "$VERACODE_APP_NAME-$APP_NAME" "${VERACODE_TO_DL_EMAIL}" "${VERACODE_SCAN_GITLAB_GROUP}" ) &
    #         else
    #             ( python3 -u /veracode/python/veracode_api.py "$VERACODE_APP_NAME-$APP_NAME" "${VERACODE_TO_DL_EMAIL}" "" ) &
    #         fi

    #         # Store pid from last command into array
    #         PIDS+="$! "
    #         echo ""
    #         echo "Parallel processing: Fork process ($!)"
    #         echo "--------------------------------------------------------------------------------------------------"
    #     fi
    # else
    #     echo "Error: Cannot generate $VERACODE_FILE_NAME file, exit out!"
    #     exit 1
    # fi

    ### Increment index
    ((INDEX++))

    ### Go back to parent directory of each app
    cd ..

done


# INDEX=0
# if [[ "${VARACODE_CAPTIALIZED_FIRST_LETTER}" == "true" ]]; then
#     for i in ${MULTI_APPS_ARRAY[@]}
#     do
#         ### Go to each app directory
#         cd ${i}
#         echo "Found ${i} directory, enter in..."

#         APP_NAME="${i^}"
#         echo "After captialize the 1st letter; APP_NAME: ${APP_NAME}"


#         export EACH_APP_VERSION=${VERACODE_TYPE_ARRAY[$INDEX]}
#         ### This portion will look each app's version
#         echo ""
#         echo "Current project: ${VERACODE_TYPE_ARRAY[$INDEX]}"
#         echo ""
#         export EACH_APP_VERSION_ARRAY=(`echo ${EACH_APP_VERSION} | tr '_' ' '`)
#         echo ""
#         echo "EACH_APP_VERSION_ARRAY: ${EACH_APP_VERSION_ARRAY[@]}"
#         echo ""


#         if [[ "$EACH_APP_VERSION" == *"MAVEN"* ]]; then
#             export VERACODE_FILE_NAME="veracode.war"
#         elif [[ "$EACH_APP_VERSION" == *"NODEJS"* ]]; then
#             export VERACODE_FILE_NAME="veracode.zip"
#         elif [[ "$EACH_APP_VERSION" == *"PYTHON"* ]]; then
#             export VERACODE_FILE_NAME="veracode.zip"
#         elif [[ "$EACH_APP_VERSION" == *"PHP"* ]]; then
#             export VERACODE_FILE_NAME="veracode.zip"
#         fi

#         ### Check if customer app has veracode.sh or veracode.zip/veracode.jar/veracode.war.
#         ### It it has, send to veracode website and exit out
#         . ${VERACODE_SCRIPTS_PATH}/run_client_veracode_bash.sh


#         ### If customer app doesn't have veracode.sh or veracode.zip
#         check_empty_element_in_array "${#EACH_APP_VERSION_ARRAY[@]}"
#         echo "Cannot find ${CLIENT_VERACODE_PKG_SCRIPT_FILE_NAME} or ${VERACODE_FILE_NAME}, I will execute zip script to generate zip file based on programming language!"


#         ### Install what each language needs
#         . ${VERACODE_SCRIPTS_PATH}/language_requirements.sh "${EACH_APP_VERSION}" "${EACH_APP_VERSION_ARRAY[1]}"

#         ### Check the version for each programming lanaugage. Package and send to veracode if pass
#         python3 -u ${VERACODE_DETECTION_PATH}/main.py

#         ### source the veracode.sh for VERACODE_FILE_NAME in parent process on child process. Need to be after main.py
#         if [[ "$EACH_APP_VERSION" == *"MAVEN"* ]]; then
#             . ${VERACODE_DETECTION_PATH}/languages/pkgs_scripts/MAVEN/veracode.sh
#         fi

#         if [[ -f "$VERACODE_FILE_NAME" ]]; then
#             echo ""
#             echo "Python generated $VERACODE_FILE_NAME, get ready to send to Veracode"
#             echo ""

#             . ${VERACODE_SCRIPTS_PATH}/send_file.sh \
#                 "${VERACODE_WRAPPER_VERSION}" \
#                 "${VERACODE_ID}" \
#                 "${VERACODE_KEY}" \
#                 "${VERACODE_APP_NAME}-${APP_NAME}" \
#                 "${CI_JOB_ID}" \
#                 "${CI_PIPELINE_ID}" \
#                 "${VERACODE_FILE_NAME}"

#             if [[ ! -z "${VERACODE_TO_DL_EMAIL}" ]]; then
#                 ### Only execute if VERACODE_SCAN_GITLAB_GROUP is set here
#                 ### VERACODE_SCAN_GITLAB_GROUP: either true or false
#                 if [[ ! -z "${VERACODE_SCAN_GITLAB_GROUP}" ]]; then
#                     ( python3 -u /veracode/python/veracode_api.py "$VERACODE_APP_NAME-$APP_NAME" "${VERACODE_TO_DL_EMAIL}" "${VERACODE_SCAN_GITLAB_GROUP}" ) &
#                 else
#                     ( python3 -u /veracode/python/veracode_api.py "$VERACODE_APP_NAME-$APP_NAME" "${VERACODE_TO_DL_EMAIL}" "" ) &
#                 fi

#                 # Store pid from last command into array
#                 PIDS+="$! "
#                 echo ""
#                 echo "Parallel processing: Fork process ($!)"
#                 echo "--------------------------------------------------------------------------------------------------"
#             fi
#         else
#             echo "Error: Cannot generate $VERACODE_FILE_NAME file, exit out!"
#             exit 1
#         fi

#         ### Increment index
#         ((INDEX++))

#         ### Go back to parent directory of each app
#         cd ..

#     done
# else
#     echo "Veracode script does not know what to do because CAPTIALIZED_FIRST_LETTER is not set yet. Please contact c-chenhao.cheng@charter.com"
#     exit 1
# fi


# Wait for all PID die
for PID in ${PIDS}; do
	wait $PID
	if [[ $? -eq 0 ]]; then
		echo "SUCCESS - Job $PID exited with a status of $?"
	else
		echo "FAILED - Job $PID exited with a status of $?"
	fi
done    
