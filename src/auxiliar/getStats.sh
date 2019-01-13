source settings.sh

analyzerDir="jars/Analyzer.jar"
trace="-TraceMethods"
machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
    SED_COMMAND="gsed" #mac
    MKDIR_COMMAND="gmkdir"
    TAC_COMMAND="gtac"
else 
    SED_COMMAND="sed" #linux
    MKDIR_COMMAND="mkdir"
    TAC_COMMAND="tac"
fi

OLDIFS=$IFS
DIR="$HOME/GDResults/*"
#DIR="/Users/ruirua/GDResults/2bb46be6-f071-413d-9221-c090a8f0cb29/15_02_18_15_25_51"

#DIR="$HOME/GDResults/GDResults/*"
RESUME_FOLDER="Resume_Stats"
mkdir -p $RESUME_FOLDER
TEST_RESUME_FILE="TestResults.csv"
###############    STATS    ###################
total_apps=0
total_correct_apps=0
total_faulty_runs=0
#tests
total_tests=0
max_tests=0
avg_tests=0
tests_limit="0"
tests_list=()
tests_flag=0
#coverage
max_coverage=0
app_max_coverage=""
coverage_limit=0
coverage_list=()
coverage_flag=0
#app with more methods covered
max_methods=0
app_max_methods=""
#memory
max_mem=0
app_max_mem=""
avg_memory=0
total_memory=0
nr_total_memory=0
#energy
max_energy=0
app_max_energy=""
avg_energy=0
nr_total_energies=0
total_energy=0
energy_limit=0
energy_list=()
energy_flag=0
#bigger test (time)
max_time=0
app_max_time=""
avg_time=0
nr_total_time=0
total_time=0
#network (mobile data or wifi)
network_file="$RESUME_FOLDER/usesNetwork.txt"
wifi_min_state=2
mobile_data_state=3 #????
#GPS
gps_file="$RESUME_FOLDER/usesGPS.txt"
gps_min_state=2 #GPS State – Current state of the GPS system   0–GPSstopped1–GPSunknownstate2–GPSrunning
#Bluetooth
bluetooth_min_state=1
bluetooth_file="$RESUME_FOLDER/usesBluetooth.txt"

#:c no args :c: with args
while getopts ":e:n:c:t:" opt; do
  case $opt in
    c) #coverage
      echo "-c was triggered getting coverage above that, Parameter: $OPTARG" >&2
      flag_coverage=$( echo $OPTARG | grep "[-+]\?[0-9]*\.\?[0-9]\+")
      if [ -n $flag_coverage ] ; then 
        coverage_limit=$flag_coverage
        coverage_flag=1
        echo "limite : $coverage_limit"
      fi
      ;;
    e) #energy
      echo "-e was triggered getting energy above that, Parameter: $OPTARG" >&2
      flag_energy=$( echo $OPTARG | grep "[-+]\?[0-9]*\.\?[0-9]\+")
      if [ -n $flag_energy ] ; then 
        energy_limit=$flag_energy
        energy_flag=1
      fi 
      ;;
      # network
    t) #tests
      echo "-t was triggered getting nr tests above that, Parameter: $OPTARG" >&2
      flag_tests=$( echo $OPTARG | grep "[-+]\?[0-9]*\.\?[0-9]\+")
      if [ -n $flag_tests ] ; then 
        tests_limit=$flag_tests
        tests_flag=1
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


for f in $DIR/
    do
    echo "$f"
    #nr of tests
    nr_tests=$(find $f/ -maxdepth 2 -not \( -path $f/oldRuns -prune \) -name "Green*.csv" | wc -l)
    echo "qtos testes ? $nr_tests"
    if [ "$nr_tests" -gt "$max_tests" ]; then
    	max_tests=$nr_tests # apps with more tests
    	app_max_tests=$f
    fi
    total_tests=$(($total_tests + $nr_tests))
    bigger_than_tests_limit=$(echo "$nr_tests>=$tests_limit" | bc)
    #echo "limite -> $tests_limit || nr tests -> $nr_tests ||"
    #echo "bigger? -> $bigger_than_tests_limit ||"
    if [ "$bigger_than_tests_limit" -gt 0 ] ; then
        tests_list+=("$f")
        echo "mais1"
    fi


    # error missing files
    nr_traced_files=$(find $f -not \( -path $f/oldRuns -prune \) -name "TracedMethods*" | wc -l)
    nr_result_files=$(find $f -not \( -path $f/oldRuns -prune \) -name "Green*.csv" | wc -l)
    if [ "$nr_traced_files" -ne "$nr_result_files" ]; then
        total_faulty_runs=$(($total_faulty_runs + 1))  
    fi      
    echo "traced files -> $nr_traced_files"
    echo "result files -> $nr_result_files"
    #if nr of tests >0 , parse csv to get stats
    if [ "$nr_result_files" -ne 0 ]; then
        #total_faulty_runs=$(($total_faulty_runs + 1))  
        tests_coverage=$(cut -d, -f4  $f/$TEST_RESUME_FILE |  grep "[0-9]*\.\?[0-9]\+" | $TAC_COMMAND | grep -m 1 '.')
        echo "total coverage $tests_coverage"
        energy_consumption=$(cut -d, -f2  $f/$TEST_RESUME_FILE |  grep "[-+]\?[0-9]*\.\?[0-9]\+" )
        memory_consumption=$(cut -d, -f10  $f/$TEST_RESUME_FILE |  grep "[-+]\?[0-9]*\.\?[0-9]\+" )
        time_consumed=$(cut -d, -f3  $f/$TEST_RESUME_FILE |  grep "[-+]\?[0-9]*\.\?[0-9]\+" )
        wifi_consumed=$(cut -d, -f5  $f/$TEST_RESUME_FILE |  grep "[0-9]" )
        mobile_data_consumed=$(cut -d, -f6  $f/$TEST_RESUME_FILE |  grep "[0-9]" )
        gps_consumed=$(cut -d, -f14  $f/$TEST_RESUME_FILE |  grep "[0-9]" )
        bluetooth_consumed=$(cut -d, -f11  $f/$TEST_RESUME_FILE |  grep "[0-9]" )
        #energy_consumption=$(cut -d, -f2  $f/$TEST_RESUME_FILE |grep "[-+]\?[0-9]*\.\?[0-9]\+")
        #all_energy_consumption=$energy_consumption$all_energy_consumption
        
        # check if coverage is above limit
        echo " $tests_coverage"
        bigger_than_coverage_limit=$(echo "$tests_coverage>=$coverage_limit" | bc)
        if [ $bigger_than_coverage_limit -gt "0" ] ; then
            coverage_list+=("$f")
            echo "coverage = $tests_coverage"
        fi
        for line in $energy_consumption ; do
            total_energy=$(echo "$total_energy + $line" | bc)
            #echo "$line"
            result=$(awk 'BEGIN {print ("+'$line'" >= "+'$max_energy'")}')
            if [ "$result" -gt 0 ]; then
                max_energy=$line # apps with more tests
                app_max_energy=$f
            fi
            nr_total_energies=$(($nr_total_energies + 1))
        done
        for line in $memory_consumption ; do
            #echo "$line"
            total_memory=$(echo "$total_memory + $line" | bc)
            result=$(awk 'BEGIN {print ("+'$line'" >= "+'$max_mem'")}')
            if [ "$result" -gt 0 ]; then
                max_mem=$line # apps with more tests
                app_max_mem=$f
            fi
            nr_total_memory=$(($nr_total_memory + 1))
        done
        for line in $time_consumed ; do
            #echo "$line"
            total_time=$(echo "$total_time + $line" | bc)
            result=$(awk 'BEGIN {print ("+'$line'" >= "+'$max_time'")}')
            if [ "$result" -gt 0 ]; then
                max_time=$line # apps with more tests
                app_max_time=$f
            fi
            nr_total_time=$(($nr_total_time + 1))
        done
        for line in $wifi_consumed ; do
            if [ "$line" -ge $wifi_min_state ]; then
                (echo "$f" >> $network_file)
            fi
        done
        for line in $mobile_data_consumed ; do
            if [ "$line" -ge $mobile_data_state ]; then
                (echo "$f" >> $network_file)
            fi
        done
        for line in $gps_consumed ; do
            if [ "$line" -ge $gps_min_state ]; then
                (echo "$f" >> $gps_file)
            fi
        done
        for line in $bluetooth_consumed ; do
            if [ "$line" -ge $bluetooth_min_state ]; then
                (echo "$f" >> $bluetooth_file)
            fi
        done
        #nr_total_memory=$(($nr_total_memory - 1)) # to remove line from method coverage in testresults file
    fi
    total_apps=$(($total_apps + 1))
done
echo "######################### GLOBAL STATS #########################"
echo "TOTAL OF APPS ANALYZED : $total_apps Apps"
echo "total falty runs : $total_faulty_runs Apps"
echo "Correct Runned Apps : $(($total_apps - $total_faulty_runs))"
 avg_memory=$(echo "${total_memory}/${nr_total_memory}" | bc -l)
 #echo "que energia $all_energy_consumption"
 #avg_energy=$( awk '{ total += $2; count++ } END { print total/count }' $all_energy_consumption )
 echo "total energy -> $total_energy energies -> $nr_total_energies"
 echo "Avg memory -> $avg_memory"
 echo "total memory -> $total_memory"
 echo "total memories -> $nr_total_memory"
 avg_energy=$(echo "${total_energy}/${nr_total_energies}" | bc -l)
 echo "total tests -> $total_tests"
 echo "Max energy -> $max_energy | app : $app_max_energy"
 echo "Avg energy -> $avg_energy  "

 echo "total correct runs -> $total_correct_apps"
 echo "App with more tests : $app_max_tests -> $max_tests tests"
 
if [ "$coverage_flag" -gt 0 ]; then
    echo "Nº Apps with that coverage -> ${#coverage_list[@]}"
    for i in "${coverage_list[@]}"
    do
       x_tests=$(find $i -maxdepth 2 -not \( -path $i/oldRuns -prune \) -name "Green*.csv" | wc -l)
       echo "$i  nr of tests ->  $x_tests tests"
    done
fi

if [ "$tests_flag" -gt 0 ]; then
    echo "Apps with more than $tests_limit tests -> ${#tests_list[@]}"
    percentageTests=$(echo "${#tests_list[@]}/${total_apps}" | bc -l)
    echo "Percentage of apps with more than $tests_limit tests -> $percentageTests"
    echo "Apps with that more than $tests_limit tests -> ${tests_list[*]}"
fi

echo "################################################################"



