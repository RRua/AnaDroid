# !/bin/bash

min_tests=10
echo "au"
for f in  $(find $HOME/GDResults -maxdepth 1 -mindepth 1 -type d ); do 
	
	# minimum 1 test 
	how_many_monkeys=$(find $f -maxdepth 4 -type d -name "MonkeyTes*" | wc -l )
	echo "$f macacos $how_many_monkeys"
	test "$how_many_monkeys" -eq "0" && echo "ignoring $f" && continue 
	#get more than 2 versions
	how_many_versions=$(find $f -maxdepth 1 -mindepth 1 -type d | wc -l)
	test "$how_many_versions" -lt "3" && continue
	# get with more than 2 tfworks
	echo " version_folder in find $f -maxdepth 1 -mindepth 1 -type d); do"
	for version_folder in $(find $f -maxdepth 1 -mindepth 1 -type d); do
		echo "$version_folder"
		test_monkey_execs=$( find $version_folder -maxdepth 2 -type d -name "MonkeyTest*" )
		echo "tt $test_monkey_execs"
		how_many_tests=$(find $test_monkey_execs -maxdepth 3 -type f -name "GreendroidResultTrace")
		echo "$how_many_tests"
	done
done
