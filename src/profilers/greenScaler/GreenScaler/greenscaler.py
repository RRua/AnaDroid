"""
Copyright 2016 Shaiful Chowdhury (shaiful@ualberta.ca)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import sys, argparse, time, threading
from libmutation import utils, application,model
import os
import time
import sys
import shutil
import commands
from os import listdir
import subprocess
from random import randint
import re

EVENT_PATH = "/dev/input/event1"

def cleaning(pkg, apk):

	print "Uninstall app if already installed"
	utils.uninstall_app(pkg)
	print "Install app"
	utils.install_app(apk)


# 
def cpu_measurement(app, apk_file, n, package, test_cmd):
	
	for i in range(n):          
		cleaning(package, apk_file)
		print "Start cpu profiling"
		print("sleeping")
		time.sleep(5)
		app.cpu.cpu_before(package)
		print "Running application"
		duration=app.test.run(test_cmd)
		app.cpu.duration=app.cpu.duration+duration
		print "total duration=",duration
		app.cpu.cpu_after(package)
		print "Collect CPU measurements"
		app.cpu.pull_cpu(package)

		print("jack -> "+ str(apk_file[:-4]))
		app.cpu.count_cpu(apk_file[:-4])
		

def syscall_trace(app, apk_file, n, package,  test_cmd):
	for i in range(n):      
		while 1:
			print "running ", str((i+1))+"th round of strace"   
			cleaning(package, apk_file)
			time.sleep(5)
			print "Start syscall tracing"   
			app.syscall.syscall_capture()
			print "syscall tracing started"
			print "Running application"
			#conv= ' '.join([str(i) for i in test_cmd])
			duration=app.test.run(test_cmd)
			print "Stop Syscall tracing"
			app.syscall.syscall_stop()
			print "Pull syscall traces"
			app.syscall.pull_syscall()
			trap=app.syscall.count_syscall()
			if trap==1: ##### strace worked
				print("Syscall worked")
				break
			else:
				print("Syscall did not work this time\nStarting this round again")

def screen_capture(app, apk_file, n, package,test_cmd):

		cleaning(package, apk_file)
		app.color.capture_images()
		print "Running application"
		app.test.run(test_cmd)
		utils.uninstall_app(package)
		app.color.pull_images()
		app.color.delete_images()
	
		no_img=0
		for img in listdir(utils.IMAGE_PATH+package+"/screen_shots/"):
			
			no_img=no_img+1
		print "total captured_images="+str(no_img)
		if no_img>=1:
			app.color.calculate_rgb()
			utils.uninstall_app(package)
			return 1
		else:
			print "Images were not captured properly"
			print"=================================================================="
			print"=================================================================="   
			return 0




def default_greenscaler(n_runs=1):
	n = n_runs
	for apk_file in sorted(listdir(utils.APKS_PATH)):
		########### Find package name and main_activity from the apk
		try:
			st=str(commands.getstatusoutput(utils.AAPT_PATH+"aapt dump badging "+utils.APKS_PATH+apk_file))
			start="package: name=\'"
			end="\' versionCode="
			package=((st.split(start))[1].split(end)[0])
			print("lo packkko " +str(package))
			start="launchable-activity: name=\'"
			end="\'  label=\'"  
			main_activity=((st.split(start))[1].split(end)[0])
		
				#pid = utils.clean_up(package, utils.APKS_PATH+apk_file)
		except:
			print "Could not find Package name"
			continue
		print "=========================================================="
		
		### initialize an app with zero resource usage
		print(apk_file)
		app=application.Application(apk_file, package,runTestCommand=run_test)
		
		######## Capture all    
		print "capture cpu and others for "+str(n), " times"
		cpu_measurement(app, apk_file, n, package)
		print "capture system calls"
		syscall_trace(app, apk_file, n, package)
		print "Now run to capture screen shots"
		while 1:
			n_image=screen_capture(app, apk_file, n, package)
			if n_image==1:
				break

		energy=model.estimate_energy(apk_file, app, n)
		print "Energy ="+str(energy)+" Joules"
	
	


def exec_command(self,command ):
	#subprocess.call(command)
	print("executing command -%s-" % command)
	pipes = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
	#If you are using python 2.x, you need to include shell=True in the above line
	std_out, std_err = pipes.communicate()

	if pipes.returncode != 0:
	    # an error happened!
	    err_msg = "%s. Code: %s" % (std_err.strip(), pipes.returncode)
	    raise Exception(err_msg)

	elif len(std_err):
		print(std_out)
	    # return code is 0 (no error), but we may want to
    # do something with the info on std_err
    # i.e. logger.warning(std_err)


def exec_greenscaler(apk_file,test_cmd ):
	n=1
	try:
		st=str(commands.getstatusoutput(utils.AAPT_PATH+"aapt dump badging "+apk_file))
		start="package: name=\'"
		end="\' versionCode="
		package=((st.split(start))[1].split(end)[0])
		start="launchable-activity: name=\'"
		end="\'  label=\'"  
		main_activity=((st.split(start))[1].split(end)[0])
			#pid = utils.clean_up(package, utils.APKS_PATH+apk_file)
	except:
		print "Could not find Package name"
	print "=========================================================="
	### initialize an app with zero resource usage
	app=application.Application(apk_file, package, runTestCommand=exec_command)
	print("executing test")
	cpu_measurement(app, apk_file, n, package,test_cmd )
	print "capture system calls"
	syscall_trace(app, apk_file, n, package,test_cmd)
	print "Now run to capture screen shots"
	while 1:
		n_image=screen_capture(app, apk_file, n, package, test_cmd)
		if n_image==1:
			break

	energy=model.estimate_energy(apk_file, app, n)
	print "Energy ="+str(energy)+" Joules"


	




if __name__=='__main__':
					
	if len(sys.argv)>2:
		apkfile=sys.argv[1]
		print("Lo apk %s" % apkfile)
		exec_greenscaler(apkfile, ' '.join(sys.argv[2:]))      
	else:
		print ("bad arg len. Usage: python greenscaler <apk-path> [cmd and args]")
		exit(-1)






		