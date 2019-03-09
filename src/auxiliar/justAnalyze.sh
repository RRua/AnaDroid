#!/bin/bash
source $ANADROID_PATH/src/settings/settings.sh

res_folder="$ANADROID_PATH/resources"
GD_ANALYZER="$res_folder/jars/Analyzer.jar"
trace="-TestOriented"
GREENSOURCE_URL="http://localhost:8000/"
#GREENSOURCE_URL="http://greensource.di.uminho.pt/"
machine=''
getSO machine
if [ "$machine" == "Mac" ]; then
    SED_COMMAND="gsed" #mac
    MKDIR_COMMAND="gmkdir"
else 
    SED_COMMAND="sed" #linux
    MKDIR_COMMAND="mkdir"   
fi

OLDIFS=$IFS
DIR="$ANADROID_PATH/GDResults/*"

for f in $DIR/
    do
    rm -rf $f/TestResults.csv
    rm -rf $f/AppResults.csv
    #files=$(find $f -not \( -path $f/oldRuns -prune \) -name "Green*.csv")
    #$GD_ANALYZER $trace $projLocalDir/ $monkey
    #java -jar $GD_ANALYZER $trace $projLocalDir/ $monkey $GREENSOURCE_URL             
    java -Xmx5g -jar $GD_ANALYZER $trace $f "-Monkey" $GREENSOURCE_URL      ##RR  ##RR
done