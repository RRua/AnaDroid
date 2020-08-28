# !/bin/bash

#target_dir="$HOME/GDResults"
target_dir=$1
test -z "$target_dir" &&  target_dir="$ANADROID_PATH/pc1GDResults/28_jul_res/"
echo "la $target_dir"


GD_ANALYZER="$ANADROID_PATH/resources/jars/AnaDroidAnalyzer.jar"
test_framework="app_crawler" #"monkey" #"app_crawler" # monkey
orientation="-TestOriented"
prefix="CrawlerTest*" # "MonkeyTest*" # 
test "$test_framework" == "app_crawler" &&  flag="crawler"
test "$test_framework" == "monkey" &&  flag="monkey"
GREENSOURCE_URL="NONE"


rejection_0_power_samples_threshold=20

result_dir="aux_test_results_dir"


function validateThresholds(){
	for i in $power0_samples_percentage; do
		#statements
		is_bigger_than_thresold=$( echo "$i > $rejection_0_power_samples_threshold" | bc -l | grep -o "[0-1]")
		#echo "resultado pum-$is_bigger_than_thresold-"
		test "$is_bigger_than_thresold" == "1" && echo "TRUE" && return
	done
	echo "FALSE"
}

function analyzeResults(){
	java -jar $GD_ANALYZER $orientation "$version_results_dir" "-$flag" $GREENSOURCE_URL 2>&1 | tee "analyzerResult.out"
	power0_samples_percentage=$( grep "power samples" "analyzerResult.out" | cut -f2 -d\: |  grep -Eo '[0-9]+([.][0-9]+)?' )			
	#is_bigger_than_thresold=$( echo "$power0_samples_percentage > $rejection_0_power_samples_threshold" | bc -l | grep -o "[0-1]")
	#echo "resultado pum-$is_bigger_than_thresold-"
	has_power_errors=$(validateThresholds)
	if [[ "$has_power_errors" == "FALSE" ]]; then	
		echo "bou mover"
		moveRelevantFiles
		#getRedAPIS
	else
		# if fatal error occured during test exec, ignore
		echo "ai jasus mtos 0s"
		rm -rf "$app_res_dir"
	fi
	
}


# must be executed after the analysis
function moveRelevantFiles(){
	cp "$version_results_dir/cloc.out" "$app_res_dir/"
	
	find "$version_results_dir/" -maxdepth 1  -name "*resume.json" | xargs -I{} cp {} "$app_res_dir"
	cp "$version_results_dir/total_traced_methods.log" "$app_res_dir/"
	cp "$version_results_dir/total_coverage.log" "$app_res_dir/"
	cp "$version_results_dir/allTracedMethods.json" "$app_res_dir/"
	#
	find "$version_results_dir/all/" -type f -maxdepth 1 | xargs -I{} cp {} "$result_dir/$app_name/$app_version/all"
	#
	cp "$f/appPermissions.json" "$app_res_dir/"
	cp  "$f/installedAPK.log"  "$app_res_dir/"
	find "$f/" -maxdepth 1  -name "begin*.json" | xargs -I{} cp {} "$app_res_dir/"
	find "$f/" -maxdepth 1  -name  "end*.json" | xargs -I{} cp {} "$app_res_dir/"
	find "$f/" -maxdepth 1  -name  "Traced*.txt" | xargs -I{} cp {} "$app_res_dir/"
	find "$f/" -maxdepth 1  -name  "crawl_output/app_firebase_test_lab/*.png"  | xargs -I{} cp {} "$app_res_dir/"
	
	}


for f in $( find $target_dir -type d -name "$prefix" ); do
	is_old=$(echo $f | grep "oldRuns")
	echo "$f"
	if [ -n "$is_old" ]; then
		echo "velha"
		tf_and_date=$(basename $f )
		app_name=$(dirname $f| xargs dirname| xargs dirname | xargs basename )
		
		version_results_dir=$(dirname $f| xargs dirname)
		app_version=$(echo $version_results_dir | xargs basename)
		echo "la versione $app_version"
		
	else
		
		echo " nao é velha"
		tf_and_date=$(basename $f )
		app_name=$(dirname $f | xargs dirname |xargs basename )
		version_results_dir=$(dirname $f  )
		app_version=$(echo $version_results_dir | xargs basename)
		echo "versao $app_version"
		
	fi
	
	
	trepn_csvs_len=$(find $f -name "Green*.csv" | xargs cat | wc -l)
	test "$trepn_csvs_len" -eq "0" && continue


	target="${version_results_dir}/$(basename $f)"
	

	find "$version_results_dir/" -type f -name "*.json" | xargs rm 
    find "$version_results_dir/" -type f -name "*.log" | xargs rm 
	
	if [ -n "$is_old" ]; then
		ln -s  "$f" "$target"
	fi 
	app_res_dir="$result_dir/$app_name/$app_version/$tf_and_date"
	echo "$app_res_dir"
	
	echo "targeto -> $target"
	echo "fff $f"
	mkdir -p "$app_res_dir"
	mkdir -p "$result_dir/$app_name/$app_version/all"
	echo "la flag $flag"
	echo " java -jar $GD_ANALYZER $orientation $version_results_dir -$flag $GREENSOURCE_URL  "
	
	analyzeResults
	
	if [ -n "$is_old" ]; then
		rm -rf "$target"
	fi 
	
done 