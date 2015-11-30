# linux-service-maker

## Synopsis

Linux service maker is a script shell that allows to simply create a linux daemon on an **ubuntu** or debian distribution.

The script has been written to be used easyly with **jenkins**.

## What does it do

1. It first copies the executable (a jar file for the moment) into an installation directory (customizable)
2. Then a launcher is created according to a template (for a jar file a java command is used)
3. Finally, a linux service wrapper is created (there is two possible ways of doing that: using a symbolic link for spring boot 1.3.0 java applications, or creating a classic daemon launcher)

## Motivation
There is a lot of people using jenkins (or other tools) in order to perform continuous integrations.

For a personnal project, I needed to create a script that allows me to easyly launch my application directly from jenkins.

I decided to create a generic script and then to create the git repository in case it can help somebody else.

## Installation

In order to use the script, it is adviced to create a script that will call the linux service maker.

Here is an example : 

```shell
#!/bin/bash

APP_NAME="WTFrontend" # less than 15 characters
DELETE_INSTALL_DIR=true
BASE_DIR=/etc
INSTALL_DIR=$BASE_DIR/$APP_NAME
JAR_FILE=$3/target/$1-$2.war # $3 is the jenkins workspace, $1 is the artifact-id, $2 is the pom version
JAR_NAME=WTFrontend.war #less than 15 characters without the .jar
CREATE_SP_BOOT_SERVICE=0
CREATE_OLD_FASHION_SERVICE=1
PROP_FILE_PARAM="prod"
JAVA_OPTS="-Dserver.port=8080"
ADDITIONNAL_PARAMS=

./mep.sh "$APP_NAME" $DELETE_INSTALL_DIR $BASE_DIR $INSTALL_DIR $JAR_FILE $JAR_NAME $CREATE_SP_BOOT_SERVICE $CREATE_OLD_FASHION_SERVICE $PROP_FILE_PARAM $JAVA_OPTS $ADDITIONNAL_PARAMS

```


## Contributors
TODO

## License
TODO
