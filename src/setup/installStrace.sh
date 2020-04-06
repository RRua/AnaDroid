#!/bin/bash

adb shell su -c 'mount -o rw,remount /system /system'

adb push "$ANADROID_PATH/resources/strace" /sdcard/

#then copy the strace to /system/xbin

adb shell su -c 'cp /sdcard/strace /system/xbin'


adb shell su -c 'chmod 777 /system/xbin/strace'