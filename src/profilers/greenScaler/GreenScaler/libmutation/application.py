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

import cpu
import test
import syscall
import color
import os
class Application:
    
	def __init__(self, apk, package, runTestCommand=None):
		self.apk=apk
		self.cpu=cpu.CPU()
		self.syscall=syscall.SYSCALL(package)
		self.color=color.RGB(package)
		self.test=test.Test(apk, runTestCommand)
		self.package = package
		#self.syscalls=Syscalls()
		#self.rgb=RGB()	


	def stop_app(self):
		os.system("adb shell am force-stop " + self.package)
	
	def stop_and_clean_app(self):
		#os.system("adb shell pm clear" + self.package)
		self.stop_app()
		os.system("adb shell pm clear " + self.package)

