# !/bin/bash

cwd=$(pwd)
for f in $(find "$HOME/GDResults" -type f -name "installedAPK.log" ); do
	echo "$f"
	folder_of_f=$(dirname $f)
	echo "$folder_of_f"
	app_trans_folder=$(cat $f | grep -o ".*_TRANSFORMED_/" )
	
	cd "$app_trans_folder"
	echo "changed dir, running gradle lint"
	test -f ./gradlew && ./gradlew lintDebug > lint.out 2>&1
	test ! -f ./gradlew  && gradle lintDebug > lint.out 2>&1
	res_file=$(find "$app_trans_folder" -type f -name "lint-results*.xml")
	cp $res_file "$folder_of_f"
	error_custom_jar_lint=$(cat lint.out | grep "java.lang.NoClassDefFoundError")
	test -n "$error_custom_jar_lint" && echo "1" > "$folder_of_f/error_lint.log"
	echo "$error_custom_jar_lint"
	echo "##### aji #########"
	cat lint.out
	
	cd "$cwd"
	
done