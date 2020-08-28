# !/bin/bash

result_dir="$ANADROID_PATH/aux_test_results_dir"

for app_folder in $(find $result_dir -maxdepth 1 -mindepth 1 -type d); do
	for version_folder in $(find $app_folder  -mindepth 1 -maxdepth 1 -type d ); do
		androguard_file=$(find $version_folder/all/ -type f -name "*.json" | grep -v "allMethods.json")
		test -z "$androguard_file" && continue
		for traced_methods_file in $(find $version_folder  -type f -name "allTracedMethods.json"); do
			echo "analyzing $traced_methods_file"
			echo "python3 $ANADROID_PATH/src/resultGen/apisUsed.py $androguard_file $traced_methods_file"
			python3 "$ANADROID_PATH/src/resultGen/apisUsed.py" "$androguard_file" "$traced_methods_file"
			
		done
	done
done