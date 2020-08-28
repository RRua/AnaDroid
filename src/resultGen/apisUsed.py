

import json,sys,os,re

# Linares Vasquez
red_apis_file=os.getenv("ANADROID_PATH")+"/resources/redAPIS.json"



# only needed fot tests executed before 27/08/2020
# created to undo error that caused malformed methoddefinitions in instrumentation phase
# remove later
# goal: to fix sh*t like this : sample.andremion.musicplayer.view.ProgressView->onMeasure.SavedState|-1183758944
# result : sample.andremion.musicplayer.view.ProgressView->onMeasure|-1183758944
def fixMethodDefinition(met_id):
	simpl_m_name= met_id.split("->")[1].split("|")[0]
	if(len(simpl_m_name.split("."))>1):
		met_id=met_id.replace(simpl_m_name,simpl_m_name.split(".")[0] )
	return met_id

def areMethodEquals(met1,met2id,met2_val):
	met2id = fixMethodDefinition(met2id)
	return met1['method_name'] == met2id.split("|")[0]  and len(met1['method_args']) == len(met2_val['method_args']) and ( met1['method_length'] == met2_val['method_length'] or met2_val['method_length']==-1 ) # and ( met1['method_locals'] == met2_val['method_locals'] or met2_val['method_locals']==-1 ) 

def methodWasInvoked(method_obj, traced_methods):
	#return method_obj['method_name'] in traced_methods
	return len (list(filter( lambda x : areMethodEquals(method_obj, x[0], x[1]  ), traced_methods.items() ))) > 0

def methodRedAPIs(method_obj, red_apis_obj):
	#print(method_obj['method_apis'])
	#print("-----\n")
	#print(red_apis_obj)
	l=[]
	for method_call in method_obj['method_apis']:
		
		if 'name' in method_call and method_call['name'] in red_apis_obj:
			l.append(method_call['name'])
	#m_apis=method_obj
	return l


def getRedApis(androguard_out_filename, all_traced_filename ):
	# load files
	red_apis_used={}
	with open(androguard_out_filename) as json_file:
		app_apis = json.load(json_file)
	
	with open(red_apis_file, encoding='utf-8') as json_file:
		red_apis = json.load(json_file)
		red_apis_dict={}
		for x in red_apis:
			red_apis_dict[x['fullMethodDefinition']]=x 

	with open(all_traced_filename) as json_file:
		traced_methods = json.load(json_file)
		traced_methods_dict={}
		#print(traced_methods.keys())
		for testid  in traced_methods.keys():
			traced_methods_dict[testid]={}
			for me , y in traced_methods[testid].items():
				#print(me)
				traced_methods_dict[testid][me]= y

	ct=0
	for classe in app_apis.values():
		for method in classe['class_methods'].values():
			for testid, test_methods in traced_methods_dict.items():
				if methodWasInvoked(method, test_methods):
					print("invocado %s" % method['method_name'] )
					l= methodRedAPIs(method, red_apis_dict)
					if len(l)>0:
						if not testid in red_apis_used:
							red_apis_used[testid]={}
						red_apis_used[testid][method['method_name']]=l
						ct=ct+1
	return red_apis_used , ct

if __name__ == '__main__':
	if len(sys.argv)>2:
		red_apis , ct = getRedApis(androguard_out_filename=sys.argv[1],all_traced_filename=sys.argv[2])
		print("methods with red apis: " + str(ct) )
		target_dir_path = os.path.dirname(os.path.realpath(sys.argv[2]))
		print("dumping to "+ str(target_dir_path) + "/redAPIs.json")
		with open( str(target_dir_path) + "/redAPIs.json", 'w') as outfile:
			json.dump(red_apis, outfile)
	else:
		print("bad input len. please provide androguard output file and allTracedMethods.json filepaths as args")