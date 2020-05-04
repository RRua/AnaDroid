#!/bin/bash
SRC_FOLDER="$ANADROID_PATH/src/"
source $SRC_FOLDER/settings/settings.sh

TAG="[GD]"

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
#localDirOriginal="/Users/ruirua/Documents/Tese/resultados/GDResults/relevant40"
#trace="-MethodOriented"   #trace=$2  ##RR
checkLogs="Off"
trace="-ActivityOriented"
monkey="-Monkey"
folderPrefix=""
GD_ANALYZER="$ANADROID_PATH/resources/jars/Analyzer.jar"  # "analyzer/greenDroidAnalyzer.jar"
GD_INSTRUMENT="$ANADROID_PATH/resources/jars/jInst.jar"
trepnLib="TrepnLib-release.aar"
trepnJar="TrepnLib-release.jar"
profileHardware="YES" # YES or ""
flagStatus="on"
SLEEPTIME=120 # 2 minutes
#SLEEPTIME=1
min_monkey_runs=2 #20
threshold_monkey_runs=3 #50
number_monkey_events=500
min_coverage=10
totaUsedTests=0

DIR=$ANADROID_PATH/demoProjects/*
#DIR=/Users/ruirua/tests/actual/*
#DIR=/Users/ruirua/Documents/Tese/resultados/relevantApps/*

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

for f in $DIR/ ; do

	#localDir=$localDirOriginal
	#clean previous list of all methods and device results
	rm -rf ./allMethods.txt
	IFS='/' read -ra arr <<< "$f"
	ID=${arr[*]: -1}
	IFS=$(echo -en "\n\b")
	now=$(date +"%d_%m_%y_%H_%M_%S")
	if [ "$ID" != "success" ] && [ "$ID" != "failed" ] && [ "$ID" != "unknown" ]; then
		projLocalDir=$localDir/$ID
		#rm -rf $projLocalDir/all/*
		if [[ $trace == "-TestOriented" ]]; then
			e_echo "	Test Oriented Profiling:      ✔"
			folderPrefix="MonkeyTest"
		elif[[ $trace == "-MethodOriented" ]]:
			e_echo "	Method Oriented profiling:    ✔"
			folderPrefix="MonkeyMethod"
		
		else
			e_echo "	Activity Oriented profiling:    ✔"
			folderPrefix="ActivityMethod"			
		fi 
		GRADLE=($(find ${f}/${prefix} -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs -I{} grep "buildscript" {} /dev/null | cut -f1 -d:))
		POM=$(find ${f}/${prefix} -maxdepth 1 -name "pom.xml")
		$MKDIR_COMMAND -p $f/$tName/
		MANIFESTS=($(find $f -name "AndroidManifest.xml" | egrep -v "/build/|$tName"))
		if [[ "${#MANIFESTS[@]}" > 0 ]]; then
			MP=($(python $SRC_FOLDER/build/manifestParser.py ${MANIFESTS[*]}))
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
				#($MV_COMMAND -f $(find $projLocalDir ! -path $projLocalDir -maxdepth 1 | grep -v "oldRuns") $projLocalDir/oldRuns/ ) >/dev/null 2>&1
				$MKDIR_COMMAND -p $projLocalDir/all

				FOLDER=${f}${prefix} #$f

				ORIGINAL_GRADLE=($(find $FOLDER -name "*.gradle" -type f -print | grep -v "settings.gradle" | xargs grep -L "com.android.library" | xargs grep -l "buildscript" | cut -f1 -d:)) # must be done before instrumentation
				APP_ID="unknown"
				getAppUID ${GRADLE[0]} $MANIF_S APP_ID
				GREENSOURCE_APP_UID="$ID#$APP_ID"
				APP_JSON="{\"app_id\": \"$GREENSOURCE_APP_UID\", \"app_location\": \"$f\", \"app_version\": \"0.0\", \"app_project\": \"$ID\"}" #" \"app_language\": \"Java\"}"
				Proj_JSON="{\"project_id\": \"$ID\", \"proj_desc\": \"\", \"proj_build_tool\": \"gradle\", \"project_apps\":[$APP_JSON] , \"project_packages\":[]}"

#Instrumentation phase	
				#oldInstrumentation=$(cat $FOLDER/$tName/instrumentationType.txt 2> /dev/null | grep  ".*Oriented" )
				allmethods=$(find $projLocalDir/all -maxdepth 1 -name "allMethods.txt")
				
				#w_echo "Different type of instrumentation. instrumenting again..."
				rm -rf $FOLDER/$tName
				mkdir -p $FOLDER/$tName
				echo "$Proj_JSON" > $FOLDER/$tName/$GREENSOURCE_APP_UID.json
				
				java -jar "$GD_INSTRUMENT" "-gradle" $tName "X" "$FOLDER" "$MANIF_S" "$MANIF_T" "$trace" "$monkey" "$GREENSOURCE_APP_UID" "$APPROACH" ##RR
				#java -jar $GD_INSTRUMENT "-gradle" $tName "X" $FOLDER $MANIF_S $MANIF_T $trace $monkey $GREENSOURCE_APP_UID ##RR
				#create results support folder
				#rm -rf $projLocalDir/all/*
				$MV_COMMAND ./allMethods.txt $projLocalDir/all/allMethods.txt
				#Instrument all manifestFiles
				(find $FOLDER/$tName -name "AndroidManifest.xml" | egrep -v "/build/" | xargs ./manifestInstr.py )

				#(echo "{\"app_id\": \"$ID\", \"app_location\": \"$f\",\"app_build_tool\": \"gradle\", \"app_version\": \"1\", \"app_language\": \"Java\"}") > $FOLDER/$tName/application.json
				#xx=$(find  $projLocalDir/ -maxdepth 1 | $SED_COMMAND -n '1!p' |grep -v "oldRuns" | grep -v "all" )
				##echo "xx -> $xx"
				#$MV_COMMAND -f $xx $projLocalDir/oldRuns/ >/dev/null 2>&1
				echo "$FOLDER/$tName" > lastTranformedApp.txt
				monkey_folder=$(find $projLocalDir/ -maxdepth 1 -name "Monkey*" )
				cp $FOLDER/$tName/$GREENSOURCE_APP_UID.json $monkey_folder
				#copy the trace/measure lib
				#folds=($(find $FOLDER/$tName/ -type d | egrep -v "\/res|\/gen|\/build|\/.git|\/src|\/.gradle"))
				#for D in `find $FOLDER/$tName/ -type d | egrep -v "\/res|\/gen|\/build|\/.git|\/src|\/.gradle"`; do  ##RR
				#    if [ -d "${D}" ]; then  ##RR
				#    	$MKDIR_COMMAND -p ${D}/libs  ##RR
				#     	cp libsAdded/$treprefix$trepnLib ${D}/libs  ##RR
				#    fi  ##RR
				#done  ##RR
			done
		fi
	fi
done


