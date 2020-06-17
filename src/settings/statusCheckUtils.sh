# !/bin/bash

hasInternetConnection(){
	if nc -zw1 google.com 443; then
  		echo "TRUE"
	else
		echo "FALSE"
	fi
}

hasADBConnection(){
	adb_ok=$( adb get-state 1 > /dev/null 2>&1 && echo 'OK' || echo 'no device attached')
	if [[ "$adb_ok" == "OK" ]]; then
			#other required tools only load when device boots
			#while adb is loaded before, pm and other tools might not be available e.g in recovery mode
			# this is to ennsure that device is connected AND running properly
		fully_working=$(adb shell pm > /dev/null )
		if [[ -z "$fully_working" ]]; then
			echo "TRUE"
		fi
	else
		
	fi	
}

hasADBConnection