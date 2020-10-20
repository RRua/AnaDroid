import pandas as pd

df = pd.DataFrame([ ["hello there", 100],
                    ["hello kid",   95],
                    ["there kid",   5]
                  ], columns = ['Sentence','Score'])

s_corr = df.Sentence.str.get_dummies(sep=' ').corrwith(df.Score/df.Score.max())
print (s_corr)