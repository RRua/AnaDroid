#!/bin/bash
ANADROID_SRC_PATH=$1
source $ANADROID_SRC_PATH/settings/settings.sh
source $ANADROID_SRC_PATH/settings/util.sh

instTests=($(adb shell pm list instrumentation | cut -f2 -d: | cut -f1 -d\ | cut -f1 -d/))
for i in ${instTests[@]}; do
	a=${i/%.test/}
	(adb shell pm uninstall $a)  > /dev/null  2>&1
	adb shell pm uninstall $i  > /dev/null  2>&1
	
	a=${i/%.tests/}
	(adb shell pm uninstall $a)  > /dev/null  2>&1
done
