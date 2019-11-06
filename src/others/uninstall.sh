#!/bin/bash

source $ANADROID_PATH/src/settings/settings.sh

PACKAGE=$1
TESTPACKAGE=$2

TAG="[APP REMOVER]"
echo ""

i_echo "$TAG Uninstalling previously installed apps"

#Uninstall the app
echo -n "$TAG Removing App: "
adb shell pm uninstall "$PACKAGE"

#Uninstall the tests
echo -n "$TAG Removing Tests: "
adb shell pm uninstall "$TESTPACKAGE" > /dev/null 2>&1
exit

## list apps
# adb shell pm list packages [-f]