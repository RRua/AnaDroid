SRC_FOLDER="$ANADROID_PATH/src/"
source $SRC_FOLDER/settings/settings.sh

file_remote_json=$1
temp_folder="$ANADROID_PATH/demoProjects/"
#temp_folder="$ANADROID_PATH/fDroid_extractor/fdroidApps/"
#mkdir -p $temp_folder
target_file="data.json"
processAgain="TRUE"


unpack(){
	current_folder=$(pwd)
	if [[ -n "$(echo $filename| grep ".tar.gz")" ]]; then
		# tar.gz file
		echo "é tar.gz"
		cd $version_folder
		echo "$filename"
		result=$( (gunzip -c "$filename" | tar xopf - ) 2>&1  )
		echo "lo resultado-${result}-"
		if [[ -n "$(echo "$result" | grep "not in gzip format" )" ]]; then
			# Since it was not a gzipped file, a simple tar is able to extract the file
			#mkdir
			mkdir aux
			cp "$filename" "aux/"
			(find "aux/"  ! -path "aux/"  | xargs tar -xzvf) > /dev/null
			#tar xvf "$filename"
			rm -rf "aux"
		fi
		cd $current_folder
	elif [[ -n "$(echo $filename| grep ".zip")" ]]; then
		#statements
		echo "é zip"
		cd $version_folder;  unzip -a "$filename" ; cd $current_folder
	else
		echo "eu sei la"
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
	
	#delete previous runs
	find "$app_folder/" ! -path "$app_folder/"  -maxdepth 1 -type d | xargs rm -rf 
	
	data_json="$app_folder/$target_file"
	# create dir for each version
	python $SRC_FOLDER/auxiliar/multiple_version_executor_aux.py "$data_json"

	#iterate each version folder
	for version_folder in $(find $app_folder -maxdepth 1 ! -path $app_folder -type d  ); do
		e_echo "versione -> $version_folder"
		filename=$(find $version_folder  -maxdepth 1 -type f | grep -v "version.log")
		echo "Processing FF $filename FF"
		unpack
		folder_of_apk=$(find $version_folder -maxdepth 1 ! -path $version_folder -type d )
		echo "----------------------------------------"
		echo "----------------------------------------"
		echo "Processing $folder_of_apk"
		echo "----------------------------------------"
		echo "----------------------------------------"
		#echo  "$version_folder" > .ana/logs/processedApps.log
		was_processed=$(checkIfAlreadyProcessed $version_folder)
		if [ "$was_processed" == "TRUE" ] && [ "$processAgain" == "FALSE" ] ; then
			echo "Skipping already processed app"
		else
			anaDroid -a whitebox -d "$version_folder/" -f "monkey"
		fi
	done
done


