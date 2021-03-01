import pandas as pd

df = pd.DataFrame([ ["com.github.hello", 100],
                    ["com.github.zzz",   95],
                    ["com.batata.au",   5],
                    ["com.batata.caca",   5]
                  ], columns = ['APIS','Energy'])

s_corr = df.APIS.str.get_dummies(sep=' ').corrwith(df.Energy/df.Energy.max())
print (s_corr)