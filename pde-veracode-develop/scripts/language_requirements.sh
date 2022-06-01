#!/bin/bash

### Programming language portion
#### Find out what version of Java is client using
if [[ "${VERACODE_TYPE}" == *"JAVA"* ]] || [[ "${1}" == *"JAVA"* ]]; then
    echo "CLIENT_JAVA_OPENJDK_VERSION: ${VERACODE_TYPE_ARRAY[1]}"

    # Assume our client either use openjdk 8 or 11
    if [[ ${VERACODE_TYPE_ARRAY[1]} == "11" ]] || [[ "${2}" == "11" ]]; then
        ### Alpine
        # export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
        ### Ubuntu
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
        export PATH=${JAVA_HOME}/bin:${PATH}
    else
        # /usr/local/openjdk-8/jre/lib/security
        ### Alpine
        # export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
        ### Ubuntu
        export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
        export PATH=${JAVA_HOME}/bin:${PATH}
    fi

    if [[ ! -z ${BPS_CERT} ]]; then
        mkdir -p /tmp/certs
        echo ${BPS_CERT} | base64 -d > /tmp/certs/bps-certs.pem
        keytool -import -noprompt -alias sbs-cert -keystore "${JAVA_HOME}/jre/lib/security/cacerts" -file /tmp/certs/bps-certs.pem -storepass changeit
        # if [[ -d "${JAVA_HOME}/jre" ]]; then
        #     keytool -import -noprompt -alias sbs-cert -keystore "${JAVA_HOME}/jre/lib/security/cacerts" -file /tmp/certs/bps-certs.pem -storepass changeit
        # elif [[ -d "${JAVA_HOME}/lib" ]]; then
        #     keytool -import -noprompt -alias sbs-cert -keystore "${JAVA_HOME}/lib/security/cacerts" -file /tmp/certs/bps-certs.pem -storepass changeit
        # fi
    fi

    echo "Current veracode java version: "
    java -version
fi

