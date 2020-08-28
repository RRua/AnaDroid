# !/bin/bash


for app in $(find  aux_test_results_dir -maxdepth 1 -mindepth 1 -type d  ); do 
	
	how_many_majors=$( find $app -maxdepth 1 -mindepth 1 -type d | xargs basename | cut -f1 -d\.  |grep  -o "[0-9]" | sort -u | wc -l )
	if [[ "$how_many_majors" -ge "3" ]]; then
		echo "$app"
		cp -r "$app" "aux_test_results_dir_so_apps_3_majors/"
	fi
	
done