# !/bin/bash


################################################################################
####																		####
####	WARNING: Most of these functions are device or platform				####
#### 	dependent. These ones are suited for NEXUS 5 running android 6.0.1 	####
####																		####
################################################################################

function setBrightness(){
	local level=$1
	
		adb shell settings put system screen_brightness_mode 1
	
		#adb shell settings put system screen_brightness_mode 0
	
	adb shell settings put system screen_brightness "$level"
}


function getBrightness(){
	local level=$1
	adb shell settings get system screen_brightness | grep -E -o "[0-1]"
}



### WIFI 

function isWifiOn(){
	state=$(adb shell settings get global wifi_on| grep -E -o "[0-1]" )
	
	if [[ "$state" == "0" ]]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}

function changeWifiState(){
	local new_state=$1
	if [[ "$new_state" == "0" ]]; then
		adb shell su -c 'svc wifi disable'
	else
		adb shell su -c 'svc wifi enable'
	fi
}

### SCREEN

function isScreenUnlocked(){
	is_awake=$(adb shell dumpsys power | grep "mWakefulness=" | cut -f2 -d= | grep "Awake" )
	is_dreaming=$(adb shell dumpsys window | grep "mDreamingLockscreen=true" | sed 's/ //g' )
	if [ -z "$is_awake" ] || [ -n "$is_dreaming" ]  ; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}

# WHEN phone locked without password
function unlockScreen(){
	echo "unlockin"
	# try first with KEYCODE_MENU
	adb shell input keyevent 82 # KEYCODE_MENU
	unlocked=$(isScreenUnlocked)
	if [ "$unlocked" == "TRUE" ]; then
		# if still unlocked
		#adb shell input keyevent 26 #Pressing the lock button
		adb shell input touchscreen swipe 930 880 930 380 #Swipe UP
		#adb shell input keyevent 66 #Pressing Enter
	fi
}

function lockScreen(){
	adb shell input keyevent 26 #Pressing the lock button	
}


### BLUETOOTH 

function isBluetoothOn(){
	local blue_on=$(adb shell settings get global bluetooth_on | grep -E -o "[0-1]")
	if [[ "$blue_on" == "0" ]]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}

function changeBluetoothState(){
	local new_state=$1
	if [[ "$new_state" == "0" ]]; then
		adb shell su -c "pm disable  com.android.bluetooth"
	else
		adb shell su -c "pm enable com.android.bluetooth"
		adb shell su -c "service call bluetooth_manager 6"
	fi
}

### HOTSPOT 

function isHotspotOn(){
	# TODO hotspot_on1 is only true when tethering and working properly
	local hotspot_on1=$(adb shell dumpsys wifi | grep "curState=TetheredState"  | grep -E "[A-Za-z]")
	local hotspot_on2=$(adb shell dumpsys wifi | grep "curState=ApEnabledState" | grep -E "[A-Za-z]")
	if [ -n "$hotspot_on1" ] || [ -n "$hotspot_on2" ]  ; then
		echo "TRUE"
	else
		echo "FALSE"
	fi
}

function changeHotspotState(){
	local new_state=$1
	if [[ "$new_state" == "0" ]]; then
		adb shell su -c "pm disable  com.android.bluetooth"
	else
		adb shell su -c "pm enable com.android.bluetooth"
		adb shell su -c "service call bluetooth_manager 6"
	fi
}

### SPEAKER

function isSpeakerEnabled(){
	local is_speaker_on=$(adb shell dumpsys audio | grep "STREAM_SYSTEM:" -A 1 | grep "false")
	if [ -z "$is_speaker_on" ]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi	
}

function changeSpeakerState(){
	adb shell input keyevent 164 # 164 KEYCODE_VOLUME_MUTE https://developer.android.com/reference/android/view/KeyEvent.html#KEYCODE_VOLUME_MUTE
}


### GPS 
function isGPSEnabled(){
	local is_gps_on=$(adb shell settings get secure location_providers_allowed | grep "gps" )
	if [ -z "$is_gps_on" ]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi	
}

function changeGPSState(){
	local new_state=$1
	if [ "$new_state" == "0" ]; then
		adb shell settings put secure location_providers_allowed -gps
	else
		adb shell settings put secure location_providers_allowed +gps
	fi	
}

### NFC

function isNFCEnabled(){
	local is_nfc_on=$(adb shell dumpsys nfc | grep "mState=on" )
	if [ -z "$is_nfc_on" ]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi	
}

function changeNFCState(){
	local new_state=$1
	if [ "$new_state" == "0" ]; then
		adb shell svc nfc disable
	else
		adb shell svc nfc enable
	fi	
}

x='''function testAllFunctions(){
	is_enabled=$(isGPSEnabled)
	if [[ "$is_enabled" == "TRUE" ]]; then
		echo "Ligado"
		changeGPSState "0" && sleep 5 && ( "$(isGPSEnabled)" == "FALSE" ) && echo "GPS functions working ok"

	else
		echo "DESLIGADO"
		changeGPSState "1" && "$(isGPSEnabled)" == "TRUE" && echo "GPS functions working ok"
	fi
	
	#(test "$is_enabled" == "FALSE" && changeGPSState "1" && "$(isGPSEnabled)" == "TRUE" && echo "GPS functions working ok") 
}'''



loadStateFromConfigFile(){
	config_id=$1
	config_file=$ANADROID_PATH/testConfig.cfg
	echo $(grep "$1" testConfig.cfg | cut -f2  -d\= | cut -f1 -d# )

}


assureTestConditions(){
	
	#screen lock
	expectable_screen_state=$(loadStateFromConfigFile "screen_state" )
	is_on=$(isScreenUnlocked)
	test "$expectable_screen_state" = "0" && test "$is_on" = "TRUE"  && echo  "changing screen state" && lockScreen
	test "$expectable_screen_state" = "1" && test "$is_on" = "FALSE" && echo  "changing screen state" && unlockScreen
	# screen brightness
	expectable_brightness=$(loadStateFromConfigFile "screen_brightness" )
	setBrightness $expectable_brightness
	# wifi
	expectable_wifi_state=$(loadStateFromConfigFile "wifi_state" )
	iswifi_on=$(isWifiOn)
	test "$expectable_wifi_state" = "0" && test $iswifi_on = "TRUE" && echo  "changing wifi state" && changeWifiState "0" # if it was supposed to be off, turn off
	test "$expectable_wifi_state" = "1" && test $iswifi_on = "FALSE" && echo  "changing wifi state" &&  changeWifiState "1" # if it was supposed to be on, turn on

	# bluetooth
	expectable_bluetooth_state=$(loadStateFromConfigFile "bluetooth_state" )
	is_blue_on=$(isBluetoothOn)
	test "$expectable_bluetooth_state" = "0" && test  "$is_blue_on" = "TRUE" && echo  "changing bluetooth state" && changeBluetoothState "0" # if it was supposed to be off, turn off
	test "$expectable_bluetooth_state" = "1" && test "$is_blue_on" = "FALSE" && echo   "changing bluetooth state" && changeBluetoothState "1" # if it was supposed to be on, turn on
	# hotspot
	expectable_hotspot_state=$(loadStateFromConfigFile "hotspot_state" )
	is_on=$(isHotspotOn)
	test "$expectable_hotspot_state" = "0" && test "$is_on" = "TRUE" &&  echo   "changing hotspot state" && changeHotspotState "0" # if it was supposed to be off, turn off
	test "$expectable_hotspot_state" = "1" && test "$is_on" = "FALSE" &&  echo  "changing hotspot state" && changeHotspotState "1" # if it was supposed to be on, turn on
	# speaker
	expectable_speaker_state=$(loadStateFromConfigFile "speaker_state" )
	is_on=$(isSpeakerEnabled)
	test "$expectable_speaker_state" = "0" && test "$is_on" = "TRUE" &&  echo  "changing speaker state" &&  changeSpeakerState "0" # if it was supposed to be off, turn off
	test "$expectable_speaker_state" = "1" && test "$is_on" = "FALSE" &&  echo   "changing speaker state" && changeSpeakerState "1" # if it was supposed to be on, turn on
	# gps
	expectable_gps_state=$(loadStateFromConfigFile "gps_state" )
	is_on=$(isGPSEnabled)
	test "$expectable_gps_state" = "0" && test "$is_on" = "TRUE" && echo   "changing gps state" && changeGPSState "0" # if it was supposed to be off, turn off
	test "$expectable_gps_state" = "1" && test "$is_on" = "FALSE" &&  echo   "changing gps state" && changeGPSState "1" # if it was supposed to be on, turn on
	# nfc
	expectable_nfc_state=$(loadStateFromConfigFile "nfc_state" )
	is_on=$(isNFCEnabled)
	test "$expectable_nfc_state" = "0" && test "$is_on" = "TRUE" &&  echo  "changing nfc state" &&  changeNFCState "0" # if it was supposed to be off, turn off
	test "$expectable_nfc_state" = "1" && test "$is_on" = "FALSE" &&  echo  "changing nfc state" && changeNFCState "1" # if it was supposed to be on, turn on


}


