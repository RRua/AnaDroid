#!/bin/bash
source settings.sh
source util.sh

machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
	Timeout_COMMAND="gtimeout"
else 
	SED_COMMAND="sed" #linux
	Timeout_COMMAND="gtimeout"	
fi
TIMEOUT="420" #7 minutes (60*7)
logDir="logs"
OLDIFS=$IFS
IFS=$(echo -en "\n\b")
ID=$1
FOLDER=$2
GRADLE=$3
apkBuild=$4
TAG="[APP BUILDER]"

#list of available build tools versions
GRADLE_VERSION=$(gradle --version | grep "Gradle" | cut -f2 -d\ ) # "3.4.1"
GRADLE_BUILD_VERSION=$(echo "$GRADLE_VERSION" | cut -f1 -d\. )
#GRADLE_VERSION=3.3 # RR

GRADLE_BUILD_VERSION="3"
GRADLE_PLUGIN="2.3.3" #TODO - Find a better way to determine this value (see https://developer.android.com/studio/releases/gradle-plugin.html#updating-gradle)

#BUILD_VERSIONS=($(ls $HOME/android-sdk-linux/build-tools/)) #MC
#TARGET_VERSIONS=($(ls $HOME/android-sdk-linux/platforms/))  #MC
#BUILD_VERSIONS=($(ls $HOME/Android/Sdk/build-tools/))
#TARGET_VERSIONS=($(ls $HOME/Android/Sdk/platforms/))
BUILD_VERSIONS=($(ls $ANDROID_HOME/build-tools/))
TARGET_VERSIONS=($(ls $ANDROID_HOME/platforms/))


i_echo "$TAG GRADLE PROJECT -> $ID "
NEW_RUNNER_JAR=libs/android-junit-report-1.5.8.jar # unused
OLD_RUNNER="android.test.InstrumentationTestRunner" # "android.support.test.runner.AndroidJUnitRunner" # 
NEW_RUNNER="android.support.test.runner.AndroidJUnitRunner"
RUNNER_VERSION="0.5"      # ${ANDROID_HOME}/extras/android/m2repository/com/android/support/test/runner
RUNNER_RULES="0.5"        # ${ANDROID_HOME}/extras/android/m2repository/com/android/support/test/rules
RUNNER_ESPRESSO="2.2.2"   # ${ANDROID_HOME}/extras/android/m2repository/com/android/support/test/espresso/espresso-cores
RUNNER_AUTOMATOR="2.1.2"  # ${ANDROID_HOME}/extras/android/m2repository/com/android/support/test/uiautomator/uiautomator-v18


#LINT
#LINT_ISSUES="\n check\ \'Recycle\',\ \'Wakelock\',\'DrawAllocation',\'ObsoleteLayoutParam\',\'ViewHolder\'\ "

#DEPENDENCIES STRINGS
TRANSITIVE=""
TEST_TRANSITIVE=""
ANDROID_TEST_TRANSITIVE=""
DEBUG_TRANSITIVE=""

if [[ $GRADLE_BUILD_VERSION -gt 3 ]]; then
	#statements
	TRANSITIVE="implementation"
	TEST_TRANSITIVE="testImplementation"
	ANDROID_TEST_TRANSITIVE="androidTestImplementation"
	DEBUG_TRANSITIVE="debugImplementation"
else
	TRANSITIVE="compile"
	TEST_TRANSITIVE="testCompile"
	ANDROID_TEST_TRANSITIVE="AndroidTestCompile"
	DEBUG_TRANSITIVE="debugCompile"
fi


if [ "$apkBuild" == "debug" ]; then
	apkBuild="Debug"
else
	apkBuild="Release"
fi


#GREENDROID=$FOLDER/libs/greenDroidTracker.jar
GREENDROID=$FOLDER/libs/TrepnLibrary-release.aar  ##RR

#Change the main build file
#$SED_COMMAND -ri.bak "s#classpath ([\"]|[\'])com.android.tools.build:gradle:(.+)([\"]|[\'])#classpath 'com.android.tools.build:gradle:$GRADLE_PLUGIN'#g" $GRADLE
#change the other build files
BUILDS=($(find $FOLDER -name "build.gradle" | egrep -v "/build/"))
for x in ${BUILDS[@]}; do
	#remove \r characters
	$SED_COMMAND -ri.bak "s#\r##g" $x

	#change the garbage collector settings
	dexOpt=$(egrep -n "dexOptions( ?){" $x)
	dexLine=$(egrep -n "dexOptions( ?){" $x | cut -f1 -d:)
	if [ -n "$dexOpt" ]; then
		((dexLine++))
		preDex=$(egrep "preDexLibraries(( )|( ?=? ?))" $x)
		if [ -n "$preDex" ]; then
			$SED_COMMAND -ri.bak "s#preDexLibraries(( )|( ?=? ?))(.+)#preDexLibraries = false#g" $x
		else
			$SED_COMMAND -i.bak ""$dexLine"i preDexLibraries = false" $x
			((dexLine++))
		fi
		heapMaxDex=$(egrep "javaMaxHeapSize(( )|( ?=? ?))" $x)
		if [ -n "$heapMaxDex" ]; then
			$SED_COMMAND -ri.bak "s#javaMaxHeapSize(( )|( ?=? ?))(.+)#javaMaxHeapSize \"2g\"#g" $x
		else
			$SED_COMMAND -i.bak ""$dexLine"i javaMaxHeapSize \"2g\""
			((dexOpt++))
		fi
	else
		#echo "adding dexOpt"
		ANDROID_LINE=($(egrep -n "android( ?){" $x | cut -f1 -d:))
		if [ -n "${ANDROID_LINE[0]}" ]; then
			((ANDROID_LINE[0]++))
			$SED_COMMAND -i.bak ""$ANDROID_LINE"i dexOptions {" $x
			((ANDROID_LINE[0]++))
			$SED_COMMAND -i.bak ""$ANDROID_LINE"i preDexLibraries = false" $x
			((ANDROID_LINE[0]++))
			$SED_COMMAND -i.bak ""$ANDROID_LINE"i javaMaxHeapSize \"2g\"" $x
			((ANDROID_LINE[0]++))
			$SED_COMMAND -i.bak ""$ANDROID_LINE"i }" $x
		fi
	fi
	#check for the lintOptions, and change the file if they are not properly set
	HAS_LINT=$(egrep "lintOptions( ?){" $x)
	if [ -n "$HAS_LINT" ]; then
		LINT_LINE=($(egrep -n "lintOptions( ?){" $x | cut -f1 -d:))
		for i in ${LINT_LINE[@]}; do
			((i++))
			HAS_ABORT=$(egrep "abortOnError (true|false)" $x)
			if [ -n "$HAS_ABORT" ]; then
				$SED_COMMAND -ri.bak "s#abortOnError true#abortOnError false#g" $x
			else
				$SED_COMMAND -i.bak ""$i"i abortOnError false" $x
			fi
		done
	else
		ANDROID_LINE=($(egrep -n "android( ?){" $x | cut -f1 -d:))
		if [ -n "${ANDROID_LINE[0]}" ]; then
			((ANDROID_LINE[0]++))
			$SED_COMMAND -i.bak ""$ANDROID_LINE"i lintOptions {" $x
			((ANDROID_LINE[0]++))
			$SED_COMMAND -i.bak ""$ANDROID_LINE"i abortOnError false" $x
			((ANDROID_LINE[0]++))
			$SED_COMMAND -i.bak ""$ANDROID_LINE"i }" $x
		fi
	fi

	##dummy way to add lint checks
	ANDROID_LINE=($(egrep -n "android( ?){" $x | cut -f1 -d:))
	#if [ -n "${ANDROID_LINE[0]}" ]; then
		#$SED_COMMAND  -i -e "\$a android\ { lintOptions\ {\ $LINT_ISSUES \n }}" $x
	#fi

	### dummy way to add mavenCentral and jcenter
	$SED_COMMAND  -i -e "\$a\ buildscript\ {repositories\ {jcenter()\ \n\ mavenCentral()}}" $x
	###
	#Add a line that includes the trepn library folder in build.gradle
	$SED_COMMAND  -i -e "\$a\ allprojects\ {repositories\ {flatDir\ {\ dirs\ 'libs'}}}" $x
	#Change the packageName and testPackageName variables, if it exists
	$SED_COMMAND -ri.bak "s#packageName (.+)#applicationId \1#g" $x
	$SED_COMMAND -ri.bak "s#testPackageName (.+)#testApplicationId \1#g" $x
	#Change the classpath variable, if necessary
	#$SED_COMMAND -ri.bak "s#classpath ([\"]|[\'])com.android.tools.build:gradle:(.+)([\"]|[\'])#classpath 'com.android.tools.build:gradle:$GRADLE_PLUGIN'#g" $x
	#Check if it is necessary to change the version of the SDK compiler
	$SED_COMMAND -ri.bak 's#([ \t]*)compileSdkVersion(( )|( ?= ?))(android-)?(1?[0-9]{1}|20|[^0-9]+)$#\1compileSdkVersion\221#g' $x
	#Check if it is necessary to change the tag for the Proguard
	$SED_COMMAND -ri.bak "s#runProguard#minifyEnabled#g" $x
	#Change the remaining tags
	$SED_COMMAND -ri.bak "s#packageNameSuffix #applicationIdSuffix #g" $x
	$SED_COMMAND -ri.bak "s#android.plugin.bootClasspath #android.bootClasspath #g" $x
	$SED_COMMAND -ri.bak "s#android.plugin.ndkFolder #android.plugin.ndkDirectory #g" $x
	$SED_COMMAND -ri.bak "s#zipAlign #zipAlignEnabled #g" $x
	$SED_COMMAND -ri.bak "s#jniDebugBuild #jniDebuggable #g" $x
	$SED_COMMAND -ri.bak "s#renderscriptDebug #renderscriptDebuggable #g" $x
	$SED_COMMAND -ri.bak "s#flavorGroups #flavorDimensions #g" $x
	$SED_COMMAND -ri.bak "s#renderscriptSupportMode #renderscriptSupportModeEnabled #g" $x
	$SED_COMMAND -ri.bak "s#ProductFlavor.renderscriptNdkMode #renderscriptNdkModeEnabled #g" $x
	$SED_COMMAND -ri.bak "s#InstrumentTest #androidTest #g" $x
	$SED_COMMAND -ri.bak "s#instrumentTestCompile #$ANDROID_TEST_TRANSITIVE #g" $x

	#check if the app uses the compatibility library and if the minSdkVersion is defined accordingly
	appCompat=$(egrep "compile ([\"]|[\'])com.android.support:appcompat-v7:(.+)([\"]|[\'])" $x)
	if [ -n "$appCompat" ]; then
		minSDK=$(egrep "minSdkVersion [0-6]" $x)
		if [ -n "$minSDK" ]; then
			IFS=" " read -ra arr <<< "$minSDK"
			SDKv=${arr[*]: -1}
			IFS=$(echo -en "\n\b")
			if [[ (("$SDKv" < "7")) ]]; then
				$SED_COMMAND -ri.bak "s#minSdkVersion (.+)#minSdkVersion 7#g" $x
			fi
		else
			minSDK=$(egrep "minSdkVersion (.+)" $x)
			if [ -z "$minSDK" ]; then
				ANDROID_LINE=($(egrep -n "defaultConfig( ?){" $x | cut -f1 -d:))
				if [ -n "${ANDROID_LINE[0]}" ]; then
					((ANDROID_LINE[0]++))
					$SED_COMMAND -i.bak ""$ANDROID_LINE"i minSdkVersion 7" $x
				fi
			fi
		fi
	fi

	btools=$(egrep "buildToolsVersion *" $x)
	#Check if it necessary to change the build tools version
	if [ -n "$btools" ]; then
		delims=\'\"
		IFS="$delims" read -ra arr <<< "$btools"
		old_buildv=${arr[1]}
		IFS=$(echo -en "\n\b")
		correct=0
		for v in ${BUILD_VERSIONS[@]}; do
			if [ "$v" == "$old_buildv" ] || [ "$old_buildv" == "" ]; then
				correct=1
				break
			elif [[ (("$v" < "$old_buildv")) ]]; then
				new_buildv=$v
			elif ! [[ ${old_buildv:0:1} =~ [0-9]{1} ]]; then
				new_buildv=21.1.2
				break
			else
				new_buildv=$v
				break
			fi
		done
		if [ "$correct" == "0" ]; then
			#new_buildv=21.1.2
			$SED_COMMAND -ri.bak "s#([ \t]*)buildToolsVersion(( )|( ?= ?))(.+)#\1buildToolsVersion\2\""$new_buildv"\"#g" $x
		fi
	fi
	#check if this is a lib project, and remove the 'applicationsId' variable
	islib=$(egrep "apply plugin: ([\"]|[\'])(com.android.library)|(android-library)([\"]|[\'])" $x)
	if [ -n "$islib" ]; then
		$SED_COMMAND -ri.bak 's#([ \t]*)applicationId .+# #g' $x
	fi
	#check if it is necessary to change the targetSdkVersion
	target=$(egrep "targetSdkVersion *" $x)
	if [ -n "$target" ]; then
		delims=\'\"
		IFS="$delims" read -ra arrT <<< "$target"
		if [ "${#arrT[@]}" == "1" ]; then
			IFS=" " read -ra arrT <<< "$target"
		fi
		old_target=${arrT[1]}
		IFS=$(echo -en "\n\b")
		correct=0
		for t in ${TARGET_VERSIONS[@]}; do
			if [ "${t:8:2}" == "$old_target" ] || [ "$old_target" == "" ]; then
				correct=1
				break
			elif [[ (("${t:8:2}" < "$old_target")) ]]; then
				new_target="${t:8:2}"
			elif ! [[ ${old_target:0:1} =~ [0-9]{1} ]]; then
				new_target="21"
				break
			else
				new_target=${t:8:2}
				break
			fi
		done
		if [ "$correct" == "0" ]; then
			$SED_COMMAND -ri.bak "s#([ \t]*)targetSdkVersion *(=?) *.+#\1targetSdkVersion \2 "$new_target"#g" $x
		fi
	fi

	#Change the test properties
	ANDROID_LINE=($(egrep -n "android( ?){$" $x | cut -f1 -d:))
	if [ -n "${ANDROID_LINE[0]}" ]; then
		ANDROID_LINE=($(egrep -n "defaultConfig( ?){$" $x | cut -f1 -d:))
		if [ -n "${ANDROID_LINE[0]}" ]; then
			((ANDROID_LINE[0]++))
			HAS_RUNNER=$(grep  "testInstrumentationRunner" $x)
			vv=$(grep "compileSdkVersion" $x)
			IFS=" " read -ra arr <<< "$vv"
			csv=${arr[*]: -1}
			IFS=$(echo -en "\n\b")
			if ! [[ -z "${HAS_RUNNER// }" ]] && [ -n $vv ]; then
				#echo "ja tem runner file $x xx$HAS_RUNNER xx $vv"
				if [ "$csv" -ge "22" ] ; then
					$SED_COMMAND -ri.bak "s#([ \t]*)testInstrumentationRunner .+#\1testInstrumentationRunner \"$NEW_RUNNER\"#g" $x
					(echo $NEW_RUNNER) > actualrunner.txt
				else
					$SED_COMMAND -ri.bak "s#([ \t]*)testInstrumentationRunner .+#\1testInstrumentationRunner \"$OLD_RUNNER\"#g" $x
					(echo $OLD_RUNNER) > actualrunner.txt
				fi
				
			else
				if [ "$csv" -ge "22" ] ; then
					$SED_COMMAND -i.bak ""$ANDROID_LINE"i testInstrumentationRunner \"$NEW_RUNNER\"" $x
					(echo $NEW_RUNNER) > actualrunner.txt
				else
					$SED_COMMAND -i.bak ""$ANDROID_LINE"i testInstrumentationRunner \"$OLD_RUNNER\"" $x
					(echo $OLD_RUNNER) > actualrunner.txt
				fi
			fi
		fi
		
		#Add TrepnLib dependency to build.gradle
		HAS_DEPEND=$(egrep -n "dependencies( ?){" $x)
		AUX=$(egrep -n "buildscript *\{" $x)
		AUX_BS=$(egrep -n "buildscript *\{" $x | cut -f1 -d: | tail -1)
		if [ -n "$HAS_DEPEND" ]; then
			DEPEND_LINE=$(egrep -n "dependencies( ?){" $x | cut -f1 -d: | tail -1)
			if [ -n "$AUX" ]; then
				matching_brackets "$x" "$AUX_BS"
				AUX_BS_2=$?
				if [[ "$AUX_BS" -lt "$DEPEND_LINE" && "$DEPEND_LINE" -lt "$AUX_BS_2" ]]; then
					DEPEND_LINE_2=$(egrep -n "dependencies( ?){" $x | cut -f1 -d: | head -1)
				fi
			fi
			if [[ "$DEPEND_LINE" == "$DEPEND_LINE_2" ]]; then
				DEPEND_LINE=$(wc -l $x | cut -f1 -d\ )
				echo "" >> $x
				((DEPEND_LINE++))
				$SED_COMMAND -i.bak ""$DEPEND_LINE"i dependencies {" $x
				((DEPEND_LINE++))
				$SED_COMMAND -i.bak ""$DEPEND_LINE"i $TRANSITIVE (name:'TrepnLibrary-release', ext:'aar')" $x
				((DEPEND_LINE++))
				###
				# For when we decide to use the new runner, this will be needed
				# $SED_COMMAND -i.bak ""$DEPEND_LINE"i androidTestCompile 'com.android.support.test:runner:$RUNNER_VERSION'" $x
				# ((DEPEND_LINE++))
  				# #// Set this dependency to use JUnit 4 rules
  				# $SED_COMMAND -i.bak ""$DEPEND_LINE"i androidTestCompile 'com.android.support.test:rules:$RUNNER_RULES'" $x
  				# ((DEPEND_LINE++))
  				# #// Set this dependency to build and run Espresso tests
  				# $SED_COMMAND -i.bak ""$DEPEND_LINE"i androidTestCompile 'com.android.support.test.espresso:$RUNNER_ESPRESSO'" $x
  				# ((DEPEND_LINE++))
  				# #// Set this dependency to build and run UI Automator tests
  				# $SED_COMMAND -i.bak ""$DEPEND_LINE"i androidTestCompile 'com.android.support.test.uiautomator:uiautomator-v18:$RUNNER_AUTOMATOR'" $x
  				# ((DEPEND_LINE++))
  				###
				$SED_COMMAND -i.bak ""$DEPEND_LINE"i }" $x
			else
				((DEPEND_LINE++))
				$SED_COMMAND -i.bak ""$DEPEND_LINE"i $TRANSITIVE (name:'TrepnLibrary-release', ext:'aar')" $x
			fi
		else
			DEPEND_LINE=$(wc -l $x | cut -f1 -d\ )
			echo "" >> $x
			((DEPEND_LINE++))
			$SED_COMMAND  -i -e "\$a\ dependencies\ {$TRANSITIVE\ (name:'TrepnLibrary-release',\ ext:'aar')}" $x
			((DEPEND_LINE++))
		fi
	fi
done
IFS=$OLDIFS
#change local.properties
LOCAL_P=$(find $FOLDER -name "local.properties")
if [ -n "$LOCAL_P" ]; then
	LOCAL_P=${LOCAL_P// /\\ }
	$SED_COMMAND -ri.bak "s|sdk.dir.+|#&|g" $LOCAL_P
fi
#change gradle-wrapper.properties
#WRAPPER=$(find $FOLDER -name "gradle-wrapper.properties")
#if [ -n "$WRAPPER" ]; then
#	WRAPPER=${WRAPPER// /\\ }
#	$SED_COMMAND -ri.bak "s#distributionUrl.+#distributionUrl=http\://services.gradle.org/distributions/gradle-$GRADLE_VERSION-all.zip#g" $WRAPPER
#fi 

#gradle --no-daemon -b $GRADLE clean build assembleAndroidTest &> $logDir/buildStatus.log
#gradle -b $GRADLE clean build assembleAndroidTest &> $logDir/buildStatus.log

## The 'RR' way:
 chmod +x $FOLDER/gradlew
 echo  "$TAG Building and running tests....."
 x=$(pwd)
 cd $FOLDER; ./gradlew assemble$apkBuild &> $x/$logDir/buildStatus.log ; cd $x 

STATUS_NOK=$(grep "BUILD FAILED" $logDir/buildStatus.log)
STATUS_OK=$(grep "BUILD SUCCESS" $logDir/buildStatus.log)
if [ -n "$STATUS_NOK" ]; then
	try="6"
	libsError=$(grep "No signature of method: java.util.ArrayList.call() is applicable for argument types: (java.lang.String) values: \[libs\]" $logDir/buildStatus.log)
	minSDKerror=$(egrep "uses-sdk:minSdkVersion (.+) cannot be smaller than version (.+) declared in" $logDir/buildStatus.log)
	buildSDKerror=$(egrep "The SDK Build Tools revision \((.+)\) is too low for project ':(.+)'. Minimum required is (.+)" $logDir/buildStatus.log)
	(export PATH=$ANDROID_HOME/tools/bin:$PATH)
	(sdkmanager --list) > sdks.txt
	#echo "available _> $availableSdkTools"
	while [[ (-n "$minSDKerror") || (-n "$buildSDKerror") || (-n "$libsError") ]]; do
		((try--))
		w_echo "$TAG Common Error. Trying again..."
		unmatchVers=($($SED_COMMAND -nr "s/(.+)uses-sdk:minSdkVersion (.+) cannot be smaller than version (.+) declared in (.+)$/\2\n\3/p" $logDir/buildStatus.log))
		unmatchBuilds=($($SED_COMMAND -nr "s/(.+)The SDK Build Tools revision \((.+)\) is too low for project ':(.+)'. Minimum required is (.+)$/\2\n\4/p" $logDir/buildStatus.log))
		oldV=${unmatchVers[0]}
		newV=${unmatchVers[1]}
		oldBuild=${unmatchBuilds[0]}
		newBuild=${unmatchBuilds[1]}
		#change the build files again
		for x in ${BUILDS[@]}; do
			#correct minSdkVersion
			gradleFolder=${x//build.gradle}
			if [[ -n "$oldV" ]]; then #"$minSDKerror" == *"$gradleFolder"* ]]; then
				#found the troublesome build.gradle, replace!
				minSDK=$(grep "minSdkVersion " $x)
				if [ -n "$minSDK" ]; then
					vrs=($($SED_COMMAND -nr "s#minSdkVersion +(.+)#\1#p" $x))
					if ! [[ ${vrs[0]} =~ "'[0-9 ]+$" ]] ; then
						$SED_COMMAND -ri.bak "s#minSdkVersion (.+)#minSdkVersion $newV#g" $x
					else
						$SED_COMMAND -ri.bak "s#minSdkVersion $oldV#minSdkVersion $newV#g" $x
					fi
				else
					ANDROID_LINE=($(egrep -n "defaultConfig( ?){" $x | cut -f1 -d:))
					if [ -n "${ANDROID_LINE[0]}" ]; then
						((ANDROID_LINE[0]++))
						$SED_COMMAND -i.bak ""$ANDROID_LINE"i minSdkVersion $newV" $x
					fi
				fi
			fi

			#correct buildToolsVersion
			if [[ -n "$oldBuild" ]] ; then
				#echo " avaliables -> $availableSdkTools"
				availableSdkTools=$(grep "build-tools/$newBuild" sdks.txt)
				# if don't have that build tools version		
				availableSdkTools=$(grep "build-tools/$newBuild" sdks.txt)
				if [[ -z "$availableSdkTools" ]] ; then 
					#download via sdkmanager 
					e_echo "No suitable build-tools found. Downloading build tools $newBuild."
					($Timeout_COMMAND -s 9 $TIMEOUT sdkmanager "build-tools;$newBuild") &> $logDir/downloads.log
				fi
				$SED_COMMAND -ri.bak "s#([ \t]*)buildToolsVersion(( )|( ?= ?))(.+)#\1buildToolsVersion\2\""$newBuild"\"#g" $x
				#$SED_COMMAND -ri.bak "s#buildToolsVersion \"$oldBuild\"#buildToolsVersion \"$newBuild\"#g" $x
				#cat $x
			fi

			if [[ -n "$libsError" ]]; then
				$SED_COMMAND -i.bak "s#dirs.each#directories.each#g" $x
				$SED_COMMAND -ri.bak "s#(.+) +dirs *= *\[#\1 directories = [#g" $x
			fi
			
		done
		

		# retry
		#gradle --no-daemon -b $GRADLE clean build assembleAndroidTest &> $logDir/buildStatus.log
		#gradle -b $GRADLE clean build assembleAndroidTest &> $logDir/buildStatus.log
		chmod +x $FOLDER/gradlew
 		echo  "$TAG Building and running tests (AGAIN) ....."
 		x=$(pwd)
		cd $FOLDER; ./gradlew assemble$apkBuild &> $x/$logDir/buildStatus.log ; cd $x 


		libsError=$(egrep "No signature of method: java.util.ArrayList.call() is applicable for argument types: (java.lang.String) values: [libs]" $logDir/buildStatus.log)
		minSDKerror=$(egrep "uses-sdk:minSdkVersion (.+) cannot be smaller than version (.+) declared in" $logDir/buildStatus.log)
		buildSDKerror=$(egrep "The SDK Build Tools revision \((.+)\) is too low for project ':(.+)'. Minimum required is (.+)" $logDir/buildStatus.log)
		STATUS_NOK=$(grep "BUILD FAILED" $logDir/buildStatus.log)
		STATUS_OK=$(grep "BUILD SUCCESS" $logDir/buildStatus.log)
		
		if [ -n "$STATUS_OK" ]; then
			#the build was successful
			i_echo "$TAG Build successful for project $ID"
			break
		fi

		if [[ "$try" -eq "0" ]]; then
			break
		fi
	done

	if [ -n "$STATUS_NOK" ]; then
		#the build failed
		e_echo "$TAG Unable to build project $ID"
		e_echo "[ERROR] Aborting"
		exit 1
	fi
elif [ -n "$STATUS_OK" ]; then
	i_echo "$TAG Build successful for project $ID"
else
	e_echo "$TAG Unable to build project $ID"
	e_echo "[ERROR] Aborting"
	exit 1
fi
exit 0
