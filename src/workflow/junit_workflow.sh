#!/bin/bash
source $ANADROID_PATH/src/settings/settings.sh

this_dir="$(dirname "$0")"
source "$this_dir/general_workflow.sh"

TAG="[JUNIT Worflow]"

machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
	MKDIR_COMMAND="gmkdir"
	MV_COMMAND="gmv"
else 
	SED_COMMAND="sed" #linux
	MKDIR_COMMAND="mkdir"
	MV_COMMAND="mv"	
fi

# args
ANADROID_PATH=$1
PROFILER=$2
trace=$3
GREENSOURCE_URL=$4
apkBuild=$5
DIR=$6
APPROACH=$7

# global
ANADROID_SRC_PATH=$ANADROID_PATH/src/
res_folder="$ANADROID_PATH/resources"
hideDir="$ANADROID_PATH/.ana/"
OLDIFS=$IFS
tName="_TRANSFORMED_"
deviceDir=""
prefix="" # "latest" or "" ; Remove if normal app
default_prefix="/latest/"
deviceExternal=""
logDir="$hideDir/logs"
localDir="$HOME/GDResults"
localDirOriginal="$HOME/GDResults"
checkLogs="Off"
TESTING_FRAMEWORK="-junit"
folderPrefix=""
GD_ANALYZER="$res_folder/jars/AnaDroidAnalyzer.jar"  # "analyzer/greenDroidAnalyzer.jar"
GD_INSTRUMENT="$res_folder/jars/jInst.jar"
trepnLib="TrepnLib-release.aar"
#trepnJar="TrepnLib-release.jar"
profileHardware="YES" # YES or something else
logStatus="off"
SLEEPTIME=60 # 1 minutes
temp_folder="$ANADROID_PATH/temp"
#DIR=/Users/ruirua/repos/GreenDroid/50apps/*

# trap - INT
# trap 'quit' INT


setup(){
	if [ "$trace" == "testoriented" ]; then
		trace="-TestOriented"
	else
		trace="-MethodOriented"
	fi
}

analyzeCSV(){
	local tags=$(cat $1 |  grep "stopped" | wc -l)
	if [ $tags -lt "2" ] && [ "$folderPrefix" == "MonkeyTest" ] ; then
		e_echo " $1 might contain an error "
		echo "$1" >> $logDir/csvErrors.log
	fi
}
errorHandler(){
	if [[ "$1" == "1" ]]; then
		#exception occured during tests
		w_echo "killing running app..."
		adb shell am force-stop $1
		w_echo "uninstalling actual app $2"
		$ANADROID_SRC_PATH/others/uninstall.sh $1
	fi
}
# trying to determine the application uuid
# appId != package of the manifest, the appID is defined in the build.gradle, and may change according to app flavor, build_type, paid/free app, etc
# ignored this for now. tries to get  applicationID in build.gradle($1). otherwise gives the package in AndroidManifest.xml ($2) file
# In GreenSource context, we defined the appID = "projectID#appID";
getAppUID(){
	GRADLE_FILE=$1
	MANIFEST_FILE=$2
	APPID=$(grep -o "applicationId\s\".*\"" $1 | awk '{ print $2 }'| sed 's/\"//g')
	if [[ -n "$APPID" ]]; then
		eval "$3='$APPID'"
	else
		#package from manifest
		APPID=$(grep  -o "package=\".*\"" $2 | sed 's/package=//g'| sed 's/\"//g' )
		if [[ -n "$APPID" ]]; then
			eval "$3='$APPID'"
		fi		
	fi
}
# abort the script execution during testing phase
quit(){
	w_echo "Aborting.."
	e_echo "signal QUIT received. Gracefully aborting..."
	w_echo "killing running app..."
	adb shell am force-stop $1
	w_echo "uninstalling actual app $1"
	$ANADROID_SRC_PATH/others/uninstall.sh $1 $2
	rm ./allMethods.json >/dev/null 2>&1
	w_echo "removing actual app from processed Apps log"
	sed "s#$3##g" $logDir/processedApps.log
	w_echo "GOODBYE"
	(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
	exit -1
}
# get battery from the connected android device
getBattery(){
	battery_level=$(adb shell dumpsys battery | grep -o "level.*" | cut -f2 -d: | sed 's/ //g')
	w_echo " Actual battery level : $battery_level"
	if [ "$battery_level" -le 20 ]; then
		w_echo "battery level below 20%. Sleeping again"
		sleep 300 # sleep 5 min to charge battery
	fi
}

analyzeResults(){
	rejection_0_power_samples_threshold=20 # 20 % 
	cp "$FOLDER/$tName/cloc.out" "$projLocalDir/"
	#w_echo "Analyzing results .."
	debug_echo "java -jar $GD_ANALYZER \"$trace\" \"$projLocalDir/\" \"${TESTING_FRAMEWORK}\" \"$GREENSOURCE_URL\""
	java -jar "$GD_ANALYZER" "$trace" "$projLocalDir/" "${TESTING_FRAMEWORK}" "$GREENSOURCE_URL" 2>&1 | tee "$temp_folder/analyzerResult.out"
	power0_samples_percentage=$( grep "power samples" "$temp_folder/analyzerResult.out" | cut -f2 -d\: |  grep -Eo '[0-9]+([.][0-9]+)?' )			
	is_bigger_than_thresold=$( echo "$power0_samples_percentage > $rejection_0_power_samples_threshold" | bc -l )
	if [[ "$is_bigger_than_thresold" == "1" ]]; then
		#if  % of power samples with 0 value  > threshold
		# reboot phone and then unlock
		echo "rebootAndUnlockPhone"
	fi	
				
}


checkBuildingTool(){
	GRADLE=($(find "${f}/${prefix}" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
	POM=$(find "${f}/${prefix}" -maxdepth 1 -name "pom.xml")
	if [ -n "$POM" ]; then
		POM=${POM// /\\ }
		#e_echo "Maven projects are not considered yet..."
		echo "Maven"
		continue
	elif [ -n "${GRADLE[0]}" ]; then
		#statements
		echo "Gradle"
	else 
		echo "Eclipse"
	fi
}




pingDevice(){
	DEVICE=$(adb devices -l  2>&1 | tail -2)
	local x=$(echo $DEVICE | egrep -o "device .+ product:" )
	if [ -z "$x" ]; then
		(adb kill-server ) > /dev/null  2>&1
		DEVICE=$(adb devices -l  2>&1)
		x=$(echo $DEVICE | egrep "device .+ product:" )
		if [ -z "$x" ]; then
			e_echo "$TAG Error: 📵 Could not find any attached device. Check and try again..."
			exit -1
		fi
	else
		deviceExternal=$(adb shell 'echo -n $EXTERNAL_STORAGE' 2>&1)
		if [ -z "$deviceExternal" ]; then
			e_echo "$TAG Could not determine the device's external storage. Check and try again..."
			exit 1
		fi
	fi
}

getDeviceSpecs(){
	devJson=$1
	local device_model=$(   echo  $DEVICE  | grep -o "model.*" | cut -f2 -d: | cut -f1 -d\ )
	local device_serial=$(   echo  $DEVICE | tail -n 2 | grep "model" | cut -f1 -d\ )
	local device_brand=$(  echo  $DEVICE | grep -o "device:.*" | cut -f2 -d: )
	echo "{\"device_serial_number\": \"$device_serial\", \"device_model\": \"$device_model\",\"device_brand\": \"$device_brand\"}" > "$devJson"
	i_echo "$TAG 📲  Attached device ($device_model) recognized "
	deviceDir="$deviceExternal/trepn"
}

cleanDeviceTrash() {

	adb shell rm -rf "$deviceDir/allMethods.txt" "$deviceDir/TracedMethods.txt" "$deviceDir/Traces/*" "$deviceDir/Measures/*" "$deviceDir/TracedTests/*"
}


analyzeAPK(){
	#PACKAGE=${RESULT[2]}
	# apk file
	apkFile=$installed_apk
	w_echo "\nANALYZING APK!!!!\n!!!!!"
	python3 $ANADROID_SRC_PATH/others/analyzeAPIs.py "$apkFile" "$PACKAGE"
	debug_echo "vou mover ./$PACKAGE.json "$projLocalDir/all/" "
	$MV_COMMAND ./$PACKAGE.json "$projLocalDir/all/"
}

setupTrepnDirs(){
	adb shell mkdir -p $deviceDir/Measures
	adb shell mkdir -p $deviceDir/TracedTests
	adb shell mkdir -p $deviceDir/Traces

}


checkIfAppAlreadyProcessed(){
	x=$1
	suc=$(cat $logDir/success.log 2>&1 | sort -u | uniq | grep $x )
	if [ -n $suc  ] && [ "$checkLogs" != "Off" ]; then
		## it was already processed
		w_echo "Aplicattion $x was already successfuly processed. Skipping.."
		continue
	fi
	procs=$(cat $logDir/processedApps.log 2>&1 | sort -u | uniq | grep $x )
	if [ -n "$procs"  ] && [ "$checkLogs" != "Off" ]; then
		## it was already processed
		w_echo "Application $x already processed (But failed). Skipping... (if you want to turn off this verification, set the \"checkLogs\" flag to Off)"
		continue
	fi
	echo $f >> $logDir/processedApps.log
}

checkConfig(){
	if [[ $trace == "-TestOriented" ]]; then
		e_echo "	Test Oriented Profiling:      ✔"
		folderPrefix="JUnitTest"
	else 
		e_echo "	Method Oriented profiling:    ✔"
		folderPrefix="JUnitMethod"
	fi 
	if [[ $profileHardware == "YES" ]]; then
		w_echo "	Profiling hardware:           ✔"
		(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/trepnPreferences/All.pref") > /dev/null 2>&1
	else 
		(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/trepnPreferences/Pref1.pref") > /dev/null 2>&1
	fi	
}

checkIfIdIsReservedWord(){
	if [ "$ID" == "success" ] || [ "$ID" == "failed" ] || [ "$ID" == "unknown" ]; then	
		continue
	fi
}

getFirstAppVersion(){

	#version_file="${f}/version.log"
	version_file=$( find "${DIR}" -maxdepth 2 -type f -name version.log | head -1 )
	is_os_app=$( echo ${DIR} | xargs basename | grep ".*_src$" )
	if [[ -f "$version_file" ]]; then
		debug_echo "achei ficheiro versão"
		appVersion=$(head -1 "$version_file")
	
	elif [[ -n "$is_os_app" ]]; then
		#if it is an app version identified as <version-code>_src
		appVersion=$(echo "$is_os_app" | sed 's/_src//g')
	else
		gradle_files=$(find "${f}/${prefix}" -maxdepth 1 -name "build.gradle" )
		for i in $gradle_files; do
			appVersion=$(cat ${i} | grep "versionName" | head -1 | cut -f2 -d\")
			if [[ -n "$appVersion" ]]; then
				break
			fi
		done
	fi
	if [[ -z "$appVersion" ]]; then
			appVersion="0.0"
	fi
	echo "$appVersion"
}


prepareAndInstallApp(){
	localDir=$projLocalDir/$folderPrefix$now
	$MKDIR_COMMAND -p $localDir
	cp $temp_folder/* $localDir
	cp $res_folder/config/GSlogin.json $localDir
	#echo "$TAG Creating support folder..."
	#mkdir -p $localDir
	#$MKDIR_COMMAND -p $localDir/all
	##copy MethodMetric to support folder
	#echo "copiar $FOLDER/$tName/classInfo.ser para $projLocalDir "
	cp $FOLDER/$tName/$GREENSOURCE_APP_UID.json $localDir
	cp $FOLDER/$tName/appPermissions.json $localDir

	# define test conditions according to the permissions declared in manifest file
	defineTestConfigurations "$FOLDER/$tName/appPermissions.json"

	registInstalledPackages "start"
	#install on device
	w_echo "[APP INSTALLER] Installing the apps on the device"
	debug_echo "install command -> $ANADROID_SRC_PATH/others/install.sh \"$FOLDER/$tName\" \"X\" \"GRADLE\" \"$PACKAGE\" \"$projLocalDir\" \"$monkey\" \"$apkBuild\" \"$logDir\""
	$ANADROID_SRC_PATH/others/install.sh "$FOLDER/$tName" "X" "GRADLE" "$PACKAGE" "$localDir" "$TESTING_FRAMEWORK" "$apkBuild" "$logDir" 
	RET=$(echo $?)
	if [[ "$RET" != "0" ]]; then
		echo "$ID" >> $logDir/errorInstall.log
		IGNORE_RUN="YES"
		return
	fi
	echo "$ID" >> $logDir/success.log
	#total_methods=$( cat $projLocalDir/all/allMethods.txt | sort -u| uniq | wc -l | $SED_COMMAND 's/ //g')
	total_methods=$( cat "$projLocalDir/all/allMethods.json" | grep -o "\->" | wc -l  | $SED_COMMAND 's/ //g')
	#now=$(date +"%d_%m_%y_%H_%M_%S")
	IGNORE_RUN=""

	NEW_PACKAGE=$PACKAGE
	isInstalled=$( isAppInstalled $PACKAGE )
	
	if [[ "$isInstalled" == "FALSE" ]]; then
		#e_echo "$TAG App not installed. Skipping tests execution"
		
		NEW_PACKAGE=$(apkanalyzer manifest application-id "$installed_apk") 
		test -z "$NEW_PACKAGE" && NEW_PACKAGE=$PACKAGE
		test -z "$NEW_PACKAGE" && NEW_PACKAGE=$(getInstalledPackage) && PACKAGE=$NEW_PACKAGE

		#debug_echo "New pack $INSTALLED_PACKAGE vs $PACKAGE"
	fi
	installed_apk=$(head -1 $localDir/installedAPK.log)
	APK=$installed_apk

	logInstalledAPKVersionInfo "$NEW_PACKAGE" "$projLocalDir/version.log"
	if [[ "$appVersion" == "0.0" ]]; then
		# if it is still indetermined
		appVersion=$(cat "$projLocalDir/version.log" )
		test -z "$app_version" && app_version="0.0"
		projLocalDir="$firstProjLocalDir/$appVersion"
		current_local_dir=$localDir
		current_vers_dir=$( echo "$localDir" | xargs dirname ) 
		localDir=$projLocalDir/$folderPrefix$now
		if [ -d "$projLocalDir" ]; then
			saveOldRuns "$projLocalDir"
			mv  "$current_local_dir" "$localDir"
		else
			mv "$current_vers_dir" "$projLocalDir"
		fi
	fi
	##########
}


runJUnitTests(){
	#run tests
	#e_echo "$ANADROID_SRC_PATH/run/runTests.sh $PACKAGE $TESTPACKAGE $deviceDir $projLocalDir $folderPrefix $FOLDER/$tName"
	assureConfiguredTestConditions

	w_echo "APP: $ID | SEED Number : $totaUsedTests"
		RET1="0"
		RET="0"
		if [[ "$(isProfilingWithTrepn $PROFILER)" == "TRUE" ]]; then
			#statements
			#(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
			debug_echo "$ANADROID_SRC_PATH/run/trepn/runTests.sh $PACKAGE $TESTPACKAGE $deviceDir $localDir $folderPrefix $FOLDER/$tName"
			$ANADROID_SRC_PATH/run/trepn/runJUnitTests.sh "$PACKAGE" "$TESTPACKAGE" "$deviceDir" "$localDir" "$folderPrefix" "$FOLDER/$tName"
			RET=$(echo $?)
			if [[ "$RET" != "0" ]]; then
				echo "$ID" >> $logDir/errorRun.log
				e_echo "[GD ERROR] There was an Error while running tests. Retrying... "
				#RETRY 
				sleep 2
				$ANADROID_SRC_PATH/run/trepn/runJUnitTests.sh "$PACKAGE" "$TESTPACKAGE" "$deviceDir" "$localDir" "$folderPrefix" "$FOLDER/$tName" # "-gradle" $FOLDER/$tName
				RET=$(echo $?)
				if [[ "$RET" != "0" ]]; then
					echo "$ID" >> $logDir/errorRun.log
					e_echo "[GD ERROR] FATAL ERROR RUNNING TESTS. IGNORING APP "
					continue
				fi
	fi
		fi
		if [[ "$(isProfilingWithGreenscaler $PROFILER)" == "TRUE" ]]; then
			#statements
			#(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
			e_echo "$TAG greenscaler not suported with JUNIT framework"
		fi


	assureConfiguredTestConditions #todo change this to runjunit test script
	registInstalledPackages "end"

}

buildAppWithGradle(){
	## BUILD PHASE						
	GRADLE=($(find "$FOLDER/$tName" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep -L "com.android.library" "{}" | xargs -I{} grep -l "buildscript" "{}" | cut -f1 -d:))
	#debug_echo "ulha os gradles -> ${GRADLE}"
	if [ "$oldInstrumentation" != "$trace" ] || [ -z "$last_build_result" ]; then
		w_echo "[APP BUILDER] Building Again"
		e_echo "gradle -> $ANADROID_SRC_PATH/build/buildGradle.sh $ID $FOLDER/$tName ${GRADLE[0]} $apkBuild \"monkey\""
		$ANADROID_SRC_PATH/build/buildGradle.sh "$ID" "$FOLDER/$tName" "${GRADLE[0]}" "$apkBuild" "junit"
		RET=$(echo $?)
	else 
		w_echo "[APP BUILDER] No changes since last run. Not building again"
		RET=0
	fi
	(echo $trace) > "$FOLDER/$tName/instrumentationType.txt"
	if [[ "$RET" != "0" ]]; then
		# BUILD FAILED. SKIPPING APP
		echo "$ID" >> $logDir/errorBuildGradle.log
		cp $logDir/buildStatus.log $f/buildStatus.log
		if [[ -n "$logStatus" ]]; then
			cp $logDir/buildStatus.log $logDir/debugBuild/$ID.log
		fi
		continue
	fi
	## END BUILD PHASE						
}

instrumentGradleApp(){
	RET="TRUE"
	oldInstrumentation=$(cat "$FOLDER/$tName/instrumentationType.txt" 2>/dev/null | grep  ".*Oriented" )
	#allmethods=$(find "$projLocalDir/all" -maxdepth 1 -name "allMethods.json")
	last_build_result=$(grep "BUILD SUCCESSFUL" "$FOLDER/$tName/buildStatus.log" 2>/dev/null  )
	if [ "$oldInstrumentation" != "$trace" ] || [ -z "$last_build_result" ]  ; then
		# same instrumentation and build successfull 
		w_echo "Different type of instrumentation. instrumenting again..."
		rm -rf $FOLDER/$tName
		$MKDIR_COMMAND -p "$FOLDER/$tName"
		echo "$Proj_JSON" > "$FOLDER/$tName/$GREENSOURCE_APP_UID.json"
		echo "$TAG Instrumenting project"
		debug_echo "java -jar \"$GD_INSTRUMENT\" \"-gradle\" $tName \"X\" \"$FOLDER\" \"$MANIF_S\" \"$MANIF_T\" \"$trace\" \"$TESTING_FRAMEWORK\" \"$GREENSOURCE_APP_UID\" \"$APPROACH\" ##RR"
		instr_output=$(java -jar "$GD_INSTRUMENT" "-gradle" $tName "X" "$FOLDER" "$MANIF_S" "$MANIF_T" "$trace" "$TESTING_FRAMEWORK" "$GREENSOURCE_APP_UID" "$APPROACH" ) ##RR
		if [ -n "$(echo $instr_output | grep 'Exception' )" ]; then
			echo "-$(echo $instr_output | grep 'Exception' )-"
			echo "$FOLDER" >> "$logDir/errorInstrument.log"
			RET="FALSE"
		else
			w_echo "$TAG Project instrumented successfuly"
		fi

		#$MV_COMMAND ./allMethods.txt $projLocalDir/all/allMethods.txt
		cp ./allMethods.json "$projLocalDir/all/allMethods.json"
		cp ./allMethods.json "$FOLDER/$tName/allMethods.json"
		#Instrument all manifestFiles
		(find "$FOLDER/$tName" -name "AndroidManifest.xml" | egrep -v "/build/" | xargs -I{} $ANADROID_SRC_PATH/build/manifestInstr.py "{}" )
	else 
		cp "$FOLDER/$tName/allMethods.json" "$projLocalDir/all/allMethods.json"
		e_echo "Same instrumentation of last time. Skipping instrumentation phase"
	
	fi
	#(echo "{\"app_id\": \"$ID\", \"app_location\": \"$f\",\"app_build_tool\": \"gradle\", \"app_version\": \"1\", \"app_language\": \"Java\"}") > $FOLDER/$tName/application.json
	xx=$(find  "$projLocalDir/" -maxdepth 1 | $SED_COMMAND -n '1!p' |grep -v "oldRuns" | grep -v "all" )
	##echo "xx -> $xx"
	saveOldRuns "$projLocalDir"
	echo "$FOLDER/$tName" > $logDir/lastTranformedApp.txt
	for D in `find "$FOLDER/$tName/" -type d | egrep -v "\/res|\/gen|\/build|\/.git|\/src|\/.gradle"`; do  ##RR
	    if [ -d "${D}" ]; then  ##RR
	    	$MKDIR_COMMAND -p ${D}/libs  ##RR
	     	cp $res_folder/libsAdded/$treprefix$trepnLib ${D}/libs  ##RR
	    fi  ##RR
	done  ##RR
}

pullTestResultsFromDevice(){
	i_echo "$TAG Pulling result files"
	#check if trepn worked correctly
	Nmeasures=$(adb shell ls "$deviceDir/Measures/" | wc -l)
	Ntraces=$(adb shell ls "$deviceDir/Traces/" | wc -l)
	echo "Nº measures: $Nmeasures"
	echo "Nº traces:   $Ntraces"
	if [[ $folderPrefix == "JUnitMethod" ]]; then
		#statements
		adb shell mv "$deviceDir/*.csv" "$deviceDir/Measures/"
	else 
	    if [ $Nmeasures -le "0" ] || [ $Ntraces -le "0" ] || [ $Nmeasures -ne $Ntraces ] ; then 
			e_echo "[GD ERROR] Something went wrong. try run trepnFix.sh and try again"
			exit 2
		fi
	fi
	cp "$FOLDER/$tName/application.json" "$localDir"
	cp "$FOLDER/$tName/appPermissions.json" "$localDir"
	adb shell ls "$deviceDir/Measures/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/Measures/{} "$localDir"
	#adb shell ls "$deviceDir/TracedMethods.txt" | tr '\r' ' ' | xargs -n1 adb pull 
	adb shell ls "$deviceDir/Traces/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.txt" | xargs -I{} adb pull $deviceDir/Traces/{} "$localDir"
	adb shell ls "$deviceDir/TracedTests/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.txt" | xargs -I{} adb pull $deviceDir/TracedTests/{} "$localDir"
	csvs=$(find "$localDir" -name "*.csv")
	for i in $csvs; do
		tags=$(cat "$i" |  grep "stopped" | wc -l)
		if [ $tags -lt "2" ] && [ "$folderPrefix" == "Test" ] ; then
			e_echo " $i might contain an error "
			echo "$i" >> logs/csvErrors.log
		fi
	done
}


setupLocalResultsFolder(){
	#echo "$TAG setting up local results folder"
	#create results support folder
	#echo "$TAG Creating support folder..."
	GRADLE=($(find "${f}/${prefix}" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
	APP_ID="unknown"
	getAppUID "${GRADLE[0]}" "$MANIF_S" APP_ID
	projLocalDir="$localDir/$APP_ID"
	firstProjLocalDir="$projLocalDir"
	$MKDIR_COMMAND -p $projLocalDir
	GREENSOURCE_APP_UID="$ID--$APP_ID"

	getFirstAppVersion $appVersion
	projLocalDir="$projLocalDir/$appVersion"
	$MKDIR_COMMAND -p $projLocalDir
	$MKDIR_COMMAND -p $projLocalDir/oldRuns
	saveOldRuns "$projLocalDir"
	$MKDIR_COMMAND -p $projLocalDir/all
	FOLDER=${f}${prefix} #$f
	ORIGINAL_GRADLE=($(find "${FOLDER}" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs grep -L "com.android.library" | xargs grep -l "buildscript" | cut -f1 -d:)) # must be done before instrumentation
	
	APP_JSON="{\"app_id\": \"$GREENSOURCE_APP_UID\", \"app_package\": \"$PACKAGE\", \"app_version\": \"$appVersion\", \"app_project\": \"$ID\"}" #" \"app_language\": \"Java\"}"
	Proj_JSON="{\"project_id\": \"$ID\", \"proj_desc\": \"\", \"proj_build_tool\": \"gradle\", \"project_apps\":[$APP_JSON] , \"project_packages\":[] , \"project_location\": \"$f\"}"
	#echo " ids -> $APP_ID , $GREENSOURCE_APP_UID"
}


uninstallApp(){
	$ANADROID_SRC_PATH/others/uninstall.sh "$NEW_PACKAGE" "$TESTPACKAGE"
	RET=$(echo $?)
	if [[ "$RET" != "0" ]]; then
		echo "$ID" >> $logDir/errorUninstall.log
		#continue
	fi
	uninstallInstalledPackagesDuringTest				
}



inferPrefix(){
	# needed because extracted apps from muse are in a folder name latest inside $ID folder
	local searching_dir=$1
	#e_echo "searching dir $1"
	local have_prefix=$(find "$searching_dir"  -maxdepth 1  -type d | grep $default_prefix )
	if [[ -n "$have_prefix" ]]; then
		prefix=$default_prefix
		#e_echo " has prefix"
	else
		prefix=""
		#e_echo " no prefix"
	fi
}

setup
$MKDIR_COMMAND -p $logDir
#### Monkey process
(adb kill-server ) > /dev/null  2>&1
pingDevice
getDeviceState "$temp_folder/deviceState.json"
getDeviceSpecs "$temp_folder/device.json"
checkConfig
setupTrepnDirs
#adb shell am startservice --user 0 com.quicinc.trepn/.TrepnService > /dev/null  2>&1
if [[ -n "$logStatus" ]]; then # if should log build status of apps
	($MKDIR_COMMAND $logDir/debugBuild ) > /dev/null  2>&1 #new
fi
w_echo "removing old instrumentations "
$ANADROID_SRC_PATH/others/forceUninstall.sh $ANADROID_SRC_PATH
w_echo "$TAG searching for Android Projects in -> $DIR"


#for each Android Proj in the specified DIR
for f in $DIR/*
	do
	if [[ -f $f ]]; then 
		#if not a directory (i.e Android Project folder), ignore 
		w_echo "$TAG $f is not a folder and will be ignored"
		continue
	fi
	inferPrefix "$f"
	localDir=$localDirOriginal
	cleanDeviceTrash
	IFS='/' read -ra arr <<< "$f"
	ID=${arr[*]: -1} # ID OF of the application (name of respective folder )
	IFS=$(echo -en "\n\b")
	now=$(date +"%d_%m_%y_%H_%M_%S")
	# check if app was already processed #TODO
	checkIfAppAlreadyProcessed "$ID"
	checkIfIdIsReservedWord	
	projLocalDir=$localDir/$ID
	BUILD_TYPE=$(checkBuildingTool)
	if [ "$BUILD_TYPE" == "Maven" ]; then
		POM=${POM// /\\ }
		e_echo " Maven projects are not considered yet... "
		continue
### Gradle proj			
	elif [ "$BUILD_TYPE" == "Gradle"  ]; then

		MANIFESTS=($(find "$f" -name "AndroidManifest.xml" | egrep -v "/build/|$tName"))
		if [[ "${#MANIFESTS[@]}" > 0 ]]; then
			MP=($(python $ANADROID_SRC_PATH/build/manifestParser.py ${MANIFESTS[*]}))
			for R in ${MP[@]}; do 
			# FOR EACH APP OF PROJECT
				RESULT=($(echo "$R" | tr ':' '\n'))
				TESTS_SRC=${RESULT[1]}
				PACKAGE=${RESULT[2]}
				if [[ "${RESULT[3]}" != "-" ]]; then
					TESTPACKAGE=${RESULT[3]}
				else
					TESTPACKAGE="$PACKAGE.test"
				fi
				MANIF_S="${RESULT[0]}/AndroidManifest.xml"
				MANIF_T="-"
				setupLocalResultsFolder
				if [ "$APPROACH" == "whitebox" ] ; then
					#debug_echo "white e diferente"
					instrumentGradleApp
					if [ "$RET" == "FALSE" ]; then
						e_echo "error in instrumentation phase. skipping app"
						continue
					fi

				else
					e_echo "No support for blackbox approach using junit framework"
					exit 4
				fi
				buildAppWithGradle
				countSourceCodeLines "$FOLDER/$tName/"
				totaUsedTests=0	
				prepareAndInstallApp
				#runMonkeyTests
				runJUnitTests
				pullTestResultsFromDevice
				uninstallApp
				analyzeAPK
				analyzeResults
				w_echo "$TAG sleeping between profiling apps"
				sleep $SLEEPTIME
				w_echo "$TAG resuming AnaDroid after nap"
				getBattery
				printf_new "#" "$(echo -e "\ncols"|tput -S)"
				totaUsedTests=0
			done
		fi
	else 
		e_echo "Dropped support for Eclipse SDK projects"
		exit -1
	fi
done
IFS=$OLDIFS
#	testRes=$(find $projLocalDir -name "Testresults.csv")
#	if [ -n $testRes ] ; then 
#		cat $projLocalDir/Testresults.csv | $SED_COMMAND 's/,/ ,/g' | column -t -s, | less -S
#	fi
#./trepnFix.sh




