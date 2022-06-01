#!/bin/bash

# Spring Boot applications submitted as WAR files should be structured according to the guidance in Packaging the Application as a WAR, EAR, or JAR.
# Ensure that the WAR file contains these directories:
### /BOOT-INF/classes/ — contains all class files
### /BOOT-INF/lib/ — contains dependencies

### if I rezip and save as veracode.zip, it doens't overwrite the old zip file
if [[ "$VERACODE_FILE_NAME" ]]; then
    rm -f $VERACODE_FILE_NAME
fi

GRADLE_FILE="build.gradle"

if [[ -f "$GRADLE_FILE" ]]; then
    echo "GRADLE file exists"
    
    if [[ -f "gradlew" ]]; then
        echo "gradlew file does exist, run it..."
        chmod +x ./gradlew
        ./gradlew bootJar
    fi

    if [[ -d "build/libs" ]]; then
        cd build/libs

        ### If .jar exist
        if ls ./*.jar &> /dev/null; then
            export VERACODE_FILE_NAME="veracode.jar"
            mv ./*.jar ../../$VERACODE_FILE_NAME
        fi

        ### If .war exist
        if ls ./*.war &> /dev/null; then
            export VERACODE_FILE_NAME="veracode.war"
            mv ./*.war ../../$VERACODE_FILE_NAME
        fi

        cd ../../
    else
        echo "Error: Cannot find lib folder"
        exit 1
    fi
else
    echo "Error: Cannot locate build.gradle"
    exit 1
fi