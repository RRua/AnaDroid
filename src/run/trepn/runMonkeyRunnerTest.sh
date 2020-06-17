#!/bin/bash

source $ANADROID_PATH/src/settings/settings.sh
this_dir="$(dirname "$0")"
source "$this_dir/general.sh"

#args
script_index=$1
script_name=$2
package=$3
localDir=$4
deviceDir=$5
trace=$6
#Monkey_Script=$7

logDir="$ANADROID_PATH/.ana/logs"
TIMEOUT=300 # 5 minutes
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

runMonkeyRunnerTest(){
	(monkeyrunner "$script_name" "$package" ) > "$localDir/monkeyrunner.log"
}


runTraceOnlyTest(){
	adb shell "echo -1 > $deviceDir/GDflag" # inform trepnlib to only trace methods
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	#getDeviceResourcesState "$localDir/begin_state$monkey_seed.json"
	w_echo "[Tracing]$now Running Monkey Runner tests..."
	clearLogCat
	runMonkeyRunnerTest	
	w_echo "[Tracing] stopped tests. "
	
	exceptions=$(grep "Exception" $localDir/monkeyrunner.log )
	if [[ -n "$exceptions"  ]]; then
		# if an exception occured during test execution
		e_echo "error while running -> error code : $RET"
		echo "$localDir,$script_name" >> $logDir/error_monkey_runner.log
		exit 1
	else
		i_echo "[Tracing] Test Successfuly Executed"
	fi
	dumpLogCatToFile
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		echo "$localDir,$script_name" >> $logDir/error_monkey_runner.log
		stopAndCleanApp "$package"
	fi
	
}

runMeasureOnlyTest(){
	adb shell "echo 1 > $deviceDir/GDflag"
	i_echo "actual seed -> $script_index"
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
	sleep 3
	getDeviceResourcesState "$localDir/begin_state$script_index.json"
	w_echo "[Measuring]$now Running monkey Runner tests..."
	clearLogCat
	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
	fi 
	
	runMonkeyRunnerTest

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
	fi

	w_echo "[Measuring] stopped tests. "
	getDeviceResourcesState  "$localDir/end_state$script_index.json"

	exceptions=$(grep "Exception" $localDir/monkeyrunner.log )
	if [[ -n "$exceptions"  ]]; then
		# if an exception occured during test execution
		e_echo "error while running -> error code : $RET"
		echo "$localDir,$script_name" >> $logDir/error_monkey_runner.log
		exit 1
	else
		i_echo "[Tracing] Test Successfuly Executed"
	fi
	dumpLogCatToFile
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		echo "$localDir,$script_name" >> $logDir/error_monkey_runner.log
		stopAndCleanApp "$package"
	fi

	stopTrepnProfiler
}

runBothModeTest(){
	adb shell "echo 0 > $deviceDir/GDflag"
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	i_echo "actual test index -> $script_index"
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	#(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
	sleep 3
	getDeviceResourcesState "$localDir/begin_state$script_index.json"
	w_echo "[Both] $now Running monkey tests..."	
	clearLogCat
	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
	fi 
	# adb shell -s <seed> -p <package-name> -v <number-of-events> ----pct-syskeys 0 --ignore-crashes --kill-process-after-error

	runMonkeyRunnerTest

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
	fi
	getDeviceResourcesState "$localDir/end_state$script_index.json"
	w_echo "[Both] stopped tests. "
dumpLogCatToFile
	exceptions=$(grep "Exception" $localDir/monkeyrunner.log )
	if [[ -n "$exceptions"  ]]; then
		# if an exception occured during test execution
		e_echo "error while running -> error code : $RET"
		echo "$localDir,$script_name" >> $logDir/error_monkey_runner.log
		exit 1
	else
		i_echo "[Both] Test Successfuly Executed"
	fi
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		echo "$localDir,$script_name" >> $logDir/error_monkey_runner.log
		stopAndCleanApp "$package"
	fi

	stopTrepnProfiler
}


i_echo "actual Script-> $script_name"
setImmersiveMode $package

## RUN TWICE: One in trace mode and another in measure mode
#runMeasureOnlyTest
runBothModeTest
#cleanAppCache $package
#runTraceOnlyTest
cleanAppCache $package


exit 0
