#!/bin/bash

x='''for f in $(find aux_test_results_dir -type d -depth 2); do 
	has_reds=$(find $f -type f -name "red*" | xargs cat | wc -c)
	test "$has_reds" -le "10" &&  tg="aux_test_results_dir_redAPIS/sem/$(echo $f| xargs dirname)" 
	mkdir -p $tg 
	cp -r   $f $tg    
done'''


for f in $(find aux_test_results_dir -maxdepth 2 -mindepth 2 -type d); do 
	for red in $(find $f -type f -name "redAPIs.json" | grep "Monkey" ); do
		has_reds=$( cat $red | wc -c)
		red_parent=$(echo $red| xargs dirname | xargs dirname | sed 's#aux_test_results_dir/##g' )
		test "$has_reds" -lt "5" &&  tg="aux_test_results_dir_redAPIS/sem/$red_parent" && mkdir -p $tg  && cp -r "aux_test_results_dir/$red_parent" $tg    
		test "$has_reds" -gt "5" &&  tg="aux_test_results_dir_redAPIS/com/$red_parent" && mkdir -p $tg  && cp -r "aux_test_results_dir/$red_parent" $tg    
	done
done


# performance issues
x='''
for f in $(find aux_test_results_dir -maxdepth 2 -mindepth 2 -type d); do 
	perf_issues=$( find $f -name "all_data.csv" | xargs cat | grep -E "^average" | cut -f8 -d\; | grep -o -E "[0-9]+" | sort -n -r | head -1 )
	#echo "-$perf_issues-"
	(test -z "$perf_issues" || test "$perf_issues" -eq "0" ) && echo "olha $perf_issues" && tg="aux_test_results_dir_perfs_6_severity/sem/$(echo $f| xargs dirname)"  && mkdir -p $tg  && cp -r $f $tg && continue   
	#echo "-$perf_issues- tem" 
	test "$perf_issues" -gt "0" &&  tg="aux_test_results_dir_perfs_6_severity/com/$(echo $f| xargs dirname)"  && mkdir -p $tg  && cp -r $f $tg    
	done
'''å
x='''
api="androidx"
for app in $(find aux_test_results_dir/ -maxdepth 1 -mindepth 1 -type d); do 
	echo "$app" ; 
	for vers in $(find $app  -maxdepth 1 -mindepth 1 -type d); do 
		metsfile=$(find "$vers/all" -type f | grep -v "allMethods.json" )
		has_x=$(grep "$api" "$metsfile")
		vers_parent=$(echo $vers | xargs dirname | sed 's#aux_test_results_dir//##g')
		echo "$vers"
		test -n "$has_x"  && tg="aux_test_results_dir_${api}/com/$vers_parent" && mkdir -p $tg  && cp -r "$vers" $tg    
		test -z "$has_x"  && tg="aux_test_results_dir_${api}/sem/$vers_parent" && mkdir -p $tg  && cp -r "$vers" $tg    
		
		#test -n "$has_x" && echo "$(echo $vers | xargs basename ) tem"
		#test -z "$has_x" && echo "$(echo $vers | xargs basename ) nao tem" 
	done
	echo "-----"
done'''
