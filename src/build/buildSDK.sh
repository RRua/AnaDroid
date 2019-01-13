#!/bin/bash
source settings.sh


OLDIFS=$IFS
IFS=$(echo -en "\n\b")
# $1 - Project ID/PATH/HASH
# $2 - Project package
# $3 - Project source path
# $4 - Project test path

machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
else 
	SED_COMMAND="sed" #linux	
fi

ID=$1
PACKAGE=$2
PROJECT_FOLDER=$3
TEST_FOLDER=$4

deviceDir=$5
localDir=$6

TAG="[APP BUILDER]"
echo ""

logDir="logs"
BUILD_P=$(find $PROJECT_FOLDER -name "build.xml")
BUILD_T=$(find $TEST_FOLDER -name "build.xml")
i_echo "$TAG SDK PROJECT"

w_echo "#SDK#"

echo "Package -> $PACKAGE"
echo "ID -> $ID"
echo "proj fold -> $PROJECT_FOLDER"
echo "test fold -> $TEST_FOLDER"
echo "local dir -> $localDir"
echo "device dir -> $deviceDir"


STATUS_NOK="FAILED"
if [ -n "$BUILD_P" ] && [ -n "$BUILD_T" ]; then
	echo "$TAG Building from existing file"
	ant -f $BUILD_T 
clean debug &> $logDir/buildStatus.log
	STATUS_NOK=$(grep "BUILD FAILED" $logDir/buildStatus.log)
fi
if [ -n "$STATUS_NOK" ]; then
	rm -rf $PROJECT_FOLDER/build.xml $PROJECT_FOLDER/project.properties $PROJECT_FOLDER/local.properties $PROJECT_FOLDER/proguard-project.txt $PROJECT_FOLDER/ant.properties
	rm -rf $TEST_FOLDER/build.xml $TEST_FOLDER/project.properties $TEST_FOLDER/local.properties $TEST_FOLDER/proguard-project.txt $TEST_FOLDER/ant.properties
	echo "$TAG Updating Project"
	UPDATE_P=$(android update project -p $PROJECT_FOLDER -t 1 -n Green --subprojects)

	echo "$TAG Updating Tests"
	UPDATE_T=$(android update test-project -p $TEST_FOLDER --main $PROJECT_FOLDER)
	ant -f $TEST_FOLDER/build.xml clean debug &> $logDir/buildStatus.log
fi
IFS=$OLDIFS

STATUS_NOK=$(grep "BUILD FAILED" $logDir/buildStatus.log)
STATUS_OK=$(grep "BUILD SUCCESS" $logDir/buildStatus.log)

if [ -n "$STATUS_NOK" ]; then
	w_echo "$TAG Retrying..."
	# Let's first try to run the tests directly from the project
	# First, let's clean previous config files
	rm -rf $PROJECT_FOLDER/build.xml $PROJECT_FOLDER/project.properties $PROJECT_FOLDER/local.properties $PROJECT_FOLDER/proguard-project.txt $PROJECT_FOLDER/ant.properties
	rm -rf $TEST_FOLDER/build.xml $TEST_FOLDER/project.properties $TEST_FOLDER/local.properties $TEST_FOLDER/proguard-project.txt $TEST_FOLDER/ant.properties
	# And uninstall potentially previous installed packages
	./forceUninstall.sh

	# Now, execute the clean and build tasks, along with install and test tasks
	echo "$TAG Running the tests (Measuring)"
	adb shell "echo 1 > $deviceDir/GDflag"
	UPDATE_P=$(android update project -p $TEST_FOLDER -t 1 -s)
	ant -f $TEST_FOLDER/build.xml clean debug install test uninstall &> $logDir/buildStatus.log

	echo "$TAG Running the tests (Tracing)"
	adb shell "echo -1 > $deviceDir/GDflag"
	UPDATE_P=$(android update project -p $TEST_FOLDER -t 1 -s)
	ant -f $TEST_FOLDER/build.xml clean debug install test uninstall &> $logDir/buildStatus.log

	# And remove the install apk's
	./forceUninstall.sh

	# Finally, let's check if the error is maintained
	STATUS_NOK=$(grep "BUILD FAILED" $logDir/buildStatus.log)
	STATUS_OK=$(grep "BUILD SUCCESS" $logDir/buildStatus.log)
	if [ -n "$STATUS_NOK" ]; then
		e_echo "$TAG Unable to build project $ID" 
		e_echo "[ERROR] Aborting"
		exit 1
	elif [ -n "$STATUS_OK" ]; then
		i_echo "$TAG Build + Trace/Measure successful for project $ID"
		echo $localDir
		adb shell ls "$deviceDir/Measures/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/Measures/{} $localDir
		#adb shell ls "$deviceDir/TracedMethods.txt" | tr '\r' ' ' | xargs -n1 adb pull 
		adb shell ls "$deviceDir/Traces/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.txt" | xargs -I{} adb pull $deviceDir/Traces/{} $localDir
		adb shell ls "$deviceDir/TracedTests/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.txt" | xargs -I{} adb pull $deviceDir/TracedTests/{} $localDir
		exit 10
	else
		e_echo "$TAG Unable to build project $ID"
		echo "[ERROR] Aborting"
		exit 1
	fi
elif [ -n "$STATUS_OK" ]; then
	i_echo "$TAG Build successful for project $ID"
else
	echo "$TAG Unable to build project $ID"
	echo "[ERROR] Aborting"
	exit 1
fi
