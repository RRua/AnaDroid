SRC_FOLDER="$ANADROID_PATH/src/"
source $SRC_FOLDER/settings/settings.sh

file_remote_json=$1
temp_folder="$ANADROID_PATH/remote_projects"
gmkdir -p $temp_folder

unpack(){
	filename=$trimmed_url
	current_folder=$(pwd)
	if [[ -n "$(echo $filename| grep ".tar.gz")" ]]; then
		# tar.gz file
		echo "é tar.gz"

		cd $temp_folder; gunzip -c "$filename" | tar xopf - ; cd $current_folder
	elif [[ -n "$(echo $filename| grep ".zip")" ]]; then
		#statements
		echo "é zip"
		cd $temp_folder;  unzip -a "$filename" ; cd $current_folder
	else
		echo "eu sei la"
		continue
	fi

}




for url in $(grep -o '"project_location": *"[^"]*"' $1 | grep -o '"[^"]*"$'| sed 's%"%%g'); do
	#statements
	w_echo "Downloading Project with url:"
	e_echo "	$url"
	trimmed_url=$(echo $url | sed 's%https://f-droid.org/repo/%%g' | sed 's%http://greensource.di.uminho.pt/%%g' )
	curl $url --output "$temp_folder/$trimmed_url"
	echo "UNPACK"
	unpack
	echo "deleting file : rm -rf $temp_folder/$trimmed_url"
	e_echo "running anadroid in dir $(pwd)"
	anaDroid -d $temp_folder -f monkey
	rm -rf $temp_folder/*

done