# !/bin/bash

cwd=$(pwd)
target_dir="$HOME/18_set_res"
for f in $(find "$target_dir" -type f -name "installedAPK.log" ); do
	echo "$(date) - $f"
	folder_of_f=$(dirname $f)
	echo "$folder_of_f"
	app_trans_folder=$(cat $f | grep -o ".*_TRANSFORMED_/" | head -1 )
	echo "trans --  $app_trans_folder -- "	
	has_res_file=$(find "$app_trans_folder" -type f -name "lint-results*.xml")
	test -n "$has_res_file" && echo "ja tem" && ( find "$app_trans_folder" -type f -name "lint-results*.xml" | xargs -I{} cp  {} "$folder_of_f" ) && echo "este ja tinha " && continue  	
	
	test ! -d "$app_trans_folder" && echo " esta nao existe " && continue
	executed=$(grep "$app_trans_folder" lint_executed_apps.log )
	test -z "$executed" && echo "already executed " && continue
	echo "$app_trans_folder" >> lint_executed_apps.log
	cd "$app_trans_folder"
	echo "changed dir, running gradle lint"
	props_gradle=$( find $app_trans_folder -type f -name "gradle.properties" | head -1 )
	test -f "$props_gradle" && echo "\norg.gradle.jvmargs=-Xms256m -Xmx4048m" >> "$props_gradle"
	
	
	test -f ./gradlew && ./gradlew lint > lint.out 2>&1
	test ! -f ./gradlew  && gradle lint > lint.out 2>&1
	res_file=$(find "$app_trans_folder" -type f -name "lint-results*.xml" | xargs -I{} cp {} "$folder_of_f" )
	error_custom_jar_lint=$(cat lint.out | grep "java.lang.NoClassDefFoundError")
	test -n "$error_custom_jar_lint" && echo "1" > "$folder_of_f/error_lint.log"
	echo "$error_custom_jar_lint"
	echo "##### aqui #########"
	cat lint.out

	cd "$cwd"
done