# !/bin/bash

res_folder="/home/greenlab/GDResults/"

for vers_folder in $( find "$res_folder" -maxdepth 2 -type d -name "0\.0" ); do
	echo $vers_folder
	for apk_i in $( find $vers_folder -type f -name "installedAPK.log" ); do
		
		apk=$(head -1 "$apk_i")
		folder_of_f=$( echo $apk_i | xargs dirname )
		test ! -f $apk && echo "ja nao existe " &&  continue
		apk_v=$(apkanalyzer manifest version-name $apk)
		if [[ "$apk_v" == "?" ]]; then
			apk_v=$(echo $apk | sed 's/_TRANSFORMED_/#/g' | cut -f1 -d# | xargs dirname|xargs basename | sed 's/_src//g')
		fi
		new_folder_of_test=$( echo $folder_of_f  | sed "s#0\.0#${apk_v}#g" )
		is_old=$( echo "$new_folder_of_test" | grep "oldRuns" )
		test -n "$is_old" && old_version_base_folder=$( echo "$folder_of_f" | xargs dirname | xargs dirname)
		test -z "$is_old" && old_version_base_folder=$( echo "$folder_of_f" | xargs dirname)
		

		new_folder_of_version=$( echo $old_version_base_folder  | sed "s#0\.0#${apk_v}#g" )
		mkdir -p "$new_folder_of_version/all"
		
		apk_trans_folder=$(echo "$apk" | grep -o ".*_TRANSFORMED_/")

		cp "$apk_trans_folder/cloc.out" "$new_folder_of_version/"
		cp "$apk_trans_folder/allMethods.json" "$new_folder_of_version/all/"
		find "$apk_trans_folder/" -maxdepth 1 -type f -name "*.json" | grep "\-\-" | xargs -I{} cp {} "$new_folder_of_version/all/"
		mkdir -p "$new_folder_of_test"
		mv  "$folder_of_f/" "$new_folder_of_test/"
		
	done
done

x="""
for f in $( find aux_test_results_dir/ -maxdepth 1 -mindepth 1 -type d ); do an=$(echo $f | xargs basename ) ;  categ=$(grep $an app_categories_dict.json | head -1);  sc=$(echo $categ | cut -f2 -d\: | sed 's/"//g' | sed 's/,//g' );     for t in $(find $f -type d -name "*Test*" ); do echo "$sc" > "$t/app_play_category.log" ; done ; done
"""