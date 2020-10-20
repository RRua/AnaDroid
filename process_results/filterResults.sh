# !/bin/bash

# remove 0.0 versions ( unknow version code)
# find aux_test_results_dir/ -name "0.0" -type d | xargs rm -rf 


# remove unwanted files from extracted results

find pc1GDResults -type d -name "unpacked" | xargs rm -rf 
find pc1GDResults -type f -name "catlog*" | xargs rm -rf 


# copy categories file to eeverhy test exec dir
x="""for f in $(find aux_test_results_dir/ -type d -name "*Test*" ); do 
	appdir=$( echo $f | xargs dirname | xargs dirname ) 
	test -f $appdir/app_play_category.log" && echo "ha ficheiro" && cp "$appdir/app_play_category.log" $f
done
"""

copy_only_apps_with_atleast_one_test="""
for f in  $(find GDResults/ -maxdepth 1 -mindepth 1 -type d ); do
	nr_tests=$(find $f  -maxdepth 4 -mindepth 1 -type d -name "*Test*"|wc -l);
	test "$nr_tests" -gt "1" && cp -r $f 18_set_res/  ; done
"""
get_nr_apps_with_atleast_one_test_executed="""
for f in  $(find GDResults/ -maxdepth 1 -mindepth 1 -type d ); do find $f  -maxdepth 4 -mindepth 1 -type d -name "*Test*" | wc -l; done | grep -v "^[0-1]$" | wc -l
"""
