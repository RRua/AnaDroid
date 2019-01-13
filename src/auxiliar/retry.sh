#!/bin/bash
source settings.sh
#Use after instrument app


machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
else 
	SED_COMMAND="sed" #linux	
fi


deviceDir="sdcard/trepn"
AppDir=$(cat lastTranformedApp.txt)
GD_ANALYZER="jars/Analyzer.jar"  # "analyzer/greenDroidAnalyzer.jar"

#clean localdir
rm -rf $localDir/*csv
rm -rf $localDir/all/*.txt
#clean deviceDir
adb shell rm -rf "$deviceDir/Measures/*txt"
adb shell rm -rf "$deviceDir/Traces/*txt"
#run tests via gradle wrapper
chmod +x $AppDir/gradlew
cd $AppDir ; $AppDir/gradlew cAT 
localDir= "$HOME/GDresults/retrys"
i_echo "$TAG Pulling result files"

#check if everything worked correctly
Nmeasures=$(adb shell ls "$deviceDir/Measures/" | wc -l)
Ntraces=$(adb shell ls "$deviceDir/Traces/" | wc -l)
echo "Nº measures: $Nmeasures "
echo "Nºtraces:    $Ntraces "
if [ $Nmeasures -le "0" ] || [ $Ntraces -le "0" ] || [ $Nmeasures -ne $Ntraces ] ; then 
	e_echo "[GD ERROR] Something went wrong. Try restart trepn (and delete .db and state files in trepn folder) or check GDflag"
fi

echo $localDir
adb shell ls "$deviceDir/Measures/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/Measures/{} $localDir
#adb shell ls "$deviceDir/TracedMethods.txt" | tr '\r' ' ' | xargs -n1 adb pull 
adb shell ls "$deviceDir/Traces/" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.txt" | xargs -I{} adb pull $deviceDir/Traces/{} $localDir
 
