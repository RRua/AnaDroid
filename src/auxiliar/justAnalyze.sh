#!/bin/bash
source settings.sh

analyzerJar="jars/Analyzer.jar"
trace="-TestOriented"
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
DIR="/Users/ruirua/Documents/Tese/resultados/GDResults/relevant40/*"

for f in $DIR/
    do
    rm -rf $f/TestResults.csv
    rm -rf $f/AppResults.csv
    #files=$(find $f -not \( -path $f/oldRuns -prune \) -name "Green*.csv")
    #$GD_ANALYZER $trace $projLocalDir/ $monkey
    java -Xmx5g -jar $analyzerJar $trace $f "-Monkey"  ##RR  ##RR
done