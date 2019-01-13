#!/bin/bash
source settings.sh

pack=$1
testPack=$2
deviceDir=$3
localDir=$4
folderPrefix=$5
appFolder=$6
#echo "ui ui olha o prefix  $folderPrefix"
machine=''
getSO machine
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


actualrunner=$(grep "JUnitRunner" actualrunner.txt)
if [[ -n "$actualrunner" ]]; then
	runner="android.support.test.runner.AndroidJUnitRunner"
else
	runner="android.test.InstrumentationTestRunner"
fi

rm -rf $localDir/*.csv
w_echo "$TAG using runner with $runner"

w_echo "$TAG Running the tests (Measuring)"
adb shell "echo 1 > $deviceDir/GDflag"
($Timeout_COMMAND -s 9 $TIMEOUT adb shell am instrument -w $testPack/$runner) &> runStatus.log

missingInstrumentation=$(grep "Unable to find instrumentation info for" runStatus.log)
flagInst="0"
if [[ -n "$missingInstrumentation" ]]; then
	# Something went wrong during instalation and run. 
	# Let's try running all existing instrumentations (should not be bigger than one)
	flagInst="1"
	#adb shell "pm list instrumentation"
	allInstrumentations=($(adb shell pm list instrumentation | cut -f2 -d: | cut -f1 -d\ ))
	echo "instrumenting"
	echo "$allInstrumentations"
	if [[ "${#allInstrumentations[@]}" -ge "1" ]]; then
		for i in ${allInstrumentations[@]}; do
			($Timeout_COMMAND -s 9 $TIMEOUT adb shell am instrument -w $i) &> runStatus.log
			RET=$(echo $?)
			if [[ "$RET" != 0 ]]; then
				./forceUninstall.sh
				exit -1
			fi
		done
	else
		e_echo "$TAG Wrong number of instrumentations: Found ${#allInstrumentations[@]}, Expected 1."
	fi
fi

#Stop the app, if it is still running
adb shell am force-stop $pack
adb shell am force-stop $testPack
adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1

w_echo "$TAG Running the tests (Tracing)"
adb shell "echo -1 > $deviceDir/GDflag"

if [[ "$flagInst" == 1 ]]; then
	allInstrumentations=($(adb shell pm list instrumentation | cut -f2 -d: | cut -f1 -d\ ))
	if [[ "${#allInstrumentations[@]}" -ge "1" ]]; then
		for i in ${allInstrumentations[@]}; do
			$Timeout_COMMAND -s 9 $TIMEOUT adb shell am instrument -w $i &> runStatus.log
			RET=$(echo $?)
			if [[ "$RET" != 0 ]]; then
				./forceUninstall.sh
				exit -1
			fi
		done
	else
		e_echo "$TAG Wrong number of instrumentations: Found ${#allInstrumentations[@]}, Expected 1."
	fi
else
	$Timeout_COMMAND -s 9 $TIMEOUT adb shell am instrument -w $testPack/$runner &> runStatus.log
fi
adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1


# TODO: Include output check from 'adb shell instrument' to assert that the tests were actually executed.

i_echo "$TAG Pulling result files"
#check if trepn worked correctly
Nmeasures=$(adb shell ls "$deviceDir/Measures/" | wc -l)
Ntraces=$(adb shell ls "$deviceDir/Traces/" | wc -l)
echo "Nº measures: $Nmeasures"
echo "Nº traces:   $Ntraces"

if [[ $folderPrefix == "Method" ]]; then
	#statements
	adb shell mv "$deviceDir/*.csv" "$deviceDir/Measures/"
else 
    if [ $Nmeasures -le "0" ] || [ $Ntraces -le "0" ] || [ $Nmeasures -ne $Ntraces ] ; then 
		e_echo "[GD ERROR] Something went wrong. try run trepnFix.sh and try again"
		exit 2
	fi
fi

now=$(date +"%d_%m_%y_%H_%M_%S")
localDir=$localDir/$ID/$folderPrefix$now
echo "$TAG Creating support folder..."
$MKDIR_COMMAND -p $localDir
$MKDIR_COMMAND -p $localDir/all
#cat ./ethods.txt >> $localDir/all/allMethods.txt
cp $appFolder/application.json $localDir
cp device.json $localDir
cp $appFolder/appPermissions.json $localDir

adb shell ls "$deviceDir/Measures/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/Measures/{} $localDir
#adb shell ls "$deviceDir/TracedMethods.txt" | tr '\r' ' ' | xargs -n1 adb pull 
adb shell ls "$deviceDir/Traces/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.txt" | xargs -I{} adb pull $deviceDir/Traces/{} $localDir
adb shell ls "$deviceDir/TracedTests/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.txt" | xargs -I{} adb pull $deviceDir/TracedTests/{} $localDir

csvs=$(find $localDir -name "*.csv")
for i in $csvs; do
	tags=$(cat $i |  grep "stopped" | wc -l)
	if [ $tags -lt "2" ] && [ "$folderPrefix" == "Test" ] ; then
		e_echo " $i might contain an error "
		echo "$i" >> logs/csvErrors.log
	fi
done


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
