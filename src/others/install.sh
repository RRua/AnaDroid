#!/bin/bash

#TODO replace
ANADROID_PATH=$(pwd)
source $ANADROID_PATH/src/settings/settings.sh

pathProject=$1
pathTests=$2
projtype=$3
package=$4
resDir=$5
monkey=$6
apkBuild=$7
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
echo ""

i_echo "$TAG Installing the apps on the device"
#find the apk files
if [ "$projtype" == "SDK" ]; then
	appAPK=($(find $pathProject -name "*-$apkBuild*.apk" | grep -v $pathTests))
	testAPK=($(find $pathTests -name "*-$apkBuild.apk"))
elif [ "$projtype" == "GRADLE" ]; then
	appAPK=($(find $pathProject -name "*-$apkBuild*.apk"))
	testAPK=($(find $pathProject -name "*$apkBuild-androidTest*.*.apk"))
fi

OK="0"


if [ "${#appAPK[@]}" != 1 ] || [ "${#testAPK[@]}" != 1 ]; then

	if [ "${#appAPK[@]}" > 1 ] && [ "${#testAPK[@]}" == 1 ]; then
		pAux=$(echo "${testAPK[0]}" | $SED_COMMAND -r "s#\/[a-zA-Z0-9-]+-$apkBuild.+.apk#/#g")
		appAPK=($(find $pAux -name "*-$apkBuild*.apk"))
		if [ "${#appAPK[@]}" == 1 ]; then
			OK="1"
		fi

	elif [ "${#appAPK[@]}" == 1 ] && [ "${#testAPK[@]}" > 1 ]; then
		pAux=$(echo "${appAPK[0]}" | $SED_COMMAND -r "s#\/[a-zA-Z0-9-]+-$apkBuild.+.apk#/#g")
		ppAux=$(dirname $pAux)
		echo "folder is -> $ppAux"
		bqq=($(find $ppAux -name "*$apkBuild-androidTest*.apk"))
		echo "testApk -> $bqq"
		if [ "${#bqq[@]}" -ge "1" ]; then
			OK="1"
		fi
	else
		#Either there's no apk files found for the app and/or tests, 
		#or there are 2 or more apks for both app and tests
		OK="0"
	fi
else
	OK="1"
fi

if [[ $monkey == "-Monkey" ]]; then
	OK="2"
fi

if [[ "$OK" == "2" ]]; then
	if [ "${#appAPK[@]}" == 1 ]; then
		#w_echo "$TAG Ready to install generated Apps -> Finded : ${#x[@]} App .apk's, ${#testAPK[@]} Test .apk's"
		w_echo "$TAG installing App .apk's -> ${appAPK[0]}" 
		(adb install -r ${appAPK[0]})  >/dev/null 2>&1
	else
		e_echo "Error while installing. No APK's found"
		exit -1
	fi
elif [[ "$OK" != "1" ]]; then
	if [[ "${#appAPK[@]}" == 0 ]]; then
		exit -1
	fi
	e_echo "$TAG Error: Unexpected number of .apk files found."
	e_echo "$TAG Expected: 1 App .apk, 1 Test .apk |  Finded : ${#appAPK[@]} App .apk's, ${#testAPK[@]} Test .apk's"
	w_echo "[ERROR] Aborting..."
	exit 1
else 
	w_echo "$TAG Ready to install generated Apps -> Finded : ${#appAPK[@]} App .apk's, ${#testAPK[@]} Test .apk's"
	w_echo "$TAG installing App .apk's"
	(adb install -r ${appAPK[0]}) >/dev/null 2>&1
	w_echo "$TAG installing Test .apk's"
	(adb install -r ${testAPK[0]}) >/dev/null 2>&1
fi
exit 0