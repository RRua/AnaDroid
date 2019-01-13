#!/bin/bash
# invocation : ./anaDroid 
TEST_ORIENTATION="-TestOriented"
URL="http://greensource.di.uminho.pt/"
PROFILER="Trepn"
TEST_FRAMEWORK="Monkey"
SRC_FOLDER="src/"
source $SRC_FOLDER/settings/settings.sh

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
    TEST_ORIENTATION="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--framework)
    TEST_FRAMEWORK="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--profiler)
    PROFILER="$2"
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

i_echo   "##############################################################################"
i_echo   "###                          ANADROID TOOL                      greenlab™  ###"
i_echo   "##############################################################################"
echo ""
echo URL  = "${URL}"
echo TEST_ORIENTATION     = "${TEST_ORIENTATION}"
echo TEST_FRAMEWORK    = "${TEST_FRAMEWORK}"
echo PROFILER    = "${PROFILER}"
echo DEFAULT         = "${DEFAULT}"
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
fi


if [[ "$TEST_FRAMEWORK" == "Monkey" ]]; then
	#statements
	./$SRC_FOLDER/monkeyScript.sh $TEST_ORIENTATION $URL
fi





