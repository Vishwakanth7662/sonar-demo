#!/bin/bash

# Spring Boot applications submitted as WAR files should be structured according to the guidance in Packaging the Application as a WAR, EAR, or JAR.
# Ensure that the WAR file contains these directories:
### /BOOT-INF/classes/ — contains all class files
### /BOOT-INF/lib/ — contains dependencies

# https://stackoverflow.com/a/8063398
middle_app() {
    m_apps=("tve-authz" "tvelrmmiddle")
    [[ ${m_apps[@]} =~ (^| )${CI_PROJECT_NAME}($| ) ]] && true
}

grab_pkg_file () {
    if [ -d "./target" ]; then
        cd target

        if middle_app; then
            export VERACODE_FILE_NAME="veracode.war"

            if ls *.war  >/dev/null; then    
                mv *.war ../../$VERACODE_FILE_NAME
            fi
        else
            ### If .jar exist
            if ls *.jar  >/dev/null; then
                export VERACODE_FILE_NAME="veracode.jar"
                mv *.jar ../$VERACODE_FILE_NAME
            fi

            ### If .war exist
            if ls *.war  >/dev/null; then
                export VERACODE_FILE_NAME="veracode.war"
                mv *.war ../$VERACODE_FILE_NAME
            fi

        fi

        cd ..
    else
        echo "Error: Cannot find target folder, Maven build failed. Exit out!"
        exit 1
    fi
}


checkStringExistInFILE () {
    # echo "1: $1"
    # echo "2: $2"
    if grep -q "$1" "$2"; then
        return 0
    else
        return 1
    fi
}

maven_install () {
    mvn clean install -U -q
}

### if I rezip and save as veracode.zip, it doens't overwrite the old zip file
if [ -f "$VERACODE_FILE_NAME" ]; then
    rm -f $VERACODE_FILE_NAME
fi

WAR_PACKAGING_TAG="<packaging>war</packaging>"
POM_PACKAGING_TAG="<packaging>pom</packaging>"
POM_FILE="pom.xml"

if [ -f "${POM_FILE}" ]; then
    echo "POM file exists"
    
    if [ -f "mvnw" ]; then
        echo "mvnw file does exist..."
        if checkStringExistInFILE "${POM_PACKAGING_TAG}" "${POM_FILE}"; then
            mvn clean install -DskipTests
        else
            if checkStringExistInFILE "$WAR_PACKAGING_TAG" "$POM_FILE"; then
                echo "$WAR_PACKAGING_TAG exist, carry on..."
                chmod +x mvnw
                ./mvnw package -f "$PWD/pom.xml"
            else
                if checkStringExistInFILE "</parent>" "$POM_FILE"; then
                    echo "Insert <packaging>war</packaging> into pom.xml, and execute mvnw command..."
                    awk '/<\/parent>/{print;print "  <packaging>war</packaging>";next}1' pom.xml > tmp.xml
                    mv tmp.xml pom.xml
                    chmod +x mvnw
                    ./mvnw package -f "$PWD/pom.xml"
                fi
            fi
        fi
    else
        echo "mvnw file does not exist..."

        if [[ ${CI_PROJECT_NAME} == "distillery" ]]; then
            mvn clean install -DskipTests
        else
            if checkStringExistInFILE "${POM_PACKAGING_TAG}" "${POM_FILE}"; then
                mvn clean install -DskipTests
            else
                if checkStringExistInFILE "${WAR_PACKAGING_TAG}" "$POM_FILE"; then
                    echo "$WAR_PACKAGING_TAG exist, carry on"
                    maven_install
                else
                    if checkStringExistInFILE "</parent>" "$POM_FILE"; then
                        echo "Insert <packaging>war</packaging> into pom.xml..."
                        awk '/<\/parent>/{print;print "  <packaging>war</packaging>";next}1' pom.xml > tmp.xml
                        mv tmp.xml pom.xml
                        maven_install
                    else
                        awk 'NR==7{print "  <packaging>war</packaging>"}1' pom.xml > tmp.xml
                        mv tmp.xml pom.xml
                        maven_install
                    fi
                fi
            fi
        fi
    fi

    if middle_app && [[ -d ./middle ]]; then
        cd ./middle
        grab_pkg_file
        cd ..
    else
        grab_pkg_file
    fi

else
    echo "Error: Cannot locate '$POM_FILE', Maven requires '$POM_FILE' to build, exit out!"
    exit 1
fi
