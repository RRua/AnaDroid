"""
Copyright 2016 Shaiful Chowdhury, Stephanie Gil (shaiful@ualberta.ca, sgil@ualberta.ca)

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

import random
from random import randint

MAX_X=715  # actually 719, but this is safer
MIN_X=0
MAX_Y=1200  # actually 1277, but avoiding BACK, HOME, etc
MIN_Y=0
MAX_DURATION=3000
MIN_DURATION=1000
#KEYEVENTS=["ENTER","HOME"]
KEYEVENTS=["DEL","ENTER"] ### we don't need to press the home event (shaiful chowdhury)

class Event(object):

    def __init__(self, package=None):
        self.command = None
        self.package = package

    def get_command(self):
        return self.command   

class Swipe(Event):

    def __init__(self, package=None):
        x1 = str(random.choice([MIN_X+20, MAX_X-20]))
        y1 = str(random.choice([MIN_Y+100, MAX_Y-100]))
        x2 = str(random.choice([MIN_X+20, MAX_X-20]))
        y2 = str(random.choice([MIN_Y+100, MAX_Y-200]))
        self.command = "###### swipe ##########\ninput swipe " +x1+" "+y1+" "+x2+" "+y2+"\nsleep 2\n"




class Tap(Event):

    def __init__(self, package=None):
        x1 = str(random.randint(MIN_X+20, MAX_X-20))
        y1 = str(random.randint(MIN_Y+100, MAX_Y-100))
        duration = str(random.choice([0, 0, 0, 1000, 2000]))
        #self.command = self._tapnswipe_to_emu("tapnswipe /dev/input/event1 tap "\
         #                               +x1+" "+y1) \
          #              + "microsleep 4000000\n"
	self.command = "###### tap ##########\ninput tap " +x1+" "+y1+ "\nsleep 2\n"


### works only with real device 
"""
class LongPress(Event):

    def __init__(self, package=None):
        x = str(random.randint(MIN_X+20, MAX_X-20))
        y = str(random.randint(MIN_Y+100, MAX_Y-200))
        #duration = str(random.choice([1000]))
	self.command = "###### long press ##########\ntapnswipe /dev/input/event1 swipe  " +x+" "+y+" "+x+" "+y+" "+str(2000) \
                        + "\nsleep 2\n"
"""

class TapMenu(Event):
    def __init__(self, package=None):
        toss=randint(0,1)
	if toss==0:
        	self.command = "###### tap menu ##########\ninput keyevent 82\nsleep 2\ninput keyevent ENTER\nsleep 2\ninput keyevent ENTER\nsleep 2\n"
	else:
		self.command = "###### tap menu without enter##########\ninput keyevent 82\nsleep 2\n"
        
class KeyEvent(Event):
    
    def __init__(self, package=None):
        self.package = package

########## this is to have lot more ENTER than DEL
	count=0
	for i in range(5):
       		key = random.choice(KEYEVENTS)
		if key=="DEL":
			count=count+1
	if count>=4:
		key=="DEL"
	else:
		key=="ENTER"	
	
        if key == "HOME":    
            self.command = "input keyevent " + key + "\nsleep 2\n"\
                           + "monkey -p " + self.package \
                           + " -c android.intent.category.LAUNCHER 1\n"\
                           + "sleep 5\n"
        else:
            self.command = "###### key event ##########\ninput keyevent " + key + "\nsleep 2\n"
    
class Text(Event):
    def __init__(self, package=None):
        inputs = ["hello%sworld", "45"] 
	toss=randint(0,1)
	if toss==0:
        	self.command = "###### tap ##########\ninput tap 40 100\nsleep 2\n###### input text ##########\ninput text " + random.choice(inputs)\
                        + "\nsleep 2\n"\
                        + "input keyevent ENTER\nsleep 2\n"
	else:
		self.command = "###### input text ##########\ninput text " + random.choice(inputs)\
                        + "\nsleep 2\n"\
                        + "input keyevent ENTER\n sleep 2\n"
