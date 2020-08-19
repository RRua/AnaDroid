#!/bin/bash
source $ANADROID_PATH/src/settings/settings.sh
#source $ANADROID_PATH/src/workflow/general_workflow.sh
this_dir="$(dirname "$0")"
source "$this_dir/general_workflow.sh"

TESTING_FRAMEWORK="Monkey"
TAG="[${TESTING_FRAMEWORK} Workflow]"


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
temp_folder="$ANADROID_PATH/temp"
hideDir="$ANADROID_PATH/.ana/"
OLDIFS=$IFS
tName="_TRANSFORMED_"
deviceDir=""
default_prefix="/latest"
prefix=""
deviceExternal=""
logDir="$hideDir/logs"
localDir="$HOME/GDResults"
localDirOriginal="$HOME/GDResults"
checkLogs="Off" # Off
monkey="-Monkey"
folderPrefix=""
GD_ANALYZER="$res_folder/jars/AnaDroidAnalyzer.jar"  # "analyzer/greenDroidAnalyzer.jar"
GD_INSTRUMENT="$res_folder/jars/jInst.jar"
trepnLib="TrepnLib-release.aar"
trepnJar="TrepnLib-release.jar"
profileHardware="YES" # YES or something else
logStatus="off"
SLEEPTIME=10 # 10 s 

# TODO put in monkey config file
min_monkey_runs=5 #20
threshold_monkey_runs=3 #50
number_monkey_events=100
min_coverage=50
#DIR=/Users/ruirua/repos/GreenDroid/50apps/*
DEBUG="TRUE" #"TRUE" 




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
	#package from manifest
	APPID=$(grep -o "package=\"[^\"]*\"" $2 | sed 's/package=//g'| sed 's/\"//g' )
	if [ -n "$APPID" ]; then
		eval "$3='$APPID'"
	else
		# from gradle
		APPID=$(grep -o "applicationId\s\".*\"" $1 | awk '{ print $2 }'| sed 's/\"//g')
		if [ -n "$APPID" ]; then
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
	w_echo "removing actual app from processed Apps log"
	sed "s#$3##g" $logDir/processedApps.log > /dev/null 2>&1
	rm ./allMethods.json >/dev/null 2>&1
	w_echo "GOODBYE"
	if [[ "$(isProfilingWithTrepn $PROFILER)" == "TRUE" ]]; then
		#statements
		(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
	fi
	exit -1
}
# get battery from the connected android device


pingDevice(){
	DEVICE=$(adb devices -l  2>&1 | tail -2)
	local x=$(echo $DEVICE | egrep -o "device .+ product:" )
	if [ -z "$DEVICE" ]; then
		(adb kill-server ) > /dev/null  2>&1
		DEVICE=$(adb devices -l  2>&1)
		x=$(echo $DEVICE | egrep "device .+ product:" )
		if [ -z "$x" ]; then
			e_echo "$TAG Error: 📵 Could not find any attached device. Check and try again..."
			exit -1
		fi
	else
		deviceExternal=$(adb shell 'echo -n $EXTERNAL_STORAGE' | tail -1 2>&1)
		if [ -z "$deviceExternal" ]; then
			e_echo "$TAG Could not determine the device's external storage. Check and try again..."
			exit 1
		fi
		deviceDir="$deviceExternal/trepn/"
	fi
}




checkIfAppAlreadyProcessed(){
	x=$1
	retValue="False"
	suc=$(cat $logDir/success.log 2>&1 | sort -u  | grep $x )
	if [ -n $suc  ] && [ "$checkLogs" != "Off" ]; then
		## it was already processed
		#w_echo "Aplicattion $x was already successfuly processed. Skipping.."
		retValue="True"
	fi
	procs=$(cat $logDir/processedApps.log 2>&1 | sort -u  | grep $x )
	if [ -n "$procs"  ] && [ "$checkLogs" != "Off" ]; then
		## it was already processed
		#w_echo "Application $x already processed (But failed). Skipping... (if you want to turn off this verification, set the \"checkLogs\" flag to Off)"
		retValue="True"
	fi
	echo $f >> $logDir/processedApps.log
	#return value
	echo "$retValue"
}

checkConfig(){
	if [[ $trace == "-TestOriented" ]]; then
		e_echo "	Test Oriented Profiling:      ✔"
		folderPrefix="${TESTING_FRAMEWORK}Test"
	elif [[ $trace == "-MethodOriented" ]]; then
		e_echo "	Method Oriented profiling:    ✔"
		folderPrefix="${TESTING_FRAMEWORK}Method"
	elif [[ $trace == "-ActivityOriented" ]]; then
		e_echo "	Activity Oriented profiling:    ✔"
		folderPrefix="${TESTING_FRAMEWORK}Activity"
	fi 
	if [[ $profileHardware == "YES" ]]; then
		w_echo "	Profiling hardware:           ✔"
		if [[ "$(isProfilingWithTrepn $PROFILER)" == "TRUE" ]]; then
			(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/trepnPreferences/All.pref") > /dev/null 2>&1
		fi
		#(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/trepnPreferences/All.pref") > /dev/null 2>&1
	else
		if [[ "$(isProfilingWithTrepn $PROFILER)" == "TRUE" ]]; then
			(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/trepnPreferences/Pref1.pref") > /dev/null 2>&1
		fi 
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

analyzeResults(){
	rejection_0_power_samples_threshold=20 # 20 % 
	cp "$FOLDER/$tName/cloc.out" "$projLocalDir/"
	w_echo "Analyzing results .."
	java -jar $GD_ANALYZER $trace "$projLocalDir/" $monkey $GREENSOURCE_URL 2>&1 | tee "$temp_folder/analyzerResult.out"
	power0_samples_percentage=$( grep "power samples" "$temp_folder/analyzerResult.out" | cut -f2 -d\: |  grep -Eo '[0-9]+([.][0-9]+)?' )			
	is_bigger_than_thresold=$( echo "$power0_samples_percentage > $rejection_0_power_samples_threshold" | bc -l )
	if [[ "$is_bigger_than_thresold" == "1" ]]; then
		#if  % of power samples with 0 value  > threshold
		# reboot phone and then unlock
		rebootAndUnlockPhone
	else 
		i_echo "Low percentage of 0 power samples. continuing..."
	fi

				
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
	$ANADROID_SRC_PATH/others/install.sh "$FOLDER/$tName" "X" "GRADLE" "$PACKAGE" "$localDir" "$monkey" "$apkBuild" "$logDir" 
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
		installed_apk=$(cat $localDir/installedAPK.log)
		NEW_PACKAGE=$(apkanalyzer manifest application-id "$installed_apk")
		#debug_echo "New pack $INSTALLED_PACKAGE vs $PACKAGE"
		test -z "$NEW_PACKAGE" && NEW_PACKAGE=$PACKAGE
		test -z "$NEW_PACKAGE" && NEW_PACKAGE=$(getInstalledPackage) && PACKAGE=$NEW_PACKAGE
	fi
	
	installed_apk=$(cat $localDir/installedAPK.log)
	APK=$installed_apk
	##########
}


pullTestResultsFromDevice(){
	test_id=$1
	if [[ $trace == "-ActivityOriented" ]]; then
		adb pull "$deviceExternal/anadroidDebugTrace.trace" "$localDir/"
		dmtracedump -o "$localDir/anadroidDebugTrace.trace" | grep  "$PACKAGE.*" | grep -E "^[0-9]+ ent" | grep -o "$PACKAGE.*" > "$localDir/TracedMethods$test_id.txt"
		python "$ANADROID_SRC_PATH/others/JVMDescriptorToJSON.py" "$localDir/TracedMethods$test_id.txt"
	
	else
		adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' |  egrep -Eio "TracedMethods.txt" |xargs -I{} adb pull $deviceDir/{} $localDir
		mv $localDir/TracedMethods.txt "$localDir/TracedMethods$test_id.txt"
	fi
	e_echo "Pulling results from device..."
	adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/{} $localDir
	mv catlog.out "$localDir/catlog$test_id.out"
	mv "$localDir/GreendroidResultTrace0.csv" "$localDir/GreendroidResultTrace$test_id.csv"
	analyzeCSV "$localDir/GreendroidResultTrace$test_id.csv"
		
}


runMonkeyTests(){
	########## RUN TESTS 1 phase ############
	trap 'quit $NEW_PACKAGE $TESTPACKAGE $f' INT
	for i  in $seeds20; do
		
		assureConfiguredTestConditions

		w_echo "APP: $ID | SEED Number : $totaUsedTests"
		RET1="0"
		RET="0"
		if [[ "$(isProfilingWithTrepn $PROFILER)" == "TRUE" ]]; then
			#statements
			#(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
			debug_echo "$ANADROID_SRC_PATH/run/trepn/runMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir"
			$ANADROID_SRC_PATH/run/trepn/runMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir		
			RET=$(echo $?)
		fi
		if [[ "$(isProfilingWithGreenscaler $PROFILER)" == "TRUE" ]]; then
			#statements
			#(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
			debug_echo "$ANADROID_SRC_PATH/run/greenscaler/gscalerMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir"
			$ANADROID_SRC_PATH/run/greenscaler/gscalerMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir		
			RET1=$(echo $?)
		fi

		if [ "$RET1" !=  "0" ] || [ "$RET" != "0" ] ; then
			e_echo "An error occured during test execution. Skipping test $i"
			if [ "$RET1" !=  "0" ] ; then
				errorHandler $RET $NEW_PACKAGE
				IGNORE_RUN="YES"
				#$ANADROID_SRC_PATH/others/trepnFix.sh $deviceDir
				#totaUsedTests=0	
			
			fi
			if [ "$RET" !=  "0" ] ; then
				errorHandler $RET $NEW_PACKAGE
				IGNORE_RUN="YES"
				$ANADROID_SRC_PATH/others/trepnFix.sh $deviceDir
				#totaUsedTests=0		
			
			fi			
		else
			i_echo "pulling results of  test $i"
			pullTestResultsFromDevice "$i"
			totaUsedTests=$(($totaUsedTests + 1))						
			if [ "$totaUsedTests" -eq 10 ]; then
				getBattery
			fi
			"$ANADROID_SRC_PATH/others/trepnFix.sh" $deviceDir
		fi

	
	done

	########## RUN TESTS  THRESHOLD ############
	
	##check if have enough coverage
	if [[ $trace == "-ActivityOriented" ]]; then
		nr_methods=$( grep -o "$PACKAGE.*" $localDir/TracedMethods*.txt  | sort -u | wc -l | $SED_COMMAND 's/ //g')
	else
		nr_methods=$( cat $localDir/Traced*.txt | sort -u | uniq | wc -l | $SED_COMMAND 's/ //g')
	fi
	#nr_methods=$( cat $localDir/Traced*.txt | sort -u | uniq | wc -l | $SED_COMMAND 's/ //g')
	actual_coverage=$(echo "${nr_methods}/${total_methods}" | bc -l)
	e_echo "actual coverage -> 0$actual_coverage"
	
	for i in $last30; do
		assureConfiguredTestConditions
		coverage_exceded=$( echo " ${actual_coverage}>= .${min_coverage}" | bc -l)
		RET1="0"
		RET="0"
		if [[ "$(isProfilingWithTrepn $PROFILER)" == "TRUE" ]]; then
			#statements
			#(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
			debug_echo "$ANADROID_SRC_PATH/run/trepn/runMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir"
			$ANADROID_SRC_PATH/run/trepn/runMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir		
			RET=$(echo $?)
		fi
		if [[ "$(isProfilingWithGreenscaler $PROFILER)" == "TRUE" ]]; then
			#statements
			#(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
			debug_echo "$ANADROID_SRC_PATH/run/greenscaler/gscalerMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir"
			$ANADROID_SRC_PATH/run/greenscaler/gscalerMonkeyTest.sh $i $number_monkey_events $trace $NEW_PACKAGE $localDir $deviceDir		
			RET1=$(echo $?)
		fi

		if [ "$RET1" !=  "0" ] || [ "$RET" != "0" ] ; then
			e_echo "An error occured during test execution. Skipping test $i"
			if [ "$RET1" !=  "0" ] ; then
				errorHandler $RET $NEW_PACKAGE
				IGNORE_RUN="YES"
				#$ANADROID_SRC_PATH/others/trepnFix.sh $deviceDir
				#totaUsedTests=0	
			fi

			if [ "$RET" !=  "0" ] ; then
				errorHandler $RET $NEW_PACKAGE
				IGNORE_RUN="YES"
				$ANADROID_SRC_PATH/others/trepnFix.sh $deviceDir
				#totaUsedTests=0		
			
			fi			
		else
			pullTestResultsFromDevice "$i"
			totaUsedTests=$(($totaUsedTests + 1))						
			if [ "$totaUsedTests" -eq 10 ]; then
				getBattery
			fi
		fi
		nr_methods=$( cat $localDir/Traced*.txt | sort -u | uniq | wc -l | $SED_COMMAND 's/ //g')
		actual_coverage=$(echo "${nr_methods}/${total_methods}" | bc -l)
		acu=$(echo "${actual_coverage} * 100" | bc -l)
		w_echo "actual coverage -> $acu %"
		#totaUsedTests=$(($totaUsedTests + 1))
		adb shell am force-stop $NEW_PACKAGE
		if [ "$totaUsedTests" -eq 30 ]; then
			getBattery
		fi
		#$ANADROID_SRC_PATH/others/trepnFix.sh $deviceDir
	done

	trap - INT
	debug_echo "la coveragzita $coverage_exceded"
	if [ "$coverage_exceded" -eq "0" ]; then
		echo "$ID|$actual_coverage" >> $logDir/below$min_coverage.log
	fi

	registInstalledPackages "end"
}

buildAppWithGradle(){
	## BUILD PHASE			
	GRADLE=($(find "$FOLDER/$tName" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep -L "com.android.library" "{}" | xargs -I{} grep -l "buildscript" "{}" | cut -f1 -d: |  awk 'BEGIN{OFS=",";} {print length($1),$1}' | sort -nk 1  | head -1 | cut -f2 -d,))
	#debug_echo "debug os gradles sao ${GRADLE[0]}"
	#debug_echo "ulha os gradles -> ${GRADLE}"
	if [ "$oldInstrumentation" != "$trace" ] || [ -z "$last_build_result" ]; then
		w_echo "[APP BUILDER] Building Again"
		#debug_echo "gradle -> $ANADROID_SRC_PATH/build/buildGradle.sh $ID $FOLDER/$tName ${GRADLE[0]} $apkBuild \"monkey\""
		$ANADROID_SRC_PATH/build/buildGradle.sh "$ID" "$FOLDER/$tName" "${GRADLE[0]}" "$apkBuild" "monkey" "$APPROACH"
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
	fi				
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
		debug_echo "java -jar \"$GD_INSTRUMENT\" \"-gradle\" $tName \"X\" \"$FOLDER\" \"$MANIF_S\" \"$MANIF_T\" \"$trace\" \"$monkey\" \"$GREENSOURCE_APP_UID\" \"$APPROACH\" ##RR"
		instr_output=$(java -jar "$GD_INSTRUMENT" "-gradle" $tName "X" "$FOLDER" "$MANIF_S" "$MANIF_T" "$trace" "$monkey" "$GREENSOURCE_APP_UID" "$APPROACH" ) ##RR
		#w_echo "ai jasus o output $instr_output"
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
	$MV_COMMAND -f $xx $projLocalDir/oldRuns/ >/dev/null 2>&1
	echo "$FOLDER/$tName" > $logDir/lastTranformedApp.txt
	for D in `find "$FOLDER/$tName/" -type d | egrep -v "\/res|\/gen|\/build|\/.git|\/src|\/.gradle"`; do  ##RR
	    if [ -d "${D}" ]; then  ##RR
	    	$MKDIR_COMMAND -p ${D}/libs  ##RR
	     	cp $res_folder/libsAdded/$treprefix$trepnLib ${D}/libs  ##RR
	    fi  ##RR
	done  ##RR
}

setupLocalResultsFolder(){
	echo "$TAG setting up local results folder"
	#create results support folder
	#echo "$TAG Creating support folder..."
	
	GRADLE=($(find "${f}/${prefix}" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
	APP_ID="unknown"
	getAppUID "${GRADLE[0]}" "$MANIF_S" APP_ID
	projLocalDir="$localDir/$APP_ID"
	$MKDIR_COMMAND -p $projLocalDir
	GREENSOURCE_APP_UID="$ID--$APP_ID"

	getFirstAppVersion $appVersion
	projLocalDir="$projLocalDir/$appVersion"
	$MKDIR_COMMAND -p $projLocalDir
	$MKDIR_COMMAND -p $projLocalDir/oldRuns
	($MV_COMMAND -f $(find "$projLocalDir" ! -path "$projLocalDir" -maxdepth 1 | grep -v "oldRuns") $projLocalDir/oldRuns/ ) >/dev/null 2>&1
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


analyzeAPK(){
	#PACKAGE=${RESULT[2]}
	# apk file
	apkFile=$(cat $logDir/lastInstalledAPK.txt)
	w_echo "\nANALYZING APK!!!!\n!!!!!"
	python3 $ANADROID_SRC_PATH/others/analyzeAPIs.py $apkFile $PACKAGE
	$MV_COMMAND ./$PACKAGE.json $projLocalDir/all/
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

checkBuildingTool(){
	GRADLE=($(find "${f}/${prefix}" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
	POM=$(find "${f}/${prefix}" -maxdepth 1 -name "pom.xml")
	NO_SOURCE=$(find "${f}/${prefix}" -name "*.java" -type f  )
	#echo "no sauce ->$NO_SOURCE<-"
	if [ -n "$POM" ]; then
		POM=${POM// /\\ }
		#e_echo "Maven projects are not considered yet..."
		echo "Maven"
		continue
	elif [ -n "${GRADLE[0]}" ]; then
		#statements
		echo "Gradle"
	elif [ -z "$NO_SOURCE" ]; then
		has_apk=$(find "${f}/${prefix}" -name "*.apk" -type f  )
		echo "NO_SOURCE"
	else 
		echo "Eclipse"
	fi
}





trace=$(setup)
$MKDIR_COMMAND -p $logDir
#### Monkey process
(adb kill-server ) > /dev/null  2>&1
pingDevice
getDeviceState "$temp_folder/deviceState.json"
getDeviceSpecs "$temp_folder/device.json"
checkConfig
if [[ "$(isProfilingWithTrepn $PROFILER)" == "TRUE" ]]; then
	adb shell am startservice --user 0 com.quicinc.trepn/.TrepnService > /dev/null  2>&1
fi 

if [[ -n "$logStatus" ]]; then # if should log build status of apps
	($MKDIR_COMMAND $logDir/debugBuild ) > /dev/null  2>&1 #new
fi
w_echo "removing old instrumentations "
$ANADROID_SRC_PATH/others/forceUninstall.sh $ANADROID_SRC_PATH
w_echo "$TAG searching for Android Projects in -> $DIR"
# getting all seeds from file
seeds20=$(head -$min_monkey_runs $res_folder/monkey_seeds.txt)
last30=$(tail  -$threshold_monkey_runs $res_folder/monkey_seeds.txt)
#for each Android Proj in the specified DIR
for f in $DIR/*
	do
	if [[ -f $f ]]; then 
		#if not a directory (i.e Android Project folder), ignore 
		w_echo "$TAG $f is not a folder and will be ignored"
		continue
	fi
	#f="$dir"
	#f=$( echo $f | sed -e "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/" ) # to escape spaces in folder name
	inferPrefix "$f"
	localDir=$localDirOriginal
	cleanDeviceTrash
	IFS='/' read -ra arr <<< "$f"
	ID=${arr[*]: -1} # ID OF of the application (name of respective folder )
	IFS=$(echo -en "\n\b")
	now=$(date +"%d_%m_%y_%H_%M_%S")
	ID=$(echo $ID | sed 's/ //g')
	# check if app was already processed #TODO
	wasProcessed=$(checkIfAppAlreadyProcessed $ID)
	if [ "$wasProcessed" == "True" ]; then
		e_echo "Application $x was already successfuly processed. Skipping.."
		continue
	fi
	checkIfIdIsReservedWord	
	#projLocalDir=$localDir/$ID
	BUILD_TYPE=$(checkBuildingTool)
	w_echo "$TAG processing app $ID"
	if [ "$BUILD_TYPE" == "Maven" ]; then
		POM=${POM// /\\ }
		e_echo " Maven projects are not considered yet... "
		continue
### Gradle proj			
	elif [ "$BUILD_TYPE" == "Gradle"  ]; then
		MANIFESTS=($(find "$f" -name "AndroidManifest.xml" | egrep -v "/build/|$tName"))
		echo "$MANIFESTS"
		if [[ "${#MANIFESTS[@]}" > 0 ]]; then
			#debug_echo " o comando do manif -> python $ANADROID_SRC_PATH/build/manifestParser.py ${MANIFESTS[*]})"
			
			MP=($(python $ANADROID_SRC_PATH/build/manifestParser.py ${MANIFESTS[*]}))
			for R in ${MP[@]}; do 
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
					last_testing_approach=$(grep "blackbox" "$FOLDER/$tName/instrumentationType.txt" 2> /dev/null  )
					if [ -z "$last_testing_approach" ]; then
						#statements
						rm -rf "$FOLDER/$tName/*"
					fi
					# no need to  instrument app source code
					# just  clone original project to $tname
				
					$MKDIR_COMMAND -p "$FOLDER/$tName"
					$(find "$FOLDER" ! -path "$FOLDER"  -maxdepth 1 | grep -v "$tName" | xargs -I{} cp -r {} "$FOLDER/$tName/")
				fi
				buildAppWithGradle
				if [[ "$RET" != "0" ]]; then
					# if BUILD FAILED, SKIPPING APP
					continue
				fi
				countSourceCodeLines "$FOLDER/$tName/"
				totaUsedTests=0	
				prepareAndInstallApp
				if [[ "$IGNORE_RUN" == "YES" ]]; then
					recoverable=$(checkIfErrorIsRecoverable )
					if [[ "$recoverable" == "TRUE" ]]; then
						buildAppWithGradle
						prepareAndInstallApp
						if [[ "$IGNORE_RUN" == "YES" ]]; then
							e_echo "$TAG Skipping execution due to unrecoverable error"
							continue
						fi
					else
						e_echo "$TAG Skipping execution due to unrecoverable 2 error"
						continue
					fi
				fi
				runMonkeyTests
				uninstallApp
				analyzeAPK	
				analyzeResults
				w_echo "$TAG sleeping between profiling apps"
				sleep $SLEEPTIME
				w_echo "$TAG resuming Greendroid after nap"
				getBattery
				printf_new "#" "$(echo -e "\ncols"|tput -S)"
				totaUsedTests=0
			done
		fi
	elif [ "$BUILD_TYPE" == "NO_SOURCE" ] && [ "$APPROACH" == "blackbox" ] ; then
		e_echo "error. Unsupported build type: $BUILD_TYPE"
	else
		e_echo "Dropped support for Eclipse SDK projects"
		continue
#SDK PROJ
	fi
done
IFS=$OLDIFS



