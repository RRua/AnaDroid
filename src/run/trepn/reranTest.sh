#!/bin/bash

#TODO replace
#ANADROID_PATH=$(pwd)
source $ANADROID_PATH/src/settings/settings.sh

this_dir="$(dirname "$0")"
source "$this_dir/../general.sh"
#args
replay_file=$1
replay_test_index=$2
replay_delay=$3
trace=$4
package=$5
localDir=$6
deviceDir=$7

TAG="[RERAN TEST]"


logDir="$ANADROID_PATH/.ana/logs"
LAUNCH_APP="TRUE"
TIMEOUT=300 # 5 minutes
totaUsedTests=0
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
		echo "$package,$replay_test_index" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi
}

pushFilesToDevice(){
	python "${this_dir}/../RERAN_TEST.py" "push" "$package" "$replay_file"
}

runRERANTest(){
	#e_echo "($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-crashes --ignore-security-exceptions --throttle 10 $monkey_nr_events) &> $localDir/monkey.log"
	if [[ "$LAUNCH_APP" == "TRUE" ]]; then
		#launch app with monkey
		adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
		sleep 8
	fi
	(python "${this_dir}/../RERAN_TEST.py" "replay" "$package" "$replay_file" ) &> "$localDir/reran.log"

}


runTraceOnlyTest(){
	adb shell "echo -1 > $deviceDir/GDflag" # inform trepnlib to only trace methods
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	#getDeviceResourcesState "$localDir/begin_state$monkey_seed.json"
	w_echo "[Tracing]$now Running RERAN test"
	runRERANTest	
	i_echo "[Tracing]  Test Successfuly Executed "
	
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		echo "$package,$replay_test_index" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi
	#echo "stopping running app"
	
}

runMeasureOnlyTest(){
	adb shell "echo 1 > $deviceDir/GDflag"
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	i_echo "$TAG Replay test -> $replay_file"
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile") > /dev/null
	sleep 3
	#w_echo "clicking home button.."
	#adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1
	#adb shell am broadcast -a org.thisisafactory.simiasque.SET_OVERLAY --ez enable true
	getDeviceResourcesState "$localDir/begin_state$replay_test_index.json"
	w_echo "[Measuring]$now Running RERAN tests..."

	if [[ $trace != "-MethodOriented" ]]; then
		(adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started") > /dev/null
	fi 
	
	runRERANTest

	if [[ $trace != "-MethodOriented" ]]; then
		(adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped") > /dev/null
	fi

	w_echo "[Measuring] stopped tests. "
	getDeviceResourcesState "$localDir/end_state$replay_test_index.json"
	i_echo "[Measuring] Test Successfuly Executed"
	
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	#e_echo "foreground_app = $foreground_app"
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		e_echo "$package,$replay_test_index" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi

	stopTrepnProfiler

}

#to run both modes simultaneously
runBothModeTest(){
	adb shell "echo 0 > $deviceDir/GDflag"
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	i_echo "actual test -> $replay_file"
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	#(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
	sleep 3
	getDeviceResourcesState "$localDir/begin_state$replay_test_index.json"
	w_echo "[Both] $now Running RERAN tests..."

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
	fi 
	# adb shell -s <seed> -p <package-name> -v <number-of-events> ----pct-syskeys 0 --ignore-crashes --kill-process-after-error

	runRERANTest

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
	fi
	getDeviceResourcesState "$localDir/end_state$replay_test_index.json"
	w_echo "[Both] stopped tests. "
	i_echo "[Both] Test Successfuly Executed"
	
	closeApp

	stopTrepnProfiler
}


pushFilesToDevice

setImmersiveMode $package


## RUN TWICE: One in trace mode and another in measure mode
runBothModeTest
#runMeasureOnlyTest
#cleanAppCache $package
#runTraceOnlyTest


cleanAppCache $package


exit 0

