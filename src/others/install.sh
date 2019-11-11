#!/bin/bash

source $ANADROID_PATH/src/settings/settings.sh

pathProject=$1
pathTests=$2
projtype=$3
package=$4
resDir=$5
testingFramework=$6
apkBuild=$7
logDir=$8
installedAPK=""
machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
else 
	SED_COMMAND="sed" #linux	
fi
if [ "$apkBuild" == "" ]; then
	apkBuild="debug"
fi

TAG="[APP INSTALLER]"
#echo ""

#i_echo "$TAG Installing the apps on the device"
#find the apk files
IFS='%'
#ID=${arr[*]: -1} # ID OF of the application (name of respective folder )

if [ "$projtype" == "SDK" ]; then
	appAPK=($(find "$pathProject" -type f -name "*-$apkBuild.apk" | while read dir; do echo $dir; done | grep -v $pathTests))
	testAPK=($(find "$pathTests" -name "*-$apkBuild.apk"))
elif [ "$projtype" == "GRADLE" ]; then
	appAPK=($(find "$pathProject" -type f -name "*-$apkBuild.apk" -print | while read dir; do echo $dir; done | grep -v $pathTests | grep -v "instant-run"))
	testAPK=$(find "$pathProject" -type f  -name "*$apkBuild-androidTest*.apk" -print | while read dir; do echo $dir; done | grep -v "instant-run" )
	#testAPK=($(find "$pathProject" -name "*$apkBuild-androidTest*.apk"))
fi
IFS=$(echo -en "\n\b")

OK="0"

if [ "${#appAPK[@]}" != "1" ] || [ "${#testAPK[@]}" != "1" ]; then

	if [ "${#appAPK[@]}" -ge 1 ] && [ "${#testAPK[@]}" == "1" ]; then
		pAux=$(echo "${testAPK[0]}" | $SED_COMMAND -r "s#\/[a-zA-Z0-9-]+-$apkBuild.+.apk#/#g")
		appAPK=($(find "$pAux" -name "*-$apkBuild*.apk"))
		if [ "${#appAPK[@]}" == 1 ]; then
			OK="1"
		fi

	elif [ "${#appAPK[@]}" == "1" ] && [ "${#testAPK[@]}" == "1" ]; then
		pAux=$(echo "${appAPK[0]}" | $SED_COMMAND -r "s#\/[a-zA-Z0-9-]+-$apkBuild.+.apk#/#g")
		ppAux=$(dirname "$pAux")
		echo "folder is -> $ppAux"
		bqq=($(find "$ppAux" -name "*$apkBuild-androidTest*.apk"))
		echo "testApk -> $bqq"
		if [ "${#bqq[@]}" -ge "1" ]; then
			OK="1"
		fi
	
	#elif [ "${#appAPK[@]}" -ge 1 ] && [ "${#testAPK[@]}" == "0" ] ; then
	elif [ "${#appAPK[@]}" -ge 1 ]; then
		#statements
		#Either there's no apk files found for the app and/or tests, 
		#or there are 2 or more apks for both app and tests
		OK="2"
	else
		e_echo "FATAL ERROR. No APK found for installation"
		exit -1
	fi
else
	OK="1"
fi

if [[ $testingFramework == "-Monkey" ]]; then
	OK="2"
fi

if [ $testingFramework == "-junit" ]  && [ "${#testAPK[@]}" == "0" ]; then
	OK="-1"
fi

if [[ "$OK" == "2" ]]; then
	if [ "${#appAPK[@]}" -eq  "1" ]; then
		#w_echo "$TAG Ready to install generated Apps -> Finded : ${#x[@]} App .apk's, ${#testAPK[@]} Test .apk's"
		#w_echo "$TAG installing App .apk's -> ${appAPK[0]}" 
		for apk in $appAPK; do
			(adb install -g -r "$apk") 
			echo "$apk" > $logDir/lastInstalledAPK.txt
		done
		
	else
		e_echo "Error while installing. No APK's found"
		exit -1
	fi
elif [[ "$OK" != "1" ]]; then
	if [[ "${#appAPK[@]}" == 0 ]]; then
		e_echo "$TAG Error: Unexpected number of .apk files found."
		exit -1
	elif [[ "${#testAPK[@]}" == "0" ]]; then
		e_echo "$TAG Error: Unexpected number of test apk files found."
	fi
else 
	w_echo "$TAG installing main apk ${appAPK[0]}"
	(adb install -g -r "${appAPK[0]}") # >/dev/null 2>&1
	installedAPK=${appAPK[0]}
	echo "$installedAPK" > $logDir/lastInstalledAPK.txt
	#w_echo "$TAG installing Test .apk's"
	if [[ "$testingFramework" == "-junit" ]]; then
		w_echo "$TAG installing test apk ${testAPK[0]}"
		(adb install -g -r "${testAPK[0]}")   #>/dev/null 2>&1
	fi
	
fi
exit 0