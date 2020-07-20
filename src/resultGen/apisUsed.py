

import json,sys,os,re

# Linares Vasquez
red_apis_file=os.getenv("ANADROID_PATH")+"/resources/redAPIS.json"




def getRedApis(filename):
	with open(filename) as json_file:
		app_apis = json.load(json_file)
	with open(red_apis_file) as json_file:
		red_apis = json.load(json_file)
	print((app_apis))
	#print(len(red_apis))


if __name__ == '__main__':
	if len(sys.argv)>1:
		getRedApis(sys.argv[1])
	else:
		print("bad input len. please provide androguard output file as arg")