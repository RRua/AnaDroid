#!/bin/bash
source src/settings/settings.sh
source $SDKMAN_DIR/bin/sdkman-init.sh
TAG="[ANADROID CONFIG]"
#1 install java 8 ou 9
#2 download sdkman (or manually install sdk)
#3 set android home
#4 install gradle? (via sdkman or brew)
#5 install coreutils (brew install coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep)

hasJava(){
	tool_name="Java"
	com="java -version"
	command_to_check=$( $com 2>&1)
	exists=$(echo $command_to_check | grep "command not found")
	#original_tool=$(echo $com | cut -f1 -d\ )
	if [[ ! -n $exists ]]; then
		#tool exists
		i_echo "$TAG $tool_name Exists"
		version=$(echo $command_to_check | cut -f2 -d\" | cut -f2 -d.)
		if [ $version -ge 8 ]; then
			#statements
			i_echo "$TAG $tool_name Actual Version $version suits well"
		else
			e_echo "Before using ANADROID, you should update your java to version above 7"
		fi
	else
		e_echo "$TAG $tool_name doesn't exist"
		exit -1
	fi
}
hasSdkman(){
	tool_name="Sdkman"
	com="sdk -help"
	command_to_check=$($com 2>&1)
	exists=$(echo $command_to_check | grep "command not found")
	#original_tool=$(echo $com | cut -f1 -d\ )
	if [[ ! -n $exists ]]; then
		#tool exists
		i_echo "$TAG $tool_name Exists"
	else
		w_echo "$TAG $tool_name doesn't exist. Installing..."
		x=$(curl -s https://get.sdkman.io | bash)
		source $SDKMAN_DIR/bin/sdkman-init.sh
		i_echo "$TAG $tool_name Installed"
	fi
}
hasAndroidSDK(){
	tool_name="ANDROID SDK"
	URL="https://developer.android.com/studio/#downloads"
	URL_DOWNLOAD="https://dl.google.com/android/repository/sdk-tools-darwin-4333796.zip"
	command_to_check=$( echo $ANDROID_HOME )
	exists=$(echo $command_to_check | grep "ndroid")
	#original_tool=$(echo $com | cut -f1 -d\ )
	if [[ ! -z $exists ]]; then
		#tool exists
		i_echo "$TAG $tool_name Exists"
	else
		e_echo "$TAG $tool_name doesn't exist. You can download it in:"
		echo "$URL"
		e_echo " You also must set the ANDROID_HOME environment variable"
		exit -1
	fi
}
hasGradle(){
	tool_name="Gradle"
	command_to_check=$( gradle -version 2>&1 )
	exists=$(echo $command_to_check | grep "command not found")
	#original_tool=$(echo $com | cut -f1 -d\ )
	if [[ ! -n $exists ]]; then
		#tool exists
		i_echo "$TAG $tool_name Exists"
	else
		e_echo "$TAG $tool_name doesn't exist. Downloading gradle with sdkman"
		#sdkman install gradle
	fi
}

hasCoreUtils(){
	Machine=$1
	if [ "$Machine" == "Mac" ]; then
		brew install coreutils 	
	fi
}



MACHINE=""
getSO MACHINE
i_echo "$TAG Running on $MACHINE OS"
hasCoreUtils
hasJava
hasAndroidSDK
hasSdkman
hasGradle
