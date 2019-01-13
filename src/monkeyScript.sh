#!/bin/bash
source settings/settings.sh

TAG="[AD]"

machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
	SED_COMMAND="gsed" #mac
	MKDIR_COMMAND="gmkdir"
	MV_COMMAND="gmv"
else 
	SED_COMMAND="sed" #linux
	MKDIR_COMMAND="mkdir"
	MV_COMMAND="mv"	
fi

OLDIFS=$IFS
tName="_TRANSFORMED_"
deviceDir=""
prefix="" # "latest" or "" ; Remove if normal app
deviceExternal=""
logDir="logs"
localDir="$HOME/GDResults"
localDirOriginal="$HOME/GDResults"
#trace="-MethodOriented"   #trace=$2  ##RR
checkLogs="Off"
trace=$1
monkey="-Monkey"
folderPrefix=""
GD_ANALYZER="resources/jars/Analyzer.jar"  # "analyzer/greenDroidAnalyzer.jar"
GD_INSTRUMENT="resources/ars/jInst.jar"
GREENSOURCE_URL=$2
trepnLib="TrepnLibrary-release.aar"
trepnJar="TrepnLibrary-release.jar"
profileHardware="YES" # YES or ""
flagStatus="on"
SLEEPTIME=60 # 1 minutes
#SLEEPTIME=1
apkBuild="debug"
min_monkey_runs=1 #20
threshold_monkey_runs=3 #50
number_monkey_events=500
min_coverage=10
totaUsedTests=0
#DIR=/Users/ruirua/repos/GreenDroid/50apps/*
DIR=/Users/ruirua/tests/newApps/*
# trap - INT
# trap 'quit' INT


analyzeCSV(){
	tags=$(cat $1 |  grep "stopped" | wc -l)
	if [ $tags -lt "2" ] && [ "$folderPrefix" == "MonkeyTest" ] ; then
		e_echo " $1 might contain an error "
		echo "$1" >> logs/csvErrors.log
	fi
}
errorHandler(){
	if [[ "$1" == "1" ]]; then
		#exception occured during tests
		w_echo "killing running app..."
		adb shell am force-stop $1
		w_echo "uninstalling actual app $2"
		./uninstall.sh $1
	fi
}
# trying to determine the application uuid
# appId != package of the manifest, the appID is defined in the build.gradle, and may change according to app flavor, build_type, paid/free app, etc
# ignored this for now. tries to get  applicationID in build.gradle($1). otherwise gives the package in AndroidManifest.xml ($2) file
# In GreenSource context, we defined the appID = "projectID#appID";
getAppUID(){
	GRADLE_FILE=$1
	MANIFEST_FILE=$2
	APPID=$(grep -o "applicationId\s\".*\"" $1 | awk '{ print $2 }'| sed 's/\"//g')
	if [[ -n $APPID ]]; then
		eval "$3='$APPID'"
	else
		#package from manifest
		APPID=$(grep  -o "package=\".*\"" $2 | sed 's/package=//g'| sed 's/\"//g' )
		if [[ -n $APPID ]]; then
			eval "$3='$APPID'"
		fi		
	fi
}
# abort the script execution during testing phase
quit(){
	w_echo "Aborting.."
	e_echo "signal QUIT received. Gracefully aborting..."
	w_echo "killing running app..."
	adb shell am force-stop $1
	w_echo "uninstalling actual app $1"
	./uninstall.sh $1 $2
	w_echo "removing actual app from processed Apps log"
	sed "s#$3##g" $logDir/processedApps.log
	w_echo "GOODBYE"
	(adb shell am stopservice com.quicinc.trepn/.TrepnService) >/dev/null 2>&1
	exit -1
}
# get battery from the connected android device
getBattery(){
	battery_level=$(adb shell dumpsys battery | grep -o "level.*" | cut -f2 -d: | sed 's/ //g')
	w_echo " Actual battery level : $battery_level"
	if [ "$battery_level" -le 20 ]; then
		w_echo "battery level below 20%. Sleeping again"
		sleep 600 # sleep 10 min to charge battery
	fi
}


#### Monkey process
(adb kill-server ) > /dev/null  2>&1
DEVICE=$(adb devices -l  2>&1 | egrep "device .+ product:")
if [ -z "$DEVICE" ]; then
	e_echo "$TAG Error: 📵 Could not find any attached device. Check and try again..."
else
	deviceExternal=$(adb shell 'echo -n $EXTERNAL_STORAGE' 2>&1)
	if [ -z "$deviceExternal" ]; then
		e_echo "$TAG Could not determine the device's external storage. Check and try again..."
		exit 1
	fi
	( adb devices -l ) > device_info.txt 2>&1
	device_model=$(   cat device_info.txt | grep -o "model.*" | cut -f2 -d: | cut -f1 -d\ )
	device_serial=$(  cat device_info.txt | tail -n 2 | grep "model" | cut -f1 -d\ )
	device_brand=$( cat device_info.txt | grep -o "device:.*" | cut -f2 -d: )
	echo "{\"device_serial_number\": \"$device_serial\", \"device_model\": \"$device_model\",\"device_brand\": \"$device_brand\"}" > device.json
	#device=$( adb devices -l | grep -o "model.*" | cut -f2 -d: | cut -f1 -d\ )
	i_echo "$TAG 📲  Attached device ($device_model) recognized "
	#TODO include mode to choose the conected device and echo the device name
	deviceDir="$deviceExternal/trepn"  #GreenDroid
	#put Trepn preferences on device
	(adb push trepnPreferences/ $deviceDir/saved_preferences/) > /dev/null  2>&1 #new
	#Start Trepn
	#adb shell monkey -p com.quicinc.trepn -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
	
	adb shell am startservice --user 0 com.quicinc.trepn/.TrepnService > /dev/null  2>&1
	
	(echo $deviceDir > deviceDir.txt) 
	(adb shell mkdir $deviceDir) > /dev/null  2>&1
	(adb shell mkdir $deviceDir/Traces) > /dev/null  2>&1
	(adb shell mkdir $deviceDir/Measures) > /dev/null  2>&1
	(adb shell mkdir $deviceDir/TracedTests) > /dev/null  2>&1

	if [[ -n "$flagStatus" ]]; then
		($MKDIR_COMMAND $logDir/debugBuild ) > /dev/null  2>&1 #new

	fi

	w_echo "removing old instrumentations "
	./forceUninstall.sh 
	#for each Android Proj in $DIR folder...
	w_echo "$TAG searching for Android Projects in -> $DIR"
	# getting all seeds from file
	seeds20=$(head -$min_monkey_runs monkey_seeds.txt)
	last30=$(tail  -$threshold_monkey_runs monkey_seeds.txt)
	for f in $DIR/
		do
		localDir=$localDirOriginal
		

		
		#clean previous list of all methods and device results
		rm -rf ./allMethods.txt
		adb shell rm -rf "$deviceDir/allMethods.txt"
		adb shell rm -rf "$deviceDir/TracedMethods.txt"
		adb shell rm -rf "$deviceDir/Traces/*"
		adb shell rm -rf "$deviceDir/Measures/*"
		adb shell rm -rf "$deviceDir/TracedTests/*"  ##RR

		IFS='/' read -ra arr <<< "$f"
		ID=${arr[*]: -1}
		IFS=$(echo -en "\n\b")
		now=$(date +"%d_%m_%y_%H_%M_%S")

		# check if was already processed
		suc=$(cat $logDir/success.log 2>/dev/null | sort -u | uniq | grep $ID )
		if [ -n $suc  ] && [ "$checkLogs" != "Off" ]; then
			## it was already processed
			w_echo "Aplicattion $ID already processed. Skipping.."
			continue
		fi
		suc=$(cat $logDir/processedApps.log 2>/dev/null | sort -u | uniq | grep $ID )
		if [ -n $suc  ] && [ "$checkLogs" != "Off" ]; then
			## it was already processed
			w_echo "Application $ID already processed. Skipping.."
			continue
		fi
		echo $f >> $logDir/processedApps.log


		if [ "$ID" != "success" ] && [ "$ID" != "failed" ] && [ "$ID" != "unknown" ]; then
			
			projLocalDir=$localDir/$ID
			#rm -rf $projLocalDir/all/*
			if [[ $trace == "-TestOriented" ]]; then
				e_echo "	Test Oriented Profiling:      ✔"
				folderPrefix="MonkeyTest"
			else 
				e_echo "	Method Oriented profiling:    ✔"
				folderPrefix="MonkeyMethod"
			fi 
			if [[ $profileHardware == "YES" ]]; then
				w_echo "	Profiling hardware:           ✔"
				(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/trepnPreferences/All.pref") > /dev/null 2>&1
			else 
				(adb shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$deviceDir/saved_preferences/trepnPreferences/Pref1.pref") > /dev/null 2>&1
			fi	
			#first, check if this is a gradle or a maven project
			#GRADLE=$(find ${f}/latest -maxdepth 1 -name "build.gradle")
			GRADLE=($(find ${f}/${prefix} -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
			POM=$(find ${f}/${prefix} -maxdepth 1 -name "pom.xml")
			if [ -n "$POM" ]; then
				POM=${POM// /\\ }
				# Maven projects are not considered yet...
### Gradle proj			
			elif [ -n "${GRADLE[0]}" ]; then
				MANIFESTS=($(find $f -name "AndroidManifest.xml" | egrep -v "/build/|$tName"))
				if [[ "${#MANIFESTS[@]}" > 0 ]]; then
					MP=($(python manifestParser.py ${MANIFESTS[*]}))
					for R in ${MP[@]}; do
						RESULT=($(echo "$R" | tr ':' '\n'))
						TESTS_SRC=${RESULT[1]}
						PACKAGE=${RESULT[2]}
						if [[ "${RESULT[3]}" != "-" ]]; then
							TESTPACKAGE=${RESULT[3]}
						else
							TESTPACKAGE="$PACKAGE.test"
						fi
						MANIF_S="${RESULT[0]}/AndroidManifest.xml"
						MANIF_T="-"
						


#create results support folder
						#echo "$TAG Creating support folder..."
						$MKDIR_COMMAND -p $projLocalDir
						$MKDIR_COMMAND -p $projLocalDir/oldRuns
						($MV_COMMAND -f $(find $projLocalDir ! -path $projLocalDir -maxdepth 1 | grep -v "oldRuns") $projLocalDir/oldRuns/ ) >/dev/null 2>&1
						$MKDIR_COMMAND -p $projLocalDir/all

						FOLDER=${f}${prefix} #$f

						ORIGINAL_GRADLE=($(find $FOLDER/ -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs grep -L "com.android.library" | xargs grep -l "buildscript" | cut -f1 -d:)) # must be done before instrumentation
						APP_ID="unknown"
						getAppUID ${GRADLE[0]} $MANIF_S APP_ID
						GREENSOURCE_APP_UID="$ID#$APP_ID"
						APP_JSON="{\"app_id\": \"$GREENSOURCE_APP_UID\", \"app_location\": \"$f\", \"app_version\": \"0.0\", \"app_project\": \"$ID\"}" #" \"app_language\": \"Java\"}"
						Proj_JSON="{\"project_id\": \"$ID\", \"proj_desc\": \"\", \"proj_build_tool\": \"gradle\", \"project_apps\":[$APP_JSON] , \"project_packages\":[]}"
						#echo " ids -> $APP_ID , $GREENSOURCE_APP_UID"

#Instrumentation phase	
						oldInstrumentation=$(cat $FOLDER/$tName/instrumentationType.txt 2>/dev/null | grep  ".*Oriented" )
						allmethods=$(find $projLocalDir/all -maxdepth 1 -name "allMethods.txt")
						if [ "$oldInstrumentation" != "$trace" ] || [ -z "$allmethods" ]; then
							w_echo "Different type of instrumentation. instrumenting again..."
							rm -rf $FOLDER/$tName
							mkdir -p $FOLDER/$tName
							echo "$Proj_JSON" > $FOLDER/$tName/$GREENSOURCE_APP_UID.json
							java -jar $GD_INSTRUMENT "-gradle" $tName "X" $FOLDER $MANIF_S $MANIF_T $trace $monkey $GREENSOURCE_APP_UID ##RR
							#create results support folder
							#rm -rf $projLocalDir/all/*
							$MV_COMMAND ./allMethods.txt $projLocalDir/all/allMethods.txt
							#Instrument all manifestFiles
							(find $FOLDER/$tName -name "AndroidManifest.xml" | egrep -v "/build/" | xargs ./manifestInstr.py )

						else 
							e_echo "Same instrumentation of last time. Skipping instrumentation phase"
						fi
						
						#(echo "{\"app_id\": \"$ID\", \"app_location\": \"$f\",\"app_build_tool\": \"gradle\", \"app_version\": \"1\", \"app_language\": \"Java\"}") > $FOLDER/$tName/application.json
						xx=$(find  $projLocalDir/ -maxdepth 1 | $SED_COMMAND -n '1!p' |grep -v "oldRuns" | grep -v "all" )
						##echo "xx -> $xx"
						$MV_COMMAND -f $xx $projLocalDir/oldRuns/ >/dev/null 2>&1
						echo "$FOLDER/$tName" > lastTranformedApp.txt

						#copy the trace/measure lib
						#folds=($(find $FOLDER/$tName/ -type d | egrep -v "\/res|\/gen|\/build|\/.git|\/src|\/.gradle"))
						for D in `find $FOLDER/$tName/ -type d | egrep -v "\/res|\/gen|\/build|\/.git|\/src|\/.gradle"`; do  ##RR
						    if [ -d "${D}" ]; then  ##RR
						    	$MKDIR_COMMAND -p ${D}/libs  ##RR
						     	cp libsAdded/$treprefix$trepnLib ${D}/libs  ##RR
						    fi  ##RR
						done  ##RR
## BUILD PHASE						
						GRADLE=($(find $FOLDER/$tName -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs grep -L "com.android.library" | xargs grep -l "buildscript" | cut -f1 -d:))
						
						#echo "gradle script invocation -> ./buildGradle.sh $ID $FOLDER/$tName ${GRADLE[0]}"
						if [ "$oldInstrumentation" != "$trace" ] || [ -z "$allmethods" ]; then
							w_echo "[APP BUILDER] Different instrumentation since last time. Building Again"
							./buildGradle.sh $ID $FOLDER/$tName ${GRADLE[0]} $apkBuild
							RET=$(echo $?)
						else 
							w_echo "[APP BUILDER] No changes since last run. Not building again"
							RET=0
						fi
						(echo $trace) > $FOLDER/$tName/instrumentationType.txt
						if [[ "$RET" != "0" ]]; then
							echo "$ID" >> $logDir/errorBuildGradle.log
							cp $logDir/buildStatus.log $f/buildStatus.log
							if [[ -n "$flagStatus" ]]; then
								cp $logDir/buildStatus.log $logDir/debugBuild/$ID.log
							fi
							continue
						else 
							i_echo "BUILD SUCCESSFULL"
						fi
## END BUILD PHASE							
						localDir=$projLocalDir/$folderPrefix$now
						#echo "$TAG Creating support folder..."
						mkdir -p $localDir
						mkdir -p $localDir/all
						
						##copy MethodMetric to support folder
						#echo "copiar $FOLDER/$tName/classInfo.ser para $projLocalDir "
						cp $FOLDER/$tName/$GREENSOURCE_APP_UID.json $localDir
						cp device.json $localDir
						cp $FOLDER/$tName/appPermissions.json $localDir

						#install on device
						./install.sh $FOLDER/$tName "X" "GRADLE" $PACKAGE $projLocalDir $monkey $apkBuild	
						RET=$(echo $?)
						if [[ "$RET" == "-1" ]]; then
							echo "$ID" >> $logDir/errorInstall.log
							continue
						fi
						echo "$ID" >> $logDir/success.log
						total_methods=$( cat $projLocalDir/all/allMethods.txt | sort -u| uniq | wc -l | $SED_COMMAND 's/ //g')
						#now=$(date +"%d_%m_%y_%H_%M_%S")
						
						IGNORE_RUN=""
						##########
########## RUN TESTS 1 phase ############
						trap 'quit $PACKAGE $TESTPACKAGE $f' INT
						for i in $seeds20; do
							w_echo "APP: $ID | SEED Number : $totaUsedTests"
							./runMonkeyTest.sh $i $number_monkey_events $trace $PACKAGE	$localDir $deviceDir		
							RET=$(echo $?)
							if [[ $RET -ne 0 ]]; then
								echo "retas $RET"
								errorHandler $RET $PACKAGE
								IGNORE_RUN="YES"
								./trepnFix.sh $deviceDir
								totaUsedTests=0
								break				
							fi
							e_echo "Pulling results from device..."
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/{} $localDir
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' |  egrep -Eio "TracedMethods.txt" |xargs -I{} adb pull $deviceDir/{} $localDir
							mv $localDir/TracedMethods.txt $localDir/TracedMethods$i.txt
							mv $localDir/GreendroidResultTrace0.csv $localDir/GreendroidResultTrace$i.csv
							analyzeCSV $localDir/GreendroidResultTrace$i.csv
							totaUsedTests=$(($totaUsedTests + 1))
							adb shell am force-stop $PACKAGE						
							echo "methods invoked : $(cat $localDir/TracedMethods$i.txt | wc -l)"
							echo "total dif. methods invoked : $(cat $localDir/TracedMethods$i.txt | sort -u | uniq | wc -l )"
							if [ "$totaUsedTests" -eq 10 ]; then
								getBattery
							fi
							./trepnFix.sh $deviceDir
						done

########## RUN TESTS  THRESHOLD ############
						if [[ "$IGNORE_RUN" != "" ]]; then
							continue
						fi
						##check if have enough coverage
						nr_methods=$( cat $localDir/Traced*.txt | sort -u | uniq | wc -l | $SED_COMMAND 's/ //g')
						actual_coverage=$(echo "${nr_methods}/${total_methods}" | bc -l)
						e_echo "actual coverage -> 0$actual_coverage"
						
						for j in $last30; do
							coverage_exceded=$( echo " ${actual_coverage}>= .${min_coverage}" | bc -l)
							if [ "$coverage_exceded" -gt 0 ]; then
								echo "$ID|$totaUsedTests" >> $logDir/above$min_coverage.log
								break
							fi
							w_echo "APP: $ID | SEED Number : $totaUsedTests"
							./runMonkeyTest.sh $j $number_monkey_events $trace $PACKAGE	$localDir $deviceDir
							e_echo "Pulling results from device..."
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/{} $localDir
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio "TracedMethods.txt" | xargs -I{} adb pull $deviceDir/{} $localDir
							mv $localDir/TracedMethods.txt $localDir/TracedMethods$i.txt
							mv $localDir/GreendroidResultTrace0.csv $localDir/GreendroidResultTrace$i.csv
							nr_methods=$( cat $localDir/Traced*.txt | sort -u | uniq | wc -l | $SED_COMMAND 's/ //g')
							actual_coverage=$(echo "${nr_methods}/${total_methods}" | bc -l)
							acu=$(echo "${actual_coverage} * 100" | bc -l)
							w_echo "actual coverage -> $acu %"
							totaUsedTests=$(($totaUsedTests + 1))
							adb shell am force-stop $PACKAGE
							if [ "$totaUsedTests" -eq 30 ]; then
								getBattery
							fi
							./trepnFix.sh $deviceDir
						done

						trap - INT

						if [ "$coverage_exceded" -eq 0 ]; then
							echo "$ID|$actual_coverage" >> $logDir/below$min_coverage.log
						fi

						#cp $FOLDER/$tName/$GREENSOURCE_APP_UID.json $localDir/projectApplication.json

						(echo "{\"device_serial_number\": \"$device_serial\", \"device_model\": \"$device_model\",\"device_brand\": \"$device_brand\"}") > device.json
						./uninstall.sh $PACKAGE $TESTPACKAGE
						RET=$(echo $?)
						if [[ "$RET" != "0" ]]; then
							echo "$ID" >> $logDir/errorUninstall.log
							#continue
						fi
						#Run greendoid!
						#java -jar $GD_ANALYZER $ID $PACKAGE $TESTPACKAGE $FOLDER $FOLDER/tName $localDir
						#(java -jar $GD_ANALYZER $trace $projLocalDir/ $projLocalDir/all/ $projLocalDir/*.csv) > $logDir/analyzer.log  ##RR
						w_echo "Analyzing results .."
						java -jar $GD_ANALYZER $trace $projLocalDir/ $monkey $GREENSOURCE_URL
						#cat $logDir/analyzer.log
						errorAnalyzer=$(cat $logDir/analyzer.log)
						#TODO se der erro imprimir a vermelho e aconselhar usar o trepFix.sh
						#break
						w_echo "$TAG sleeping between profiling apps"
						sleep $SLEEPTIME
						w_echo "$TAG resuming Greendroid after nap"
						totaUsedTests=0
						getBattery
					done
				fi
			else
#SDK PROJ
				MANIFESTS=($(find $f -name "AndroidManifest.xml" | egrep -v "/bin/|$tName"))
				MP=($(python manifestParser.py ${MANIFESTS[*]}))
				for R in ${MP[@]}; do
					RESULT=($(echo "$R" | tr ':' '\n'))
					echo "result -> $RESULT"
					SOURCE=${RESULT[0]}
					TESTS=${RESULT[1]}
					PACKAGE=${RESULT[2]}
					TESTPACKAGE=${RESULT[3]}
					if [ "$SOURCE" != "" ] && [ "$TESTS" != "" ] && [ "$f" != "" ]; then
						#delete previously instrumented project, if any
						rm -rf $SOURCE/$tName
					
					APP_ID="unknown"
					getAppUID  $R $APP_ID
					GREENSOURCE_APP_UID="$ID#$APP_ID"
					APP_JSON="{\"app_id\": \"$GREENSOURCE_APP_UID\", \"app_location\": \"$f\", \"app_version\": \"1\"}" #" \"app_language\": \"Java\"}"
					Proj_JSON="{\"project_id\": \"$ID\", \"proj_desc\": \"\", \"proj_build_tool\": \"sdk\", \"project_apps\":[$APP_JSON]} , \"project_packages\":[]}"
					#echo "$Proj_JSON" > $localDir/projectApplication.json
#instrumentation phase
						if [[ "$SOURCE" != "$TESTS" ]]; then
							echo "$Proj_JSON" > $FOLDER/$tName/$GREENSOURCE_APP_UID.json
							java -jar $GD_INSTRUMENT "-sdk" $tName "X" $SOURCE $TESTS $trace $monkey $GREENSOURCE_APP_UID
						else
							echo "$Proj_JSON" > $FOLDER/$tName/$GREENSOURCE_APP_UID.json
							java -jar $GD_INSTRUMENT "-gradle" $tName "X" $FOLDER $MANIF_S $MANIF_T $trace $monkey $GREENSOURCE_APP_UID
						fi
						#copy the test runner
						$MKDIR_COMMAND -p $SOURCE/$tName/libs
						$MKDIR_COMMAND -p $SOURCE/$tName/tests/libs
						cp libsAdded/$trepnJar $SOURCE/$tName/libs
						cp libsAdded/$trepnJar $SOURCE/$tName/tests/libs
	
						#build
						./buildSDK.sh $ID $PACKAGE $SOURCE/$tName $SOURCE/$tName/tests $deviceDir $localDir
						RET=$(echo $?)
						if [[ "$RET" != "0" ]]; then
							echo "$ID" >> $logDir/errorBuildSDK.log
							if [[ "$RET" == "10" ]]; then
								#everything went well, at second try
								#let's create the results support files
								$MKDIR_COMMAND -p $projLocalDir
								$MKDIR_COMMAND -p $projLocalDir/oldRuns
								mv  $(ls $projLocalDir | grep -v "oldRuns") $projLocalDir/oldRuns/
								$MKDIR_COMMAND -p $projLocalDir/all
								cat ./allMethods.txt >> $projLocalDir/all/allMethods.txt
								echo "$ID" >> $logDir/success.log
							elif [[ -n "$flagStatus" ]]; then
								cp $logDir/buildStatus.log $logDir/debugBuild/$ID.log
							fi
							continue
						fi
						
						#install on device
						./install.sh $SOURCE/$tName $SOURCE/$tName/tests "SDK" $PACKAGE $localDir $monkey $apkBuild
						RET=$(echo $?)
						if [[ "$RET" != "0" ]]; then
							echo "$ID" >> $logDir/errorInstall.log
							continue
						fi
						echo "$ID" >> $logDir/success.log
	
						#create results support folder
						#echo "$TAG Creating support folder..."
						$MKDIR_COMMAND -p $projLocalDir
						$MKDIR_COMMAND -p $projLocalDir/oldRuns
						$MV_COMMAND -f $(find  $projLocalDir/ -maxdepth 1 | $SED_COMMAND -n '1!p' |grep -v "oldRuns") $projLocalDir/oldRuns/
						$MKDIR_COMMAND -p $projLocalDir/all
						cat ./allMethods.txt >> $projLocalDir/all/allMethods.txt
						
						##copy MethodMetric to support folder
						#echo "copiar $FOLDER/$tName/classInfo.ser para $projLocalDir "
						cp $FOLDER/$tName/$GREENSOURCE_APP_UID.json $localDir
						echo "$ID" >> $logDir/success.log
						total_methods=$( cat $projLocalDir/all/allMethods.txt | sort -u | wc -l | sed 's/ //g')
						now=$(date +"%d_%m_%y_%H_%M_%S")
						localDir=$localDir/$folderPrefix$now
						#echo "$TAG Creating support folder..."
						mkdir -p $localDir
						mkdir -p $localDir/all
						
########## RUN TESTS 1 phase ############
						trap 'quit $PACKAGE $TESTPACKAGE $f' INT
						for i in $seeds20; do
							w_echo "SEED Number : $totaUsedTests"
							./runMonkeyTest.sh $i $number_monkey_events $trace $PACKAGE	$localDir $deviceDir		
							RET=$(echo $?)
							if [[ $RET -ne 0 ]]; then
								errorHandler $RET $PACKAGE
								IGNORE_RUN="YES"
								break						
							fi
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/{} $localDir
							#adb shell ls "$deviceDir/TracedMethods.txt" | tr '\r' ' ' | xargs -n1 adb pull 
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio "TracedMethods.txt" | xargs -I{} adb pull $deviceDir/{} $localDir
							mv $localDir/TracedMethods.txt $localDir/TracedMethods$i.txt
							mv $localDir/GreendroidResultTrace0.csv $localDir/GreendroidResultTrace$i.csv
							totaUsedTests=$(($totaUsedTests + 1))
							adb shell am force-stop $PACKAGE
							if [ "$totaUsedTests" -eq 30 ]; then
								getBattery
							fi
							./trepnFix.sh $deviceDir
						done

########## RUN TESTS  THRESHOLD ############

						##check if have enough coverage
						nr_methods=$( cat $localDir/Traced*.txt | sort -u | uniq | wc -l | $SED_COMMAND 's/ //g')
						actual_coverage=$(echo "${nr_methods}/${total_methods}" | bc -l)
						e_echo "actual coverage -> $actual_coverage"
						
						for j in $last30; do
							coverage_exceded=$( echo " ${actual_coverage}>= .${min_coverage}" | bc -l)
							if [ "$coverage_exceded" -gt 0 ]; then
								w_echo "above average. Run completed"
								echo "$ID|$totaUsedTests" >> $logDir/above$min_coverage.log
								break
							fi
							w_echo "SEED Number : $totaUsedTests"
							./runMonkeyTest.sh $j $number_monkey_events $trace $PACKAGE	$localDir $deviceDir
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio ".*.csv" |  xargs -I{} adb pull $deviceDir/{} $localDir
							#adb shell ls "$deviceDir/TracedMethods.txt" | tr '\r' ' ' | xargs -n1 adb pull 
							adb shell ls "$deviceDir" | $SED_COMMAND -r 's/[\r]+//g' | egrep -Eio "TracedMethods.txt" | xargs -I{} adb pull $deviceDir/{} $localDir
							mv $localDir/TracedMethods.txt $localDir/TracedMethods$i.txt
							mv $localDir/GreendroidResultTrace0.csv $localDir/GreendroidResultTrace$i.csv
							nr_methods=$( cat $localDir/Traced*.txt | sort -u | uniq | wc -l | $SED_COMMAND 's/ //g')
							actual_coverage=$(echo "${nr_methods}/${total_methods}" | bc -l)
							w_echo "actual coverage -> $actual_coverage"
							totaUsedTests=$(($totaUsedTests + 1))
							adb shell am force-stop $PACKAGE
							if [ "$totaUsedTests" -eq 30 ]; then
								getBattery
							fi
							./trepnFix.sh $deviceDir
						done
						trap - INT
						if [ "$coverage_exceded" -eq 0 ]; then
							echo "$ID|$actual_coverage" >> $logDir/below$min_coverage.log
						fi


						APP_JSON="{\"app_id\": \"$GREENSOURCE_APP_UID\", \"app_location\": \"$f\", \"app_version\": \"1\"}" #" \"app_language\": \"Java\"}"
						Proj_JSON="{\"project_id\": \"$ID\", \"proj_desc\": \"\", \"proj_build_tool\": \"gradle\", project_apps:[$APP_JSON]} , project_packages=[]}"
						echo "$Proj_JSON" > $localDir/projectApplication.json
						./uninstall.sh $PACKAGE $TESTPACKAGE
						RET=$(echo $?)
						if [[ "$RET" != "0" ]]; then
							echo "$ID" >> $logDir/errorUninstall.log
							#continue
						fi
						w_echo "Analyzing results .."
						java -jar $GD_ANALYZER $trace $projLocalDir/ $monkey $GREENSOURCE_URL
						#cat $logDir/analyzer.log
						errorAnalyzer=$(cat $logDir/analyzer.log)
						#TODO se der erro imprimir a vermelho e aconselhar usar o trepFix.sh
						#break
						w_echo "$TAG sleeping between profiling apps"
						sleep $SLEEPTIME
						w_echo "$TAG resuming Greendroid after nap"
						totaUsedTests=0
						getBattery
					else
						e_echo "$TAG ERROR!"
					fi
				done
			fi
	    fi
	done
	IFS=$OLDIFS
#	testRes=$(find $projLocalDir -name "Testresults.csv")
#	if [ -n $testRes ] ; then 
#		cat $projLocalDir/Testresults.csv | $SED_COMMAND 's/,/ ,/g' | column -t -s, | less -S
#	fi
	#./trepnFix.sh
fi



