#!/bin/bash

#TODO replace
#ANADROID_PATH=$(pwd)
source $ANADROID_PATH/src/settings/settings.sh

#args
monkey_seed=$1
monkey_nr_events=$2
trace=$3
package=$4
localDir=$5
deviceDir=$6
cpu=''
mem=''
nr_processes=''
sdk_level=''
api_level=''
logDir="$ANADROID_PATH/.ana/logs"
TIMEOUT=300 # 5 minutes
totaUsedTests=0
machine=''
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

grantPermissions(){
	w_echo "Granting permissions on $1"
	(adb shell pm grant $1 android.permission.READ_EXTERNAL_STORAGE) >/dev/null 2>&1
	(adb shell pm grant $1 android.permission.WRITE_EXTERNAL_STORAGE) >/dev/null 2>&1
	
	#adb shell pm grant $1 android.permission.INTERNET
	#adb shell pm grant $1 android.permission.ACCESS_FINE_LOCATION
	#adb shell pm grant $1 android.permission.ACCESS_WIFI_STATE
	#adb shell pm grant $1 android.permission.READ_PHONE_STATE
	#adb shell pm grant $1 android.permission.ACCESS_NETWORK_STATE
	#adb shell pm grant $1 android.permission.RECEIVE_BOOT_COMPLETED

}

initProfiler(){
	w_echo "starting the profiler"
	adb shell monkey -p com.quicinc.trepn -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
	sleep 1
	(adb shell am startservice --user 0 com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
	sleep 2
	(adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME) > /dev/null 2>&1
	sleep 3
	#e_echo "vou carregar o ficheiro pref $deviceDir/saved_preferences/trepnPreferences/All.pref" > /dev/null 2>&1
	(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/All.pref") >/dev/null 2>&1
	sleep 2
}


#set brightness to lowest possible 
#adb shell settings put system screen_brightness_mode 0 
#adb shell settings put system screen_brightness 150 #  0 <= b <=255


#grantPermissions $package
w_echo "setting immersive mode"
adb shell settings put global policy_control immersive.full=$package
adb shell "echo 0 > $deviceDir/GDflag"
i_echo "actual seed -> $monkey_seed"
now=$(date +"%d/%m/%y-%H:%M:%S")
initProfiler
(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
sleep 1
w_echo "starting profiling phase"
(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
sleep 3
#w_echo "clicking home button.."
#adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1
#adb shell am broadcast -a org.thisisafactory.simiasque.SET_OVERLAY --ez enable true
getAndroidState cpu mem nr_processes sdk_level api_level
timestamp=$(date +%s )
e_echo "state: CPU: $cpu % , MEM: $mem,proc running : $nr_processes sdk level: $sdk_level API:$api_level"
echo "{\"test_results_unix_timestamp\": \"$timestamp\", \"device_state_mem\": \"$mem\", \"device_state_cpu_free\": \"$cpu\",\"device_state_nr_processes_running\": \"$nr_processes\",\"device_state_api_level\": \"$api_level\",\"device_state_android_version\": \"$sdk_level\" }" > $localDir/begin_state$monkey_seed.json
w_echo "[Measuring]$now Running monkey tests..."

if [[ $trace == "-TestOriented" ]]; then
	adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value "1" -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
fi 
# adb shell -s <seed> -p <package-name> -v <number-of-events> ----pct-syskeys 0 --ignore-crashes --kill-process-after-error
($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-crashes --ignore-security-exceptions --throttle 10 $monkey_nr_events) &> $logDir/monkey.log
RET=$(echo $?)
if [[ $trace == "-TestOriented" ]]; then
	adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value "0" -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
fi
w_echo "stopped tests. "

#exceptions=$(grep "Exception" logs/monkey.log)
#if [[ "$exceptions" != "" ]]; then
#	cat logs/monkey.log
#	e_echo "Fatal Exception occured in app during test execution. ignoring app "
#	
#	echo "x" > monkey.log
#fi
if [[ "$RET" != "0" ]]; then
	e_echo "error while running -> error code : $RET"
	echo "$localDir,$monkey_seed" >> $logDir/timeoutSeed.log
	w_echo "An Error Ocurred. killing process of monkey test"
	adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
	exit 1
fi

echo "stopping running app"
sleep 1
adb shell am force-stop $package 
echo "stopping profiler..."
sleep 1
(adb shell am broadcast -a com.quicinc.trepn.stop_profiling) >/dev/null 2>&1
sleep 6
(adb shell am broadcast -a  com.quicinc.trepn.export_to_csv -e com.quicinc.trepn.export_db_input_file "myfile" -e com.quicinc.trepn.export_csv_output_file "GreendroidResultTrace0" ) >/dev/null 2>&1
#(adb shell am broadcast -a  com.quicinc.trepn.export_to_csv -e com.quicinc.trepn.export_csv_output_file "GreendroidResultTrace0" ) #>/dev/null 2>&1
sleep 1
getAndroidState cpu mem nr_processes sdk_level api_level

adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
#adb shell am broadcast -a org.thisisafactory.simiasque.SET_OVERLAY --ez enable false
e_echo "state: CPU: $cpu % , MEM: $mem,proc running : $nr_processes sdk level: $sdk_level API:$api_level "
echo "{\"device_state_mem\": \"$mem\", \"device_state_cpu_free\": \"$cpu\",\"device_state_nr_processes_running\": \"$nr_processes\",\"device_state_api_level\": \"$api_level\",\"device_state_android_version\": \"$sdk_level\" }" > $localDir/end_state$monkey_seed.json

#adb shell "echo -1 > $deviceDir/GDflag"
#grantPermissions $package

#### AFTER EXPORTING, RUN AGAIN  ( TRACING METHODS)
#adb shell am broadcast -a org.thisisafactory.simiasque.SET_OVERLAY --ez enable true
#w_echo "[Tracing] Running monkey tests..."
#w_echo "monkey command -> $TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --kill-process-after-error  $monkey_nr_events"
#sleep 2
#($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v  --pct-syskeys 0 --ignore-crashes --ignore-security-exceptions --throttle 10 $monkey_nr_events) &> logs/monkey.log
#RET=$(echo $?)
#if [[ "$RET" != "0" ]]; then
#	e_echo "error while running -> error code : $RET"
#	echo "$localDir,$monkey_seed" >> logs/timeoutSeed.log
#	w_echo "A TIMEOUT Ocurred. killing process of monkey test"
#	adb shell ps | grep "com.android.commands.monkey" | awk '{print $2}' | xargs -I{} adb shell kill -9 {}
#fi

echo "cleaning app cache"
adb shell pm clear $package >/dev/null 2>&1
echo "stopping running app"
adb shell am force-stop $package 
exit 0

