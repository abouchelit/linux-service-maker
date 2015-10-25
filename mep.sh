#!/bin/bash 

####
# loading parameters: shift  is used to avoid a $10 attempt (max allowed is $9)
###
# TODO: create a function to load parameters according to the following schema: --param_name value
#
# Application name: used in several log messages and in particular in the daemon creation
APP_NAME=$1
shift

# Indicates if it is needed to remove a previous installation for the application
DELETE_INSTALL_DIR=$1
shift

# Base directory for the application installation (often /etc)
BASE_DIR=$1
shift

# Installation directory: composed like that : $BASE_DIR/$APP_NAME (/!\ this parameter will be removed soon)
INSTALL_DIR=$1
shift

# Path to the jar file to copy
JAR_FILE=$1
shift

# Name of the copied jar file
JAR_NAME=$1
shift

# Indicates if it is necessary to create a spring boot linux service (available since spring boot 1.3.0)
CREATE_SP_BOOT_SERVICE=$1
shift

# Indicates if it is necessary to create a linux service the old fashion way (ie: create a start shell script to launch the jar file and create a service wrapper in /etc/init.d)
CREATE_OLD_FASHION_SERVICE=$1
shift

# The application.properties profile to load
# TODO: change the variable name to PROFILE_PARAM
PROP_FILE_PARAM=$1
shift

# Additionnal java options (such as -Xmx or -Dxxx)
JAVA_OPTS=$1


# Control of the program arguments
if [ -z $APP_NAME ] ||  [ -z $DELETE_INSTALL_DIR ] ||  [ -z $BASE_DIR ] ||  [ -z $INSTALL_DIR ] ||  [ -z $JAR_FILE ] ||  [ -z $JAR_NAME ]; then
	echo "usage: mep.sh <app_name> <delete_install_dir (true or false) <base_dir> <install_dir> <jar_file> <jar_name> [<CREATE_SP_BOOT_SERVICE (1 or 0)> <CREATE_OLD_FASHION_SERVICE (1 or 0)>]"
	exit 1
else
	echo "executing script with following parameters : "
	echo "APP_NAME = $APP_NAME"
	echo "DELETE_INSTALL_DIR = $DELETE_INSTALL_DIR"
	echo "BASE_DIR = $BASE_DIR"
	echo "INSTALL_DIR = $INSTALL_DIR"
	echo "JAR_FILE = $JAR_FILE"
	echo "JAR_NAME = $JAR_NAME"
	echo "CREATE_SP_BOOT_SERVICE = $CREATE_SP_BOOT_SERVICE"
	echo "CREATE_OLD_FASHION_SERVICE = $CREATE_OLD_FASHION_SERVICE"
	echo "PROP_FILE_PARAM = $PROP_FILE_PARAM"
	echo "JAVA_OPTS=$JAVA_OPTS"
fi

# TODO: create a log  function or use one already existing
echo "mep $APP_NAME"

#  This function allows to create the installation directory for the service currently installed
function createInstallDir() {
	
	sudo mkdir $INSTALL_DIR

        if [ -d $INSTALL_DIR ]; then
        	echo "$INSTALL_DIR successfully created"
        else
                echo "an error occurred when tried to create $INSTALL_DIR"
                return 1
        fi
	
	return 0
}


# TODO: remove this function and use mkdir -p instead (shame on me)
function checkAndCreateAppDir() {
	echo "checking existence of directory: $INSTALL_DIR"

	if [ ! -d $INSTALL_DIR ]; then
	
		echo "$INSTALL_DIR does not exist --> trying to create it"
		
		if [ ! -d $BASE_DIR ]; then

			echo "$BASE_DIR does not exist --> trying to create it"
			local RES=$(mkdir $BASE_DIR)
			
			if [ $? -eq 0 ]; then
				echo "$BASE_DIR successfully created"

				createInstallDir

				if [ $? -ne 0 ]; then 
					return 1 
				fi

			else
				echo "an error occurred when tried to create $BASE_DIR"
				echo "RES = $RES"
                                return 1
			fi
		else
			echo "$BASE_DIR already exists"
			
			createInstallDir

                        if [ $? -ne 0 ]; 
				then return 1 
			fi
		fi
	else 
		echo "$INSTALL_DIR already exists"
	fi

	return 0	
}

# This function allows to copy the jar within the $JAR_FILE variable (value is provided as parameter to the program)
# into the installation directory with a new name ($JAR_NAME also provided as parameter to the program) 
function copyJarFile() {

	sudo cp $JAR_FILE $INSTALL_DIR/$JAR_NAME

	if [ -e $INSTALL_DIR/$JAR_NAME ]; then
		echo "jar file successfully copied"
		return 0
	else 
		echo "an error occurred when tried to copy the jar file $INSTALL_DIR/$JAR_NAME"
		return 1
	fi
}


# This function allow to create a linux the old fashion way : 
# 1 - create a program launcher according to a template (echo | sed is used)
# 2 - create a service launcher directly into /etc/init.d directory (root authorizations are needed)
#
# All created scripts are using templates
# 1 - spring_boot_start.sh.tpl : allows to create a script to launch a spring boot application
# 2 - launcher.sh.tpl : it's a linux service wrapper template
#
function createOldFashionService() {
	
	echo "creating start.sh script"
	startFile=${JAR_NAME%.*}
	sudo touch $INSTALL_DIR/$startFile
	sudo chmod o+w $INSTALL_DIR/$startFile
	sudo cat spring_boot_start.sh.tpl | sed -e "s;\${JAVA_OPTS};${JAVA_OPTS};"  -e "s;\${APP_HOME};${INSTALL_DIR};" -e "s;\${JAR_NAME};$JAR_NAME;" -e "s;\${PROP_FILE_PARAM};$PROP_FILE_PARAM;"  >   $INSTALL_DIR/$startFile
	sudo chmod 700 $INSTALL_DIR/$startFile

	echo "creating init.d launcher"
	file=/etc/init.d/${JAR_NAME%.*}

	if [ -e $file ]; then
		echo "removing file $file"
		sudo rm $file
	fi

	sudo touch $file
	sudo chmod 777 $file

	CMD_STRT=$INSTALL_DIR/$startFile
	#CMD_STRT="$startFile"
	PID_DIR=/tmp$INSTALL_DIR

	echo "file = $file"
	
	sudo cat launcher.sh.tpl | sed -e "s;\${SERVICE_DESC};$APP_NAME;" -e "s;\${APP_NAME};${JAR_NAME%.*};" -e "s;\${CMD_START};$CMD_STRT;" -e "s;\${PID_DIR};$PID_DIR;" > $file
	
	sudo chmod 755 $file
}

# This function allows to create a linux service directly by using the spring boot jar file feature
# A symbolic link to the jar file is created into /etc/init.d. This symbolic link allows the jar
# to behave like a linux daemon (according to the spring boot documentation)
# 
# This function has not been tested yet, the 1.3.0 version has to be released first.
# TODO: test this function :p
function createSpringBootService() {

	sudo rm /etc/init.d/${JAR_NAME%.*}

	sudo ln -s $INSTALL_DIR/$JAR_NAME /etc/init.d/${JAR_NAME%.*}

	if [ -e /etc/init.d/${JAR_NAME%.*} ]; then
		echo "symbolic link for /etc/init.d/${JAR_NAME%.*} has been successfully created"
		return 0
	else
		echo "an error occured when tried to create symbolic link for /etc/init.d/${JAR_NAME%.*}"
		return 1
	fi
}



###############################################################################
#                            MAIN PROGRAM                                     #
###############################################################################

if [ $DELETE_INSTALL_DIR ]; then
	echo "deleting $INSTALL_DIR"
	sudo rm -rf $INSTALL_DIR
else
	checkAndCreateAppDir
fi

if [ $? -eq 0 ] &&  [ $DELETE_INSTALL_DIR ]; then
	echo "$INSTALL_DIR deleted successfully"
        checkAndCreateAppDir
else
        exit $?
fi

if [ $? -eq 0 ]; then 
	copyJarFile
else
	exit 1 
fi

if [ $CREATE_SP_BOOT_SERVICE -eq 1 ]; then
	echo "creating linux service for spring boot jar file"
	createSpringBootService
else 
	echo "no need to create spring boot service"
fi

if [ $CREATE_OLD_FASHION_SERVICE -eq 1 ]; then
	echo "creating old fashion service"
	createOldFashionService
fi

exit $?
