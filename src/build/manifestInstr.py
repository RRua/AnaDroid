#!/usr/bin/python

import xml.etree.ElementTree as ET
#from lxml import etree
import sys



def insertReadWritePerms(file):
	#
	
	try:
		tree = ET.parse(file)
		root = tree.getroot()
	except Exception as e:
		print("Exception: {0}".format(e))
		return
	#root == manifest
	#hasPermission(root,"android.permission.READ_EXTERNAL_STORAGE")
	root.set( "xmlns:android", "http://schemas.android.com/apk/res/android")
	
	
	#ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
	read = ET.SubElement(root, 'uses-permission')
	read.set('android:name', 'android.permission.READ_EXTERNAL_STORAGE')
	
	write = ET.SubElement(root, 'uses-permission')
	write.set('android:name', 'android.permission.WRITE_EXTERNAL_STORAGE')
	tree.write(file)


def main(argv):
	for arg in argv:
		insertReadWritePerms(arg)

if __name__ == "__main__":
   main(sys.argv[1:])