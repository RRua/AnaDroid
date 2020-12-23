import pandas as pd
import json
from pathlib import Path
import os
import re,subprocess
import glob
help='''

#generate metacsv.csv com resultados todos dos csv
$find aux_test_results_dir/ -type f -name "all_data.csv" | xargs cat | grep -v average | grep -v test_id > metacsv.csv
append o header de um dos csvs a mao no inicio do file
# mudar o nome da coluna da energia para energy
'''


x='''df = pd.DataFrame([ ["hello there", 100],
                    ["hello kid",   95],
                    ["there kid",   5]
                  ], columns = ['Sentence','Score'])'''






def getTestEnergy(jsonfile, test_nr):
	folder_of_jsonfile = "/".join(jsonfile.split("/")[:-1])
	resume_file = folder_of_jsonfile+ "/test" + str(test_nr) + "resume.json"
	with open(resume_file,"r",encoding='utf-8') as jso:
		jf = json.load(jso)	
	energy_of_test = list(filter ( lambda x : x['metric'] == "energyconsumed", jf ))[0]
	return float(energy_of_test['value_text'])


def loadAPISOfTests(jsonfile):
	l = []
	#l.append( ["API", "Energy"] )
	with open(jsonfile,"r",encoding='utf-8') as jso:
		jf = json.load(jso)	
	
	for test, methods in jf.items():
		energy_of_test = getTestEnergy(jsonfile,test)
		for m_invoked, m_vars in methods.items():
			for api in m_vars['method_apis']:
				if 'name' in api:
					api= api['name']
					#print("%s,%f" % (api, energy_of_test))
					l.append( [api, energy_of_test ] )
	return l


def getAllTests(rootdir):
	stream = os.popen("find \"%s\" -type f -name \"allTracedMethods.json\"" % rootdir)
	return stream.readlines()

def loadAllAPISofTests(basedir):
	full_api_list = []
	tests=getAllTests(basedir)
	for test in tests:
		l = loadAPISOfTests(test.strip())
		full_api_list+=l
	#print(full_api_list)
	return full_api_list


#all_apis = loadAllAPISofTests("/Users/ruirua/repos/AnaDroid/aux_test_results_dir")
#df = pd.DataFrame( all_apis , columns = ['API','Energy'])
#df.to_csv('/Users/ruirua/repos/AnaDroid/apis_energy.csv')
df =  pd.read_csv('/Users/ruirua/repos/AnaDroid/apis_energy.csv')
s_corr = df.API.str.get_dummies().corrwith(df.Energy/df.Energy.max())
print (s_corr)
#s_corr.to_csv('/Users/ruirua/repos/AnaDroid/apis_correlations.csv')
x='''

l=[]
for rowid,row in df.iterrows():
	ll=[]
	ll.append(row['app_category'])
	ll.append(row['energy'])
	l.append(ll)

	#print(row['app_category']+"," + str(row['energy']))
	#exit(0)

df = pd.DataFrame( l , columns = ['App_category','Energy'])

s_corr = df.App_category.str.get_dummies(sep='#').corrwith(df.Energy/df.Energy.max())
print (s_corr)
'''