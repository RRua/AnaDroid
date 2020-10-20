#!/usr/bin/python

import xml.etree.ElementTree as ET
#from lxml import etree
import sys, os
import json


def parseXML(lintfile):	
	issues = {}
	try:
		tree = ET.parse(lintfile)
		root = tree.getroot()
	except Exception as e:
		print("Exception: {0}".format(e))
		print(lintfile)
		return
	#root == manifest
	for elem in root:
		sev = elem.attrib['severity']
		priority = elem.attrib['priority']
		category = elem.attrib['category']
		id_elem = elem.attrib['id']
		for subelem in elem:
			if subelem.tag== 'location':
				line = subelem.attrib['line'] if 'line' in subelem.attrib else None
				file = subelem.attrib['file'] if 'file' in subelem.attrib else None
		if category not in issues:
			issues[category] =[]

		issues[category].append ( ( sev,priority, id_elem, line, file ) )

	target_dir_path = os.path.dirname(os.path.realpath(lintfile))
	with open( str(target_dir_path) + "/lintIssues.json", 'w') as outfile:
			json.dump(issues, outfile)

def main(argv):
	for arg in argv:
		parseXML(arg)

if __name__ == "__main__":
   main(sys.argv[1:])