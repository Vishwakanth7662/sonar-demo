#!/bin/bash


# 1: VERACODE_WRAPPER_VERSION
# 2: VERACODE_ID
# 3: VERACODE_KEY
# 4: VERACODE_APP_NAME
# 5: CI_JOB_ID
# 6: CI_PIPELINE_ID
# 7: VERACODE_FILE_NAME

#### Download veracode engine
echo "Downloading veracode package (version: ${1})..."
if [ -z "${1}" ]; then
	echo "Veracode package version is not set... Exit out"
	exit 1
fi
wget -q https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/${1}/vosp-api-wrappers-java-${1}.jar

# echo "1: ${1}"
# echo "2: ${2}"
# echo "3: ${3}"
# echo "4: ${4}"
# echo "5: ${5}"
# echo "6: ${6}"
# echo "7: ${7}"

echo "Sending file to Veracode..."

if [ -n ${APP_VERSION} ]; then
	app_version=${APP_VERSION}
else
	app_version="job ${5} in pipeline ${6}"
fi

#### Send to veracode
### if version is 21.9.8.2, -deleteincompletescan option is fine
### if version is 20.8.7.1, -deleteincompletescan throw an error because there's no such option
if [ -n ${8} ]; then
	echo "---------------------------------------------------------------"
	echo "Detect Sandbox name: ${8}, send to sandbox..."
	echo "---------------------------------------------------------------"
	java -jar vosp-api-wrappers-java-${1}.jar \
		-action uploadandscan \
		-vid ${2} \
		-vkey ${3} \
		-appname "${4}" \
		-createprofile true \
		-criticality High \
		-sandboxname ${8} \
		-version "${app_version}" \
		-filepath ${7} \
		-autoscan true \
		-deleteincompletescan true

else
	java -jar vosp-api-wrappers-java-${1}.jar \
		-action uploadandscan \
		-vid ${2} \
		-vkey ${3} \
		-appname "${4}" \
		-createprofile true \
		-criticality High \
		-version "${app_version}" \
		-filepath ${7} \
		-autoscan true \
		-deleteincompletescan true
fi

echo "sending file return: $?"
STATUS=$?
echo "STATUS: $STATUS"

if [ $STATUS == 0 ]; then
	echo "Successful sent the file to Veracode website..."
else
	echo "Failed sending the file to Veracode website... exit out!!"
	echo "The previous scan of application: ${4} is very likely still in progress (Not finished), so the new scan can not be added!"
	exit 1
fi
