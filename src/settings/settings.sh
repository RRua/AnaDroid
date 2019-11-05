#!/bin/bash


function w_echo {
	echo -e "$yellow_$1$rc_"
}

function i_echo {
	echo -e "$greenB_$1$rc_"
}

function e_echo {
	echo -e "$red_$1$rc_"
}
function b_echo {
	echo -e "$blue_$1$rc_"
}




printf_new() {
     str=$1
     num=$2
     local v=$(printf "%-${num}s" "$str")
     i_echo "${v// /#}"
}

function getAndroidState(){
	used_cpu=$(adb shell dumpsys cpuinfo | grep  "Load" | cut -f2 -d\ )
	free_mem=$(adb shell dumpsys meminfo | grep "Free RAM.*" | cut -f2 -d: | cut -f1 -d\( | tr -d ' '| sed "s/K//g" | sed "s/,//g")
	nprocesses=$(adb shell top -n 1 | grep -v "root" | grep -v "system" | wc -l) #take the K/M and -4
	nr_procceses=$(($nprocesses -5))
	sdk_level=$(adb shell getprop ro.build.version.release)
	api_level=$(adb shell getprop ro.build.version.sdk )
	battery_level=$(adb shell dumpsys battery | grep "level:" | cut -f2 -d\: | sed "s/ //g")
	battery_temperature=$(adb shell dumpsys battery | grep "temperature:" | cut -f2 -d\: | sed "s/ //g")
	battery_voltage=$(adb shell dumpsys battery | grep "voltage:" | cut -f2 -d\: | sed "s/ //g")
	
	eval "$1='$used_cpu'"
	eval "$2='$free_mem'"
	eval "$3='$nr_procceses'"
	eval "$4='$sdk_level'"
	eval "$5='$api_level'"
}

function getSO(){
	unameOut="$(uname -s)"
	case "${unameOut}" in
		Linux*)     machine=Linux;;
		Darwin*)    machine=Mac;;
		CYGWIN*)    machine=Cygwin;;
		MINGW*)     machine=MinGw;;
		*)          machine="UNKNOWN:${unameOut}"
	esac
	eval "$1='$machine'"
}

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

if [ "$machine" == "Mac" ]; then
	#reset
	rc_="\033[m"
	#normal colors
	red_="\033[31m"
	green_="\033[32m"
	blue_="\033[36m"
	yellow_="\033[33;1m" # \[\033[33;1m\]
	#bold colors
	redB_="\033[31m\033[1m"
	greenB_="\033[32m\033[1m"
	yellowB_="\033[33m\033[1m"
	#b_echo "OS of Host System : MAC OS"

elif [ "$machine" == "Linux" ]; then
	#echo "LINUX SYSTEM DETECTED"
	#reset
	rc_="\e[0m"
	#normal colors
	red_="\e[31m"
	green_="\e[32m"
	yellow_="\e[33m"
	#bold colors
	redB_="\e[31m\e[1m"
	greenB_="\e[32m\e[1m"
	yellowB_="\e[33m\e[1m"
	yellowB_="\e[33m\e[1m"
else
	#echo "UNKNOWN SYSTEM DETECTED"
	#reset
	rc_="\e[0m"
	#normal colors
	red_="\e[31m"
	green_="\e[32m"
	yellow_="\e[33m"
	#bold colors
	redB_="\e[31m\e[1m"
	greenB_="\e[32m\e[1m"
	yellowB_="\e[33m\e[1m"
fi

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
	nr_processes=$( adb shell ps -o STAT  | egrep "^R|L" | wc -l | sed 's/ //g') # get processes running or with pages in memory
	#sdk_level=$(adb shell getprop ro.build.version.release)
	local battery=$(adb shell dumpsys battery)
	#echo "battery -> $battery"
	ischarging=$( echo $battery | grep "powered" |  grep "true" | wc -l | sed 's/ //g')
	battery_level=$(echo "$battery" | grep "level:" | cut -f2 -d\: | sed "s/ //g")
	keyboard=$(adb shell dumpsys  input_method | grep "mCurMethodId" | cut -f2 -d= )
	battery_temperature=$(echo "$battery" | grep "temperature:" | cut -f2 -d\: | sed "s/ //g")
	battery_voltage=$(echo "$battery" | grep "voltage:" | tail -1 | cut -f2 -d\: | sed "s/ //g")
	timestamp=$(date +%s )
	echo "
	{	\"timestamp\": \"$timestamp\",
		\"used_cpu\": \"$used_cpu\",
		\"used_mem_pss\": \"$used_mem_pss\", 
		\"used_mem_kernel\": \"$used_mem_kernel\", 
		\"nr_processes\": \"$nr_processes\", 
		\"ischarging\": \"$ischarging\", 
		\"battery_level\": \"$battery_level\", 
		\"battery_temperature\": \"$battery_temperature\",
		\"keyboard\": \"$keyboard\", 
		\"battery_voltage\": \"$battery_voltage\"
	}" > "$resState"
}




getDeviceSpecs(){
	devJson=$1
	DEVICE=$(adb devices -l  2>&1 | tail -2)
	has_devices_conected=$(adb shell echo "" 2>&1 | grep "devices/emulators found")
	if [[ -n "$has_devices_conected" ]]; then
		e_echo " No Conected Devices found. Conect the device to the development machine and try again. Aborting..."
		exit -1
	fi
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
	local soft_version=$(adb shell getprop ro.build.software.version | sed "s/Android//g" | cut -f1 -d_)
	local ismi=$(test -z $(adb shell getprop ro.miui.cust_variant) && echo "true")
	if [ -z "$ismi"  ]; then
		local mi_version=$(adb shell getprop ro.miui.ui.version.name)
	else
		local mi_version=""
	fi
	local sdk_version=$(adb shell getprop ro.build.version.sdk)
	#local device_keyboard=$(adb shell dumpsys  input_method | grep "mCurMethodId" | cut -f2 -d= )
	local operator=$(adb shell getprop gsm.sim.operator.alpha)
	local operator_country=$(adb shell getprop gsm.operator.iso-country)
	local conn_type=$(adb shell getprop gsm.network.type )
	local kernel_version=$(adb shell cat /proc/version)
	local device_id=$(adb shell getprop ro.serialno )
	echo "
	{
		\"state_device_id\": \"$device_id\",
		\"state_os_version\": \"$soft_version\",
		\"state_miui_version\": \"$mi_version\", 
		\"state_api_version\": \"$sdk_version\", 
		\"state_kernel_version\": \"$kernel_version\", 
		\"state_operator\": \"$operator\", 
		\"state_operator_country\": \"$operator_country\"
	}" > "$statJson"
}

checkBuildingTool(){
	GRADLE=($(find ${f}/${prefix} -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
	POM=$(find ${f}/${prefix} -maxdepth 1 -name "pom.xml")
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


