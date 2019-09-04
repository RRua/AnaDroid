# Imports the monkeyrunner modules used by this program
from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
from os import sys



def dummy_test(apk_location, activity_name):
	# Connects to the current device, returning a MonkeyDevice object
	device = MonkeyRunner.waitForConnection()
	#print(dir(device))
	# Installs the Android package. Notice that this method returns a boolean, so you can test
	# to see if the installation worked.
	device.installPackage(apk_location)

	# sets a variable with the package's internal name
	#package = 'com.ruirua.footexam'

	# sets a variable with the name of an Activity in the package
	#activity =  package + "." + "LoginActivity" #'com.example.android.myapplication.MainActivity'

	# sets the name of the component to start
	#runComponent = package + '/' + activity_name
	runComponent = activity_name
	# Runs the component
	device.startActivity(component=runComponent)
	# Presses the Menu button
	device.press('KEYCODE_MENU', MonkeyDevice.DOWN_AND_UP)
	# Takes a screenshot
	result = device.takeSnapshot()
	# Writes the screenshot to a file
	result.writeToFile('1.png','png')


if __name__== "__main__":
	if len(sys.argv) > 1:
		dummy_test(sys.argv[1], sys.argv[2])
	else:
		print ("at least 2 args required ( <apk-path> <package-name>  )")
