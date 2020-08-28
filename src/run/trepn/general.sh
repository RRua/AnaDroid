

initTrepnProfiler(){
	w_echo "starting the profiler"
	adb shell monkey -p com.quicinc.trepn -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
	sleep 1
	(adb shell am startservice --user 0 com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
	sleep 2
	(adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME) > /dev/null 2>&1
	sleep 3
	e_echo "nao fiz load do ficheiro de prefs !! "   # > /dev/null 2>&1
	#(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/All.pref") >/dev/null 2>&1
	sleep 3
}


stopTrepnProfiler(){
	#echo "stopping profiler..."
	sleep 10
	(adb shell am broadcast -a com.quicinc.trepn.stop_profiling) >/dev/null 2>&1
	sleep 10
	(adb shell am broadcast -a  com.quicinc.trepn.export_to_csv -e com.quicinc.trepn.export_db_input_file "myfile" -e com.quicinc.trepn.export_csv_output_file "GreendroidResultTrace0" ) >/dev/null 2>&1
	#(adb shell am broadcast -a  com.quicinc.trepn.export_to_csv -e com.quicinc.trepn.export_csv_output_file "GreendroidResultTrace0" ) #>/dev/null 2>&1
	sleep 20
	#getDeviceResourcesState "$localDir/end_state$monkey_seed.json"
	
}

clearLogCat(){
	adb logcat -c
}

dumpLogCatToFile(){
	adb logcat -d > "catlog.out"
}





grantPermissions(){
	package=$1
	adb shell pm grant $package android.permission.WRITE_EXTERNAL_STORAGE
	adb shell pm grant $package android.permission.READ_EXTERNAL_STORAGE
}

gracefullyQuitApp(){
	## essentiall to make foreground activity call ondestroy()
	n_times=10
	x=1
	while [ $x -le $n_times ];do
		#press back button
		adb shell input keyevent 4
		x=$(( $x + 1 ))
	done

}

getForegroundApp(){
	#foregroundApp=$(adb shell dumpsys window windows | grep -E 'mCurrentFocus' | cut -d '/' -f1 | sed 's/.* //g')
	foregroundApp=$(adb shell dumpsys activity recents | grep 'Recent #0' | cut -d= -f2 | sed 's| .*||' | cut -d '/' -f1)
	echo "$foregroundApp"
}

cleanAppCache(){
	package=$1
	echo "cleaning app cache"
	adb shell pm clear $package >/dev/null 2>&1
}



setImmersiveMode(){
	package=$1
	w_echo "setting immersive mode"
	adb shell settings put global policy_control immersive.full=$package
}

stopAndCleanApp(){
	package=$1
	adb shell am force-stop $package >/dev/null 2>&1
	adb shell pm clear $package >/dev/null 2>&1
}


#set brightness to lowest possible 
#adb shell settings put system screen_brightness_mode 0 
#adb shell settings put system screen_brightness 150 #  0 <= b <=255



