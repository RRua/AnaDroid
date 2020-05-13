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



buildMonkeyTestCommand(){
	#e_echo "($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-crashes --ignore-security-exceptions --throttle 10 $monkey_nr_events) &> $localDir/monkey.log"
	mkey_command="($TIMEOUT_COMMAND -s 9 $TIMEOUT adb shell monkey  -s $monkey_seed -p $package -v --pct-syskeys 0 --ignore-security-exceptions --throttle 100 $monkey_nr_events) &> $localDir/monkey.log" 
	##################
}

buildMonkeyTestCommand
python "$ANADROID_PATH/src/profilers/greenScaler/GreenScaler/greenscaler.py" "$package" $mkey_command
RET=$?
e_echo "retorno = $RET"


exit 0

