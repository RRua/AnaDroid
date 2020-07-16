import json,sys,os,re


enabled_state=1
disabled_state=0

permissionStateMatch  = {
	"ACCESS_FINE_LOCATION" : "gps_state",
	"BLUETOOTH" : "bluetooth_state",
	"BLUETOOTH_ADMIN" : "bluetooth_state",
	"BLUETOOTH_PRIVILEGED" : "bluetooth_state",
	"INTERNET" : "wifi_state",
	"NFC" : "nfc_state",
	"NFC_TRANSACTION_EVENT" : "nfc_state"
}


def loadDefaultTestConfigurations():
	default_file=(os.getenv("ANADROID_PATH")+"/defaultTestConfig.cfg")
	json_def={}
	with open(default_file, 'r') as filehandle:
		for line in filehandle.read().splitlines():
			if re.match(r'\w+\=[0-9]+',line):
				x1,x2= line.split("#")[0].split("=")
				json_def[x1]= x2.strip()
	return json_def

def writeDefinedTestConfigurations(config_json):
	text_file = open(os.getenv("ANADROID_PATH")+"/testConfig.cfg", "w")
	for x,y in config_json.items():
		text_file.write(str(x)+"="+str(y)+"\n")
	text_file.close()
	


def deriveTestConditionsFromPermissions(perms_list):
	def_config_json = loadDefaultTestConfigurations()
	interest_new_testing_state= map ( lambda z :  permissionStateMatch[z.upper()] , filter(lambda x : x.upper() in permissionStateMatch, perms_list ))
	#final_config_json = {k:   for k, v in my_dictionary.items()}
	for f in interest_new_testing_state:
		def_config_json[f]=enabled_state
		print("[ defineTestConditions ] defining " + f + " as enabled")
	return def_config_json

def loadPermissions(filename):
	with open(filename) as json_file:
		data = json.load(json_file)
	return  map( lambda x : x['permission'] , data ) 

if __name__== "__main__":
	if len(sys.argv) > 1:
		perms=loadPermissions(sys.argv[1])
		new_configs=deriveTestConditionsFromPermissions(perms)
		writeDefinedTestConfigurations(new_configs)
		#print(perms)
		
	else:
		print ("arg required ( permissions filename )")

