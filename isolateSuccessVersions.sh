# !/bin/bash

default_location="/home/greenlab/Anadroid/demoProjects"
#default_location="./samples"

target_success_apps_dir="$HOME/successAppsFolder"

#for version in $(cat suc.log); do 
for version in $(cat $ANADROID_PATH/.ana/logs/success.log); do 
	folder_version=$(grep "$version" $ANADROID_PATH/.ana/logs/processedApps.log )
	target_app_dir=$( dirname $folder_version | xargs dirname | xargs basename  )
	version_app_dir=$( dirname $folder_version  | xargs basename  )

	echo "$version  -   $target_app_dir --  $version_app_dir"
	target_dir="$target_success_apps_dir/$target_app_dir/$version_app_dir"
	echo "creating $target_dir"
	
	if [ -d "$target_dir" ]; then 
		echo "ja existe"	
		continue
	fi
	mkdir -p "$target_dir"
	cp -r $folder_version $target_dir
	
	#echo "cp -r $folder_version $target_success_apps_dir"
	#exit 0
	#version_pack=$(find $default_location -mindepth 3 -maxdepth 4 -name $version -type f )
	#echo "folder - $version_pack"
	#app_name=$( echo "$version" | cut -f9 -d\/ ) #"sed 's#'"${default_location}"'##g' )
	#echo "->$app_name"
	#mkdir -p "outDir/$app_name"
	#cp $version_pack "outDir/$app_name"

done
