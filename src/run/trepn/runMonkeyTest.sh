#!/bin/bash

#TODO replace
#ANADROID_PATH=$(pwd)
source $ANADROID_PATH/src/settings/settings.sh

this_dir="$(dirname "$0")"
source "$this_dir/../general.sh"
#args
monkey_seed=$1
monkey_nr_events=$2
trace=$3
package=$4
localDir=$5
deviceDir=$6

logDir="$ANADROID_PATH/.ana/logs"
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



runMonkeyTest(){
	#e_echo "($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-crashes --ignore-security-exceptions --throttle 10 $monkey_nr_events) &> $localDir/monkey.log"
	e_echo "($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-security-exceptions --throttle 100 $monkey_nr_events) &> $localDir/monkey.log)"
	($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-security-exceptions --throttle 100 $monkey_nr_events) &> $localDir/monkey.log 
	##################
}


runTraceOnlyTest(){
	adb shell "echo 0 > $deviceDir/GDflag" # inform trepnlib to only trace methods
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	#getDeviceResourcesState "$localDir/begin_state$monkey_seed.json"
	w_echo "[Tracing]$now Running monkey tests..."
	runMonkeyTest	
	w_echo "[Tracing] stopped tests. "
	
	exceptions=$(grep "Exception" $localDir/monkey.log )
	if [[ -n "$exceptions"  ]]; then
		# if an exception occured during test execution
		e_echo "error while running -> error code : $RET"
		echo "$localDir,$monkey_seed" >> $logDir/timeoutSeed.log
		w_echo "An Error Ocurred. killing process of monkey test"
		adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
		exit 1
	else
		i_echo "[Tracing] Test Successfuly Executed"
	fi
	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
	e_echo "foreground_app = $foreground_app"
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		e_echo "$package,$monkey_seed" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi
	echo "stopping running app"
	adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
	#getDeviceResourcesState "$localDir/end_state$monkey_seed.json"

}

runMeasureOnlyTest(){
	adb shell "echo 1 > $deviceDir/GDflag"
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	i_echo "actual seed -> $monkey_seed"
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
	sleep 3
	#w_echo "clicking home button.."
	#adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1
	#adb shell am broadcast -a org.thisisafactory.simiasque.SET_OVERLAY --ez enable true
	getDeviceResourcesState "$localDir/begin_state$monkey_seed.json"
	w_echo "[Measuring]$now Running monkey tests..."

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
	fi 
	
	runMonkeyTest

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
	fi

	w_echo "[Measuring] stopped tests. "
	getDeviceResourcesState "$localDir/end_state$monkey_seed.json"

	exceptions=$(grep "Exception" $localDir/monkey.log )
	if [[ -n "$exceptions"  ]]; then
		e_echo "error while running -> error code : $RET"
		echo "$localDir,$monkey_seed" >> $logDir/timeoutSeed.log
		w_echo "An Error Ocurred. killing process of monkey test"
		adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
		exit 1
	else
		i_echo "[Measuring] Test Successfuly Executed"
	fi

	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
e_echo "foreground_app = $foreground_app"
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		e_echo "$package,$monkey_seed" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi

	stopTrepnProfiler

	echo "stopping running app"
	adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
	
}

#to run both modes simultaneously
runBothModeTest(){
	adb shell "echo 0 > $deviceDir/GDflag"
	(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	i_echo "actual seed -> $monkey_seed"
	now=$(date +"%d/%m/%y-%H:%M:%S")
	initTrepnProfiler
	#(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
	sleep 1
	w_echo "starting profiling phase"
	(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
	sleep 3
	getDeviceResourcesState "$localDir/begin_state$monkey_seed.json"
	w_echo "[Both] $now Running monkey tests..."

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 1 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
	fi 
	# adb shell -s <seed> -p <package-name> -v <number-of-events> ----pct-syskeys 0 --ignore-crashes --kill-process-after-error

	runMonkeyTest

	if [[ $trace != "-MethodOriented" ]]; then
		adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value 0 -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
	fi
	getDeviceResourcesState "$localDir/end_state$monkey_seed.json"
	w_echo "[Both] stopped tests. "

	exceptions=$(grep "Exception" $localDir/monkey.log )
	if [[ -n "$exceptions"  ]]; then
		e_echo "error while running -> error code : $RET"
		echo "$localDir,$monkey_seed" >> $logDir/timeoutSeed.log
		w_echo "An Error Ocurred. killing process of monkey test"
		adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
		exit 1
	else
		i_echo "[Both] Test Successfuly Executed"
	fi

	gracefullyQuitApp
	foreground_app=$(getForegroundApp)
e_echo "foreground_app = $foreground_app"
	if [[ "$package" == "$foreground_app"  ]]; then
		# gracefull exit failed. force kill
		e_echo "$package,$monkey_seed" > $logDir/badExit.log
		stopAndCleanApp "$package"
	fi

	stopTrepnProfiler

	echo "stopping running app"
	adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}

}


#set brightness to lowest possible 
#adb shell settings put system screen_brightness_mode 0 
#adb shell settings put system screen_brightness 150 #  0 <= b <=255

setImmersiveMode $package

## RUN TWICE: One in trace mode and another in measure mode
runMeasureOnlyTest
#cleanAppCache $package
runTraceOnlyTest


cleanAppCache $package


exit 0

