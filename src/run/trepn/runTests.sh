#!/bin/bash
source $ANADROID_PATH/src/settings/settings.sh
this_dir="$(dirname "$0")"
source "$this_dir/general.sh"

logDir="$ANADROID_PATH/.ana/logs/"
pack=$1
testPack=$2
deviceDir=$3
localDir=$4
folderPrefix=$5
appFolder=$6
machine=""
getSO machine
nRuns=2
state="begin"
if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
	MKDIR_COMMAND="gmkdir"
	Timeout_COMMAND="gtimeout"
else 
	SED_COMMAND="sed" #linux
	MKDIR_COMMAND="mkdir"
	Timeout_COMMAND="timeout"	
fi
TIMEOUT="600" #15 minutes (60*10)

TAG="[APP RUNNER]"
execs=0

actualrunner=$(grep "JUnitRunner" $logDir/actualrunner.txt)
if [ -n "$actualrunner" ]; then
	runner="android.support.test.runner.AndroidJUnitRunner"
	#e_echo "actual runner -> $runner"
else
	runner="android.test.InstrumentationTestRunner"
	#e_echo "actual runner -> $runner"
fi

#rm -rf $localDir/*.csv
#w_echo "$TAG using runner with $runner"


#set brightness to lowest possible 
#adb shell settings put system screen_brightness_mode 0 
#adb shell settings put system screen_brightness 0 #  0 <= b <=255

grantPermissions(){
	w_echo "Granting permissions on $1"
	(adb shell pm grant $pack android.permission.READ_EXTERNAL_STORAGE) >/dev/null 2>&1
	(adb shell pm grant $pack android.permission.WRITE_EXTERNAL_STORAGE) >/dev/null 2>&1
	(adb shell pm grant "$pack.test" android.permission.WRITE_EXTERNAL_STORAGE) >/dev/null 2>&1
	(adb shell pm grant "$pack.test" android.permission.READ_EXTERNAL_STORAGE) >/dev/null 2>&1	
}

initProfiler(){
	w_echo "starting the profiler"
	adb shell monkey -p com.quicinc.trepn -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
	sleep 1
	(adb shell am startservice --user 0 com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
	sleep 2
	(adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME) > /dev/null 2>&1
	#sleep 3
	#e_echo "nao fiz load do dfichero de prefs !! " > /dev/null 2>&1
	#(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/All.pref") >/dev/null 2>&1
	#sleep 3
}



runTests(){
	state="begin"
	adb shell "echo $GDflag > $deviceDir/GDflag"
	clearLogCat
	#echo "sei la comando ($Timeout_COMMAND -s 9 $TIMEOUT adb shell am instrument -w $testPack/$runner) &> runStatus.log"
	($Timeout_COMMAND -s 9 $TIMEOUT adb shell am instrument -w "$testPack/$runner") &> runStatus.log
	#if went wrong
	missingInstrumentation=$(grep "Unable to find instrumentation info for" runStatus.log)
	flagInst="0"
	if [[ -n "$missingInstrumentation" ]]; then
		# Something went wrong during instalation or run. 
		flagInst="1"
		#adb shell "pm list instrumentation"
		allInstrumentations=($(adb shell pm list instrumentation | grep $pack  | cut -f2 -d: | cut -f1 -d\ ))
		echo " all : $allInstrumentations"
		if [[ "${#allInstrumentations[@]}" -ge "1" ]]; then
			for i in ${allInstrumentations[@]}; do
				hasPack=$(echo $i | grep $pack )
				if [ -n "$hasPack" ]; then
					($Timeout_COMMAND -s 9 $TIMEOUT adb shell am instrument -w $i) &> runStatus.log
					RET=$(echo $?)
					if [[ "$RET" != 0 ]]; then
						$ANADROID_SRC_PATH/others/forceUninstall.sh 
						
						exit -1
					fi
				fi
			done
		else
			e_echo "$TAG Wrong number of instrumentations: Found ${#allInstrumentations[@]}, Expected 1."
			#e_echo "bou abandonar2"
			state="end"
			exit -1
		fi
	fi
	dumpLogCatToFile
	execs=$(($execs + 1))
	state="end"

}

stopAndcleanTrash(){
	#Stop the app, if it is still running
	echo "cleaning app cache"
	adb shell pm clear $pack >/dev/null 2>&1	
	adb shell am force-stop $pack
	adb shell am force-stop $testPack
	adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1
}


pullResults(){
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
	cp "$appFolder/application.json" "$localDir"
	cp device.json "$localDir"
	cp "$appFolder/appPermissions.json" "$localDir"
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

stateToJSON(){
	State=$1
	#e_echo "$localDir/${State}_state.json"
	getDeviceResourcesState "$localDir/${State}_state.json"
	#getAndroidState cpu mem nr_processes sdk_level api_level
	#timestamp=$(date +%s )
	#e_echo "$state device state: CPU: $cpu % , MEM: $mem,proc running : $nr_processes sdk level: $sdk_level API:$api_level"
	#echo "{\"test_results_unix_timestamp\": \"$timestamp\", \"device_state_mem\": \"$mem\", \"device_state_cpu_free\": \"$cpu\",\"device_state_nr_processes_running\": \"$nr_processes\",\"device_state_api_level\": \"$api_level\",\"device_state_android_version\": \"$sdk_level\" }" > "$localDir/${state}_state${execs}.json"

}

#initProfiler

if [ $nRuns -eq 2 ]; then
	#run in measure and trace mode separately
	GDflag="-1"
	w_echo "$TAG Running the tests (Tracing mode)"
	#initSimiasque
	runTests
	stopAndcleanTrash
	GDflag="1"
	w_echo "$TAG Running the tests (Measuring mode)"
	stateToJSON "begin"
	grantPermissions
	runTests 
	stateToJSON "end"
	stopAndcleanTrash
	#stopSimiasque
	pullResults
else
	# run only once, in normal mode
	GDflag="0"
	w_echo "$TAG Running the tests (Measuring mode)"

	#initSimiasque
fi

(adb shell am stopservice com.quicinc.trepn/.TrepnService) # remove


# In case the missing instrumentation error occured, let's remove all apps with instrumentations now!
#« if [[ "$flagInst" == 1 ]]; then
#	instTests=($(adb shell pm list instrumentation | cut -f2 -d: | cut -f1 -d\ | cut -f1 -d/))
#	for i in ${instTests[@]}; do
#		a=${i/%.test/}
#		adb shell pm uninstall $a
#		adb shell pm uninstall $i
		
		#a=${i/%.tests/}
		#adb shell pm uninstall $a
#	done
# fi

exit 0
