# -*- coding: utf-8 -*-
from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
from os import sys
import time


def dummy_test(apk_location, pack_name):
	device = MonkeyRunner.waitForConnection()
	device.shell("monkey -p "+pack_name +" -c android.intent.category.LAUNCHER 1")
	time.sleep(5)
	result = device.takeSnapshot()
	result.writeToFile( pack_name+ "_main.png",'png')


if __name__== "__main__":
	if len(sys.argv) > 1:
		dummy_test(sys.argv[1], sys.argv[2])
	else:
		print ("at least 2 args required ( <apk-path> <package-name>  )")
