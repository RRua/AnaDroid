# !/bin/bash


path=$1
test -z "$path" &&  path="$ANADROID_PATH/18_set_res/"
echo "searching results in $path"


get_date() {
    date --utc --date="$1" +"%Y-%m-%d %H:%M:%S"
}

min_crawler_tests=3
min_monkey_tests=14

for app_folder in $(find  $path  -mindepth 1 -maxdepth 1 -type d ); do
	
	for version_folder in $(find $app_folder  -mindepth 1 -maxdepth 1 -type d ); do
		#echo $version_folder
		how_many_monkey_execs=$(find $version_folder -maxdepth 3 -type d -name "MonkeyTest*" |wc -l)
		how_many_crawler_execs=$(find $version_folder -maxdepth 3 -type d -name "CrawlerTest*" |wc -l)
		#echo " $how_many_monkey_execs | $how_many_crawler_execs "
		test "$how_many_crawler_execs" -eq "0" && test "$how_many_monkey_execs" -eq "0" && echo "ai jasus so 0s" | xargs rm -rf "$version_folder" && continue
		if [[ "$how_many_monkey_execs" -gt "1" ]]; then
			#get execs

			candidates=$(find $version_folder -maxdepth 3 -type d -name "MonkeyTest*")
			most_recent=$(find $version_folder -maxdepth 3 -type d -name "MonkeyTest*" | head -1)
			mr_date=$(echo $most_recent |  xargs basename | sed 's#MonkeyTest##g' | xargs  -I{} date  -jf '%d_%m_%y_%H_%M_%S' +'%Y-%m-%d %H:%M:%S' {} ) 
			for mk_test in $candidates; do
				test_count=$(find $mk_test -name "GreendroidResultTra*" |wc -l)
				echo "monkey tests $test_count -> $test_count"
				cur_date=$(echo $mk_test |  xargs basename | sed 's#MonkeyTest##g' | xargs  -I{} date  -jf '%d_%m_%y_%H_%M_%S' +'%Y-%m-%d %H:%M:%S' {} ) 
				if [ "$cur_date" > "$mr_date" ] && [ "$test_count" -ge "$min_monkey_tests" ]  ; then
					#$cur_date é maior que $mr_date
					echo "bou substituir"
					rm -r "$most_recent"
					most_recent=$mk_test
					mr_date=$cur_date
				elif [[ "$cur_date" < "$mr_date" ]]; then
					#statements
					rm -r "$mk_test"
				fi

			done
		fi
		
		if [[ "$how_many_crawler_execs" -gt "1" ]]; then
			#get execs
			#echo " $how_many_crawler_execs inda é maior"
			
			candidates=$(find $version_folder -maxdepth 3 -type d -name "CrawlerTest*")
			most_recent=$(find $version_folder -maxdepth 3 -type d -name "CrawlerTest*" | head -1)
			mr_date=$(echo $most_recent |  xargs basename | sed 's#CrawlerTest##g' | xargs  -I{} date  -jf '%d_%m_%y_%H_%M_%S' +'%Y-%m-%d %H:%M:%S' {} ) 
			for craw_test in $candidates; do
				test_count=$(find $craw_test -name "GreendroidResultTra*" |wc -l)
				echo "crawl $test_count -> $test_count"
				
				cur_date=$(echo $craw_test |  xargs basename | sed 's#CrawlerTest##g' | xargs  -I{} date  -jf '%d_%m_%y_%H_%M_%S' +'%Y-%m-%d %H:%M:%S' {} ) 
				if [ "$cur_date" > "$mr_date" ] && [ "$test_count" -ge "$min_crawler_tests" ]  ; then
					#$cur_date é maior que $mr_date
					echo "bou substituir"
					rm -r "$most_recent"
					most_recent=$craw_test
					mr_date=$cur_date
				elif [[ "$cur_date" < "$mr_date" ]]; then
					#statements
					rm -r "$craw_test"
				fi

			done
			
		fi


	done

done