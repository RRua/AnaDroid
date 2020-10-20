import pandas as pd

help='''

#generate metacsv.csv com resultados todos dos csv
$find aux_test_results_dir/ -type f -name "all_data.csv" | xargs cat | grep -v average | grep -v test_id > metacsv.csv
append o header de um dos csvs à mao no inicio do file
# mudar o nome da coluna da energia para energy
'''


x='''df = pd.DataFrame([ ["hello there", 100],
                    ["hello kid",   95],
                    ["there kid",   5]
                  ], columns = ['Sentence','Score'])'''

df = pd.read_csv("metacsv.csv", sep=";")

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