#!/bin/bash

#TODO replace
#ANADROID_PATH=$(pwd)
source $ANADROID_PATH/src/settings/settings.sh

this_dir="$(dirname "$0")"
source "$this_dir/general.sh"
#args
test_index=$1
trace=$2
package=$3
installedAPK=$4
localDir=$5
deviceDir=$6

TAG="[APP CRAWLER TEST]"
test_log_file="crawlerTestOutput.log"
trepnFlag=0

logDir="$ANADROID_PATH/.ana/logs"
LAUNCH_APP="TRUE"
machine=""
getSO machine



if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
	MKDIR_COMMAND="gmkdir"
	MV_COMMAND="gmv"
	TIMEOUT_COMMAND="gtimeout"

else 
	SED_COMMAND="sed" #linux
	MKDIR_COMMAND="mkdir"
	MV_COMMAND="mv"
	TIMEOUT_COMMAND="timeout"
fi


closeApp(){
	foreground_app=$(getForegroundApp)
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		gracefullyQuitApp
	fi
	foreground_app=$(getForegroundApp)
	#e_echo "foreground_app = $foreground_app"
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		echo "$package,0" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi
}



function detectCrawlFinish(){
	keyprase="Crawl finished."
	finished=$(grep "$keyprase"  "$test_log_file" )
	while [[ -z "$finished" ]]; do
		sleep 0.1
		finished=$(grep "$keyprase" "$test_log_file" )
	done
	echo "Crawler Finished. Waiting for generated results..."

	if [ "$trepnFlag" -ge "0" ] && [ $trace != "-MethodOriented" ]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
		w_echo "Stopped tests via background task"
	fi
	exit 0
}



runCrawlerTest(){
	#e_echo "($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-crashes --ignore-security-exceptions --throttle 10 $monkey_nr_events) &> $localDir/monkey.log"
	detectCrawlFinish &
	(java -jar "$ANADROID_PATH/src/testingFrameworks/app-crawler/crawl_launcher.jar" --apk-file "$installedAPK" --app-package-name "$package"  --android-sdk "$ANDROID_HOME") > "$test_log_file"
}

runTraceOnlyTest(){
	trepnFlag=-1
	adb shell "echo -1 > $deviceDir/GDflag" # inform trepnlib to only trace methods
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	#getDeviceResourcesState "$localDir/begin_state$monkey_seed.json"
	grantPermissions "$package"
	w_echo "[Tracing]$now Running CRAWLER test"
	clearLogCat
	runCrawlerTest	
	i_echo "[Tracing]  Test Successfuly Executed "
	dumpLogCatToFile
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		echo "$package,$test_index" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi
	#echo "stopping running app"
	
}

runMeasureOnlyTest(){
	trepnFlag=1
	adb shell "echo 1 > $deviceDir/GDflag"
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile") > /dev/null
	sleep 3
	#w_echo "clicking home button.."
	#adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1
	#adb shell am broadcast -a org.thisisafactory.simiasque.SET_OVERLAY --ez enable true
	getDeviceResourcesState "$localDir/begin_state$test_index.json"
	w_echo "[Measuring]$now Running CRAWLER tests..."
	clearLogCat
	if [[ $trace != "-MethodOriented" ]]; then
		(adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started") > /dev/null
	fi 
	
	runCrawlerTest

	if [[ $trace != "-MethodOriented" ]]; then
		(adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped") > /dev/null
	fi

	w_echo "[Measuring] stopped tests. "
	getDeviceResourcesState "$localDir/end_state$test_index.json"
	i_echo "[Measuring] Test Successfuly Executed"
	dumpLogCatToFile
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	#e_echo "foreground_app = $foreground_app"
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		e_echo "$package,$test_index" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi

	stopTrepnProfiler

}

#to run both modes simultaneously
runBothModeTest(){
	trepnFlag=0
	adb shell "echo 0 > $deviceDir/GDflag"
	i_echo "actual test -> $test_index"
	grantPermissions "$package"
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	#(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
	sleep 3
	getDeviceResourcesState "$localDir/begin_state$test_index.json"
	w_echo "[Both] $now Running CRAWLER tests..."
	clearLogCat
	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
	fi 
	# adb shell -s <seed> -p <package-name> -v <number-of-events> ----pct-syskeys 0 --ignore-crashes --kill-process-after-error

	runCrawlerTest

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
	fi
	getDeviceResourcesState "$localDir/end_state$test_index.json"
	w_echo "[Both] stopped tests. "
	i_echo "[Both] Test Successfuly Executed"
	dumpLogCatToFile
	closeApp
	sleep 10
	stopTrepnProfiler
}


setImmersiveMode $package

## RUN TWICE: One in trace mode and another in measure mode
runBothModeTest
#runMeasureOnlyTest
#cleanAppCache $package
#runTraceOnlyTest


cleanAppCache $package


exit 0

