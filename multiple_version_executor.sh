SRC_FOLDER="$ANADROID_PATH/src/"
source $SRC_FOLDER/settings/settings.sh

file_remote_json=$1
temp_folder="$ANADROID_PATH/demoProjects/appsSauce/"
#temp_folder="$ANADROID_PATH/fDroid_extractor/fdroidApps/"
#mkdir -p $temp_folder
target_file="data.json"
processAgain="TRUE"
logDir="$ANADROID_PATH/.ana/logs"

unpack(){
	current_folder=$(pwd)
	if [[ -n "$(echo $filename| grep ".tar.gz")" ]]; then
		# tar.gz file
		cd $app_folder
		result=$( (gunzip -c "$filename" | tar xopf - ) 2>&1  )
		if [[ -n "$(echo "$result" | grep "not in gzip format" )" ]]; then
			# Since it was not a gzipped file, a simple tar is able to extract the file
			mkdir aux
			cp "$filename" "aux/"
			(find "aux/"  ! -path "aux/"  | xargs tar -xzvf) &> /dev/null
			rm -rf "aux"
		fi
		cd $current_folder
	elif [[ -n "$(echo $filename| grep ".zip")" ]]; then
		# zip file
		cd $app_folder; mkdir "${filename}_src";  (unzip -a -o "$filename" -d "${filename}_src") >/dev/null ; cd $current_folder
	
	elif [ ! -d "$filename" ]; then
		cd $app_folder; mkdir "${filename}_src"; ( unzip -a -o "$filename" -d "${filename}_src" ) > /dev/null ; cd $current_folder
	else
		echo "filename" > "$logDir/unpackError.log" 
		continue
	fi

}


checkIfAlreadyProcessed(){
	app_folder=$1
	is_processed=$(grep "$app_folder" .ana/logs/processedApps.log)
	if [[ -n "$is_processed" ]]; then
		echo "TRUE"
	else
		echo "FALSE"
	fi
}


for app_folder in $( find $temp_folder  ! -path $temp_folder -maxdepth 1 -type d ); do
	echo "$app_folder"
	#delete previous runs
	#find "$app_folder/" ! -path "$app_folder/"  -maxdepth 1 -type d | xargs rm -rf 
	
	#data_json="$app_folder/$target_file"
	# create dir for each version
	#python $SRC_FOLDER/auxiliar/multiple_version_executor_aux.py "$data_json"

	#iterate each version folder
	for version_pack in $(find $app_folder -maxdepth 1 ! -path $app_folder  ); do
		#filename=$(find $version_folder  -maxdepth 1 -type f | grep -v "version.log")
		filename=$version_pack
		echo "$filename"
		unpack
		#folder_of_apk=$(find $version_folder -maxdepth 1 ! -path $version_folder -type d )
		#echo "Processing $folder_of_apk"
		#was_processed=$(checkIfAlreadyProcessed $version_folder)
		if [ "$was_processed" == "TRUE" ] && [ "$processAgain" == "FALSE" ] ; then
			echo "Skipping already processed app"
		else
			#echo "x"
			anaDroid -d "${version_pack}_src" -f "monkeyrunner" -m "resources/sample_tests/monkeyrunner_example_script.py"
		fi
	done
done


