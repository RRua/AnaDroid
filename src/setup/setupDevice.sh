#!/bin/bash
source settings.sh
TAG="[SETUP]"

# GLOBAL
APKS_DIR="apks/"
# TREPN
TREPN_PREFERENCES_DESTINATION_DIR="saved_preferences/"
TREPN_PREFERENCES_DIR="trepnPreferences/"
TREPN_DIR="trepn/"

# STEPS
# install trepn
# cp preferences
# install simiasque
getTrepnAPK(){
	apk=$(find $APKS_DIR -name "*trepn*.apk")
	eval "$1='$apk'"
}

getSimiasqueAPK(){
	apk=$(find $APKS_DIR -name "*simiasque*.apk")
	eval "$1='$apk'"
}

getDeviceExternalStorage(){
	deviceExternal=$(adb shell 'echo -n $EXTERNAL_STORAGE' 2>&1)
	errors=$(echo $deviceExternal| grep "error:")
	if [ -n "$errors" ]; then
		e_echo "$TAG Could not determine the device's external storage. Check the connection and try again... \n"
		exit -1
	
	else
		device_model=$(  adb devices -l | grep -o "model.*" | cut -f2 -d: | cut -f1 -d\ )
		i_echo "$TAG 📲  Attached device ($device_model) recognized "
		eval "$1='$deviceExternal'"
	fi
}
# $1 must be the external storage (e.g sdcard)
setupTrepnOnDevice(){
	FULL_TREPN_DIR=$1/$TREPN_DIR
	(adb shell mkdir -p $FULL_TREPN_DIR/$TREPN_PREFERENCES_DESTINATION_DIR)
	(adb push trepnPreferences/ $FULL_TREPN_DIR/$TREPN_PREFERENCES_DESTINATION_DIR) > /dev/null  2>&1 
	w_echo "$TAG Pushed Trepn Preferences"
	(adb shell mkdir $FULL_TREPN_DIR) > /dev/null  2>&1
	(adb shell mkdir $FULL_TREPN_DIR/Traces) > /dev/null  2>&1
	(adb shell mkdir $FULL_TREPN_DIR/Measures) > /dev/null  2>&1
	(adb shell mkdir $FULL_TREPN_DIR/TracedTests) > /dev/null  2>&1
	w_echo "$TAG Created Auxiliary directories"
}

installTrepn(){
	w_echo "$TAG installing Trepn Apk on the Connected Android Device ..." 
	install_res=$(adb install -r $1 )
	check_res=$(echo $install_res | grep "Success")
	if [[ -z "$check_res" ]]; then
		# error occured
		e_echo "An error occured while installing Trepn APK. You must enable the \"Install via USB\" option in the Programmer Options of the Android device"
	fi
}

installSimiasque(){
	w_echo "$TAG installing Simiasque Apk on the Connected Android Device ..." 
	install_res=$(adb install -r $1 )
	#check_res=$(echo $install_res | grep "Success")
	#if [[ -n "$check_res" ]]; then
		# error occured
	#	e_echo "An error occured while installing Simiasque APK. You must enable the \"Install via USB\" option in the Programmer Options of the Android device"
	#fi
}

i_echo "\n$TAG Setting up AnaDroid framework"
device_external_storage=""
getDeviceExternalStorage device_external_storage
trepnapk=""
getTrepnAPK trepnapk
#echo "$trepnapk"
simiasqueAPK=""
getSimiasqueAPK simiasqueAPK
#echo "$simiasqueAPK"
installTrepn $trepnapk
setupTrepnOnDevice $device_external_storage
installSimiasque $simiasqueAPK



