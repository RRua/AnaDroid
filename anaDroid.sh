#!/bin/bash
# invocation : ./anaDroid 
ANADROID_PATH=$(pwd)
SRC_FOLDER="$ANADROID_PATH/src/"
source $SRC_FOLDER/settings/settings.sh

#ANADROID FINAL CONFIG
SUPPORTED_TESTING_FRAMEWORKS=( "monkey" "junit" )
SUPPORTED_PROFILERS=( "trepn" )
SUPPORTED_MONITORING_TYPES=( "testoriented"  "methodOriented" )
#ANADROID DEFAULT CONFIG
TEST_ORIENTATION="testoriented"
URL="http://greensource.di.uminho.pt/"
PROFILER="trepn"
TEST_FRAMEWORK="monkey"
APP_BUILD_TYPE="debug"
TARGET_DIR="$(pwd)/demoProjects/*"

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return -1
}

processAndValidateArguments(){
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
    key="$1"
    case $key in
        -u|--url)
        URL="$2"
        shift # past argument
        shift # past value
        ;;
        -o|--orientation)
        lower2=$( echo "$2" | awk '{print tolower($0)}' )
        containsElement "${lower2}" "${SUPPORTED_MONITORING_TYPES[@]}"
        RET=$?
        if [ $RET -ge 0 ]; then
            TEST_ORIENTATION="${SUPPORTED_MONITORING_TYPES[$RET]}"
            echo TEST_ORIENTATION     = "${TEST_ORIENTATION}"
        else
            e_echo "ANADROID doesn't suport \"$2\" monitoring type ... Assuming Test Oriented (default) as required monitoring type"
        fi
        shift # past argument
        shift # past value
        ;;
        -f|--framework)
        lower2=$( echo "$2" | awk '{print tolower($0)}' )
        containsElement "${lower2}" "${SUPPORTED_TESTING_FRAMEWORKS[@]}"
        RET=$?
        if [ $RET -ge 0 ]; then
            TEST_FRAMEWORK="${SUPPORTED_TESTING_FRAMEWORKS[$RET]}"
            echo TEST_FRAMEWORK     = "${TEST_FRAMEWORK}"
        else
            e_echo "ANADROID doesn't suport \"$2\" framework ... Assuming Monkey (default) as required framework"
        fi
        shift # past argument
        shift # past value
        ;;
        -p|--profiler)
        lower2=$( echo "$2" | awk '{print tolower($0)}' )
        containsElement "${lower2}" "${SUPPORTED_PROFILERS[@]}"
        RET=$?
        if [ $RET -ge 0 ]; then
            PROFILER="${SUPPORTED_PROFILERS[$RET]}"
            echo PROFILER     = "${PROFILER}"
        else
            e_echo "ANADROID doesn't suport \"$2\" profiler ... Assuming Trepn (default) as required profiler"
        fi
        shift # past argument
        shift # past value
        ;;
        -b|--build)
        lower2=$( echo "$2" | awk '{print tolower($0)}' )
        if [ "$lower2" == "debug" ] || [ "$lower2" == "release" ]  ; then
            APP_BUILD_TYPE="$lower2"
        fi
        shift # past argument
        shift # past value
        ;;
        -u|--url)
        lower2=$( echo "$2" | awk '{print tolower($0)}' )
        if [ "$lower2" == "localhost" ]; then
            w_echo "sending to http://localhost:8000/"
            URL="localhost"
        else
             w_echo "sending to $URL"
        fi

        shift # past argument
        shift # past value
        ;;
        -s|--silent)
            # TODO 
            w_echo "RUNNING on silent mode. Not submitting results to GreenSource database"
            URL="NONE"
        shift # past argument
        shift # past value
        ;;
        ;;
        -d|--dir)
            # TODO 
            TARGET_DIR=$2

        shift # past argument
        shift # past value
        ;;
        --default)
        DEFAULT=YES
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters
    if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
    fi
}

# TODO put this in settings.sh or util.sh
printf_new() {
     str=$1
     num=$2
     local v=$(printf "%-${num}s" "$str")
     i_echo "${v// /#}"
}
printAnaDroidHeader(){
    columns_left=0
    columns=$(echo -e "\ncols"|tput -S)
    printf_new '#' $columns
    # print anadroid tool line
    v=$(printf "%-3s" "#")
    columns_left=$(($columns - 28 ))
    if [[ $columns_left -ge 0 ]]; then
        spaces=$(echo "$columns_left / 2 " | bc )
        v="$v$(printf "%-${spaces}s" " ")"
        v="$v$(printf "ANADROID TOOL")"
        v="$v$(printf "%-${spaces}s" " ")"

    fi
    v="$v$(printf "%-3s" "#")"
    i_echo "${v// /#}"
}

printf_new "#" "$(echo -e "\ncols"|tput -S)"
#i_echo   "\n##############################################################################"
#i_echo   "###                          ANADROID TOOL                      greenlab™  ###" #28
i_echo   "###  ANADROID TOOL " #                     greenlab™  ###"
i_echo   "###  greenlab™  "
printf_new "#" "$(echo -e "\ncols"|tput -S)"
i_echo   "### Check our work at: http://greenlab.di.uminho.pt/ " #                       ###"
printf_new "#" "$(echo -e "\ncols"|tput -S)"
echo ""
processAndValidateArguments "$@"
echo URL  = "${URL}"
echo TEST_ORIENTATION     = "${TEST_ORIENTATION}"
echo TEST_FRAMEWORK    = "${TEST_FRAMEWORK}"
echo PROFILER    = "${PROFILER}"
echo APP_BUILD_TYPE    = "${APP_BUILD_TYPE}"
#echo DEFAULT         = "${DEFAULT}"

if [ "$TEST_FRAMEWORK" == "monkey"  ]; then
	#statements
	$SRC_FOLDER/monkeyScript.sh $ANADROID_PATH $TEST_ORIENTATION $URL $APP_BUILD_TYPE $TARGET_DIR
elif [ "$TEST_FRAMEWORK" == "junit" ]; then
    e_echo "Currently Not available. We are working on that. Sorry"
fi






