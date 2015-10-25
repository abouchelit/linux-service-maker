#!/bin/bash

HOME="${APP_HOME}"
JAR_NAME="${JAR_NAME}"
PROP_FILE_PARAM="${PROP_FILE_PARAM}"
JAVA_OPTS="${JAVA_OPTS}"

java $JAVA_OPTS  -jar $HOME/$JAR_NAME --spring.profiles.active=$PROP_FILE_PARAM 2>1 1>/var/log/${JAR_NAME}.log
