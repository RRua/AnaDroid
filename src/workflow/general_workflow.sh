#!/bin/bash

source $ANADROID_PATH/src/settings/settings.sh
source $ANADROID_PATH/src/others/assureTestConditions.sh



saveOldRuns(){
	that_dir=$1
	($MV_COMMAND -f $(find "$that_dir" ! -path "$that_dir" ! -path "$that_dir/all" -maxdepth 1 | grep -v "oldRuns"  ) "$that_dir/oldRuns/" ) >/dev/null 2>&1
}

debug_echo(){
	DEBUG="FALSE" 
	if [[ "$DEBUG" == "TRUE" ]]; then
		e_echo "[DEBUG] $1"
	fi
}


registInstalledPackages(){
	stage=$1
	#echo  "$ANADROID_PATH/temp/${stage}_packages.log" 
	adb shell pm list packages > "$ANADROID_PATH/temp/${stage}_packages.log" 
}

getInstalledPackage(){
	 adb shell pm list packages > "$ANADROID_PATH/temp/temp_packages.log" 
	 echo "$(diff temp/start_packages.log  temp/temp_packages.log  | grep -E "^>" | tr -d '\r' | sed 's/.*package://g')" 
}


rebootAndUnlockPhone(){
	adb reboot
	sleep 60
	"$ANADROID_PATH/src/others/unlockPhone.sh" # exec command to unlock phone
}


uninstallInstalledPackagesDuringTest(){

	diff "$ANADROID_PATH/temp/start_packages.log" "$ANADROID_PATH/temp/end_packages.log" | grep -E "^>" | tr -d '\r' | sed 's/.*package://g' | xargs -I{} adb shell pm uninstall {}
}


logInstalledAPKVersionInfo(){
	installed_package=$1
	target_file=$2
	result_version=$(adb shell dumpsys package "$installed_package" | grep -E "versionName=" | sed 's/versionName=//g' | tr -d '[:space:]' )
	echo "$result_version" > "$target_file"

}

setup(){
	if [ "$trace" == "testoriented" ]; then
		echo "-TestOriented"
	elif [ "$trace" == "methodriented" ]; then
		#statements
		echo "-MethodOriented"
	elif [ "$trace" == "activityoriented" ]; then
		#statements
		echo "-ActivityOriented"
	else
		echo "-TestOriented"
	fi
}


isNetworkError(){
	has_net=$(curl -Is http://www.google.com | head -1 | grep "HTTP/1.1 200 OK")
	if [[ -n "$has_net" ]]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}


waitForNetworkReconnection(){
	times_to_wait=10
	sleep_interval=5
	net_error=$(isNetworkError)
	for (( i = 0; i < $times_to_wait &&  "$net_error" == "TRUE" ; i++ )); do
		sleep $sleep_interval
		net_error=$(isNetworkError)
		machine=''
		getSO machine
		if [ "$machine" == "Mac" ]; then
			echo "TODO recover from network error"
		else
			echo " my sudo password " | sudo -S service network-manager restart
		fi
		sleep $sleep_interval
	done
}


checkIfErrorIsRecoverable(){
	ok=""
	net_error=$(isNetworkError)
	if [[ "$net_error" == "TRUE" ]]; then
		waitForNetworkReconnection
		net_error=$(isNetworkError)
		if [[ "$net_error" == "TRUE" ]]; then
			echo "FALSE"
		else 
			echo "TRUE"
		fi
	fi

}


checkIfIdIsReservedWord(){  #historic reasons
	if [ "$ID" == "success" ] || [ "$ID" == "failed" ] || [ "$ID" == "unknown" ]; then	
		continue
	fi
}


cleanDeviceTrash() {
	adb shell rm -rf "$deviceDir/allMethods.txt" "$deviceDir/TracedMethods.txt" "$deviceDir/Traces/*" "$deviceDir/Measures/*" "$deviceDir/TracedTests/*"
}

isAppInstalled(){
	appPackage=$1
	all_packages=$(adb shell pm list packages)
	isInstalled=$( echo $all_packages | grep "$appPackage" | head -1 )
	if [ "$appPackage" != "$isInstalled" ]; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}

isProfilingWithTrepn(){
	profiler=$1
	if [ -n "$(echo $profiler | grep "trepn")" ]; then
		echo "TRUE"
	elif [ -n "$(echo $profiler | grep "both")" ]; then
		echo "TRUE"
	elif [ -n "$(echo $profiler | grep "all")" ]; then
		echo "TRUE"
	else
		echo "FALSE"
	fi
}

isProfilingWithGreenscaler(){
	profiler=$1
	if [ -n "$(echo $profiler | grep "greenscaler")" ]; then
		echo "TRUE"
	elif [ -n "$(echo $profiler | grep "both")" ]; then
		echo "TRUE"
	elif [ -n "$(echo $profiler | grep "all")" ]; then
		echo "TRUE"
	else
		echo "FALSE"
	fi
}

getDeviceResourcesState(){
	resState=$1
	# hree numbers represent averages over progressively longer periods of time (one, five, and fifteen minute averages),
	used_cpu=$(adb shell dumpsys cpuinfo | grep  "Load" | cut -f2 -d: | sed 's/ //g' )
	#used_mem=$(adb shell dumpsys meminfo | grep "Free RAM.*" | cut -f2 -d: | cut -f1 -d\( | tr -d ' '| sed "s/K//g" | sed "s/,//g")
	local mem=$(adb shell dumpsys meminfo | grep "Used RAM.*" ) #| cut -f2 -d: | cut -f1 -d\( | tr -d ' ' ) #| sed "s/K//g" | sed "s/,//g")
	used_mem_pss=$( echo "$mem" |  cut -f2 -d\(   | cut -f1 -d+ | cut -f1 -d\   )
	used_mem_kernel=$(echo "$mem" |  cut -f2 -d\(   | cut -f2 -d+     |  sed 's/kernel)//g' | sed 's/ //g' )
	#nprocesses=$(adb shell top -n 1 |  wc -l) #take the K/M and -4
	#nr_procceses=$(($nprocesses -6))
	nr_procceses=$( adb shell ps -o STAT  | egrep "^R|L" | wc -l | sed 's/ //g') # get processes running or with pages in memory
	#sdk_level=$(adb shell getprop ro.build.version.release)
	local battery=$(adb shell dumpsys battery)
	#echo "battery -> $battery"
	ischarging=$( echo $battery | grep "powered" |  grep "true" | wc -l | sed 's/ //g')
	battery_level=$(echo "$battery" | grep "level:" | cut -f2 -d\: | sed "s/ //g")
	battery_temperature=$(echo "$battery" | grep "temperature:" | cut -f2 -d\: | sed "s/ //g")
	battery_voltage=$(echo "$battery" | grep "voltage:" | tail -1 | cut -f2 -d\: | sed "s/ //g")
	echo "
	{
		\"used_cpu\": \"$used_cpu\",
		\"used_mem_pss\": \"$used_mem_pss\", 
		\"used_mem_kernel\": \"$used_mem_kernel\", 
		\"nr_procceses\": \"$nr_procceses\", 
		\"ischarging\": \"$ischarging\", 
		\"battery_level\": \"$battery_level\", 
		\"battery_temperature\": \"$battery_temperature\",
		\"battery_voltage\": \"$battery_voltage\"
	}" > "$resState"
}




getDeviceSpecs(){
	devJson=$1
	DEVICE=$(adb devices -l  2>&1 | tail -2)
	#local device_model=$(   echo  $DEVICE  | grep -o "model.*" | cut -f2 -d: | cut -f1 -d\ )
	local device_model=$(adb shell getprop ro.product.model)
	local device_serial=$(   echo  $DEVICE | tail -n 2 | grep "model" | cut -f1 -d\ )
	local device_ram=$(adb shell cat /proc/meminfo | grep "MemTotal"| cut -f2 -d: | sed 's/ //g')
	local device_cores=$( adb shell cat /proc/cpuinfo | grep processor| wc -l | sed 's/ //g')
	local device_max_cpu_freq=$(adb shell cat /proc/cpumaxfreq )
	local device_brand=$(adb shell getprop ro.product.brand)
	#local device_brand=$(  echo  $DEVICE | grep -o "device:.*" | cut -f2 -d: )
	echo "
	{
		\"device_serial_number\": \"$device_serial\",
		 \"device_model\": \"$device_model\",
		 \"device_brand\": \"$device_brand\",
		 \"device_ram\": \"$device_ram\",
		 \"device_cores\": \"$device_cores\",
		 \"device_max_cpu_freq\": \"$device_max_cpu_freq\"
	}" > "$devJson"
	i_echo "📲  Attached device ($device_model) recognized "
	deviceDir="$deviceExternal/trepn"
	
}

getDeviceState(){
	statJson=$1
	# fields = ('state_id','state_os_version','state_miui_version', 
	#'state_api_version','state_device','state_keyboard',
	#'state_operator','state_operator_country')
	local soft_version=$(adb shell getprop ro.build.software.version)
	local ismi=$(test -z $(adb shell getprop ro.miui.cust_variant) && echo "true")
	if [ -z "$ismi"  ]; then
		local mi_version=$(adb shell getprop ro.miui.ui.version.name)
	else
		local mi_version=""
	fi
	local sdk_version=$(adb shell getprop ro.build.version.sdk)
	local device_keyboard=$(adb shell dumpsys  input_method | grep "mCurMethodId" | cut -f2 -d= )
	local operator=$(adb shell getprop gsm.sim.operator.alpha)
	local operator_country=$(adb shell getprop gsm.operator.iso-country)
	local conn_type=$(adb shell getprop gsm.network.type )
	local kernel_version=$(adb shell cat /proc/version)
	local device_serial=$(   echo  $DEVICE | tail -n 2 | grep "model" | cut -f1 -d\ )
	echo "
	{
		\"state_os_version\": \"$soft_version\",
		\"state_miui_version\": \"$mi_version\", 
		\"state_api_version\": \"$sdk_version\", 
		\"state_kernel_version\": \"$kernel_version\", 
		\"state_keyboard\": \"$device_keyboard\", 
		\"state_operator\": \"$operator\", 
		\"state_operator_country\": \"$operator_country\",
		\"state_device_id\": \"$device_serial\"
	}" > "$statJson"
}



checkBuildingTool(){
	GRADLE=($(find "${f}/${prefix}" -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
	POM=$(find "${f}/${prefix}" -maxdepth 1 -name "pom.xml")
	if [ -n "$POM" ]; then
		POM=${POM// /\\ }
		#e_echo "Maven projects are not considered yet..."
		echo "Maven"
		continue
	elif [ -n "${GRADLE[0]}" ]; then
		#statements
		echo "Gradle"
	else 
		echo "Eclipse"
	fi
}

countSourceCodeLines(){
	project_dir=$1
	scc "$project_dir" > "${project_dir}/cloc.out"	

}

getBattery(){
	battery_level=$(adb shell dumpsys battery | grep -o "level.*" | cut -f2 -d: | grep -E -o "[0-9]+" )
	limit=20
	if [ "$battery_level" -le "$limit" ]; then
		echo "battery level below ${limit}%. Sleeping again"
		sleep 300 # sleep 5 min to charge battery
	fi
}




assureConfiguredTestConditions(){
	w_echo "Assuring defined test conditions"
	assureTestConditions
}


# define test conditions according to the permissions declared in manifest file
defineTestConfigurations(){
	w_echo "Infering test conditions"
	app_permissions_file=$1
	test -f "$app_permissions_file" && python  "$ANADROID_PATH/src/others/defineTestConditions.py" "$(realpath $app_permissions_file)"
	
}

#used_cpu free_mem nr_procceses sdk_level api_level battery_temperature battery_voltage
#tempDir="$ANADROID_PATH/temp"
#getDeviceSpecs "$tempDir/devSpecs.json"
#getDeviceState "$tempDir/deviceState.json"
#getDeviceResourcesState "$tempDir/devResState.json"




