#!/bin/bash
source src/settings/settings.sh
source $SDKMAN_DIR/bin/sdkman-init.sh
TAG="[ANADROID CONFIG]"
#1 install java 8 ou 9
#2 download sdkman (or manually install sdk)
#3 set android home
#4 install gradle? (via sdkman or brew)
#5 install coreutils (brew install coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep)


setHomeDir(){
	has_home_dir=$(echo $HOME)
	if [ -z "$has_home_dir" ]; then
		#needs to be set
		home_dir=$(" eval echo ~$USER")
		export HOME=$home_dir
	fi
}

installPython(){
	tool_name="Python"
	com="python --version"
	command_to_check=$( $com 2>&1)
	exists=$(echo $command_to_check | grep "command not found")
	#original_tool=$(echo $com | cut -f1 -d\ )
	if [[ ! -n $exists ]]; then
		#tool exists
		i_echo "$TAG $tool_name Exists"
		version=$(echo $command_to_check | cut -f2 -d\" | cut -f2 -d.)
	else
		#install java 
		e_echo "$TAG $tool_name doesn't exist. Downloading"
		Mac=""
		getSO Mac
		if [ "$Mac" == "Mac" ]; then
			echo "$TAG installing $tool_name on $Mac OS"
			brew install python
		else
			echo "$TAG installing $tool_name on $Mac OS"
			sudo apt install python
		fi
	fi
}

installJava(){
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
		#install java 
		e_echo "$TAG $tool_name doesn't exist. Downloading"
		Mac=""
		getSO Mac
		if [ "$Mac" == "Mac" ]; then
			echo "$TAG installing $tool_name on $Mac OS"
			brew cask install java8
		else
			echo "$TAG installing $tool_name on $Mac OS"
			sudo apt install openjdk-8-jdk
		fi
	fi
}
installSdkman(){
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
		has_curl=$(curl -h 2>&1)
		exists=$(echo $has_curl | grep "command not found")
		#original_tool=$(echo $com | cut -f1 -d\ )
		if [ -n "$exists" ]; then
			#curl doesnt exist
			Mac=""
			getSO Mac
			if [ "$Mac" != "Mac" ]; then
				echo "installing curl"
				sudo apt install curl
				echo "installing curl"
			fi
		fi
		x=$(curl -s https://get.sdkman.io | bash)
		SDKMAN_DIR=$HOME/.sdkman
		export SDKMAN_DIR=$HOME/.sdkman
		source $SDKMAN_DIR/bin/sdkman-init.sh
		i_echo "$TAG $tool_name Installed"
	fi
}
installAndroidSDK(){
	tool_name="ANDROID SDK"
	URL="https://developer.android.com/studio/#downloads"
	#URL_DOWNLOAD="https://dl.google.com/android/repository/sdk-tools-darwin-4333796.zip"
	command_to_check=$( echo $ANDROID_HOME )
	exists=$(echo $command_to_check | grep "ndroid")
	#original_tool=$(echo $com | cut -f1 -d\ )
	if [[ ! -z $exists ]]; then
		#tool exists
		i_echo "$TAG $tool_name Exists"
	else
		e_echo "$TAG $tool_name doesn't exist. You can download it in:"
		Mac=""
		getSO Mac
		if [ "$Mac" == "Mac" ]; then
			w_echo "https://dl.google.com/android/repository/sdk-tools-darwin-4333796.zip"
			mkdir -p $HOME/android-sdk
			cd $HOME/android-sdk
			export ANDROID_HOME=$HOME/android-sdk
			cd $ANDROID_HOME; wget https://dl.google.com/android/repository/sdk-tools-darwin-4333796.zip ; unzip sdk-tools-linux-*.zip
			$ANDROID_HOME/tools/bin/sdkmanager --update
			$ANDROID_HOME/tools/bin/sdkmanager "platforms;android-26"
 			$ANDROID_HOME/tools/bin/sdkmanager "platform-tools"
 			e_echo "You also must set the ANDROID_HOME environment variable"
			w_echo "More info at $URL"
		else
			#w_echo "https://dl.google.com/android/repository/sdk-tools-linux-*.zip"
			mkdir -p $HOME/android-sdk
			cd $HOME/android-sdk
			export ANDROID_HOME=$HOME/android-sdk
			cd $ANDROID_HOME; wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip ; unzip sdk-tools-linux-*.zip
			$ANDROID_HOME/tools/bin/sdkmanager --update
			$ANDROID_HOME/tools/bin/sdkmanager "platforms;android-26"
 			$ANDROID_HOME/tools/bin/sdkmanager "platform-tools"
 			e_echo "You also must set the ANDROID_HOME environment variable"
			w_echo "More info at $URL"
			
		fi
		
		#exit -1
	fi
}
installGradle(){
	tool_name="Gradle"
	command_to_check=$( gradle -version 2>&1 )
	exists=$(echo $command_to_check | grep "command not found")
	#original_tool=$(echo $com | cut -f1 -d\ )
	if [[ ! -n $exists ]]; then
		#tool exists
		i_echo "$TAG $tool_name Exists"
	else
		e_echo "$TAG $tool_name doesn't exist. Downloading gradle with sdkman"
		export SDKMAN_DIR="$HOME/.sdkman"
		[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
		sdk install gradle
	fi
}

installCoreUtils(){
	Machine=$1
	if [ "$Machine" == "Mac" ]; then
		brew install coreutils 
		brew install gnu-gsed	
	fi
}




setHomeDir
MACHINE=""
getSO MACHINE
i_echo "$TAG Running on $MACHINE OS"
installCoreUtils $MACHINE
installJava
installPython
installAndroidSDK
installSdkman
installGradle
