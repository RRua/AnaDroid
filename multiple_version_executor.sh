SRC_FOLDER="$ANADROID_PATH/src/"
source $SRC_FOLDER/settings/settings.sh

file_remote_json=$1
#temp_folder="$ANADROID_PATH/demoProjects/demoProjects/"
temp_folder="$ANADROID_PATH/demoProjects/fdroidApps/"
#mkdir -p $temp_folder
target_file="data.json"

unpack(){
	current_folder=$(pwd)
	if [[ -n "$(echo $filename| grep ".tar.gz")" ]]; then
		# tar.gz file
		echo "é tar.gz"
		cd $version_folder; gunzip -c "$filename" | tar xopf - ; cd $current_folder
	elif [[ -n "$(echo $filename| grep ".zip")" ]]; then
		#statements
		echo "é zip"
		cd $version_folder;  unzip -a "$filename" ; cd $current_folder
	else
		echo "eu sei la"
		continue
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
		filename=$(find $version_folder  -maxdepth 1 -type f)
		echo "Processing FF $filename FF"
		unpack
		folder_of_apk=$(find $version_folder -maxdepth 1 ! -path $version_folder -type d )
		echo "----------------------------------------"
		echo "----------------------------------------"
		echo "Processing $folder_of_apk"
		echo "----------------------------------------"
		echo "----------------------------------------"
		anaDroid -a whitebox -d "$version_folder/" -f "monkey"

	done

done


