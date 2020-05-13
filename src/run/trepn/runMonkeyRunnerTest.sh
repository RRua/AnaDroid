#!/bin/bash

source $ANADROID_PATH/src/settings/settings.sh
this_dir="$(dirname "$0")"
source "$this_dir/../general.sh"

#args
script_index=$1
script_name=$2
apk=$3
package=$4
localDir=$5
deviceDir=$6
trace=$7
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

#grantPermissions(){
	#w_echo "Granting permissions on $1"
	#(adb shell pm grant $1 android.permission.READ_EXTERNAL_STORAGE) >/dev/null 2>&1
	#(adb shell pm grant $1 android.permission.WRITE_EXTERNAL_STORAGE) >/dev/null 2>&1
#}

setImmersiveMode
initTrepnProfiler

(adb shell "> $deviceDir/TracedMethods.txt") >/dev/null 2>&1
w_echo "setting immersive mode"
adb shell settings put global policy_control immersive.full=$package
adb shell "echo 0 > $deviceDir/GDflag"
i_echo "actual Script-> $script_name"
now=$(date +"%d/%m/%y-%H:%M:%S")
getDeviceResourcesState "$localDir/begin_state$script_index.json"
sleep 1
w_echo "starting profiling phase"
(adb shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "myfile")
sleep 3

w_echo "[Measuring]$now Running monkey tests..."

if [[ $trace == "-TestOriented" ]]; then
	adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value "1" -e com.quicinc.Trepn.UpdateAppState.Value.Desc "started"
fi 

#e_echo "monkeyrunner $script_name "\"$apk\"" "\"$package\"""
(monkeyrunner $script_name "$apk"  "$package" )

if [[ $trace == "-TestOriented" ]]; then
	adb shell am broadcast -a com.quicinc.Trepn.UpdateAppState -e com.quicinc.Trepn.UpdateAppState.Value "0" -e com.quicinc.Trepn.UpdateAppState.Value.Desc "stopped"
fi
w_echo "stopped tests. "


echo "stopping running app"
sleep 1
adb shell am force-stop $package 

stopProfiler

getDeviceResourcesState "$localDir/end_state$script_index.json"
echo "cleaning app cache"
adb shell pm clear $package >/dev/null 2>&1
echo "stopping running app"
adb shell am force-stop $package 
exit 0



