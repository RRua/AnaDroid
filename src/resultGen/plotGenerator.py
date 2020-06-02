#import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
import os, sys
import subprocess
import csv
import itertools
from pylab import *
from termcolor import colored
from collections import OrderedDict 


min_csv_row_len=1


def line_plot(x_data,y_data, x_label, y_label, plot_title):
   
    fig, ax = plt.subplots()
    ax.plot(x_data, y_data)

    ax.set(xlabel=x_label, ylabel=y_label,
           title=plot_title)
    ax.grid()

    fig.savefig(str(plot_title)+".png")
    plt.show()


def fetch_all_data_csvs(folder):
    ret_list = []
    output = subprocess.check_output("find %s -type f -name \"all_data.csv\"" % folder, shell=True)
    for x in output.decode("utf-8").strip().split("\n"):
        ret_list.append(x)
    return ret_list


def sort_csv_test_id(csv_file):
    reader = csv.reader(open(csv_file), delimiter=";")
    header = next(reader)
    csv_row_list = list(reader)
    avg_row = csv_row_list[-7]
    other_metrics = csv_row_list[-6:]
    
    sortedlist = sorted(csv_row_list[:-7], key=lambda row: int(row[0]))
    return header, sortedlist, avg_row , other_metrics

def generate_box_plots(csvs_dict):
    
    # energy boxplot
    generate_box_plots_from_column(" energy cons (J)", csvs_dict , title = "Energy consumed (J)" )
    generate_box_plots_from_column( ' time elapsed (ms)', csvs_dict, yfactor=1000, title = "Elapsed Time (s)")
    #generate_box_plots_from_column(" energy cons (J)", csvs_dict )
    generate_box_plots_from_column( ' cpuloadnormalized (%)', csvs_dict , title="CPU Load (%)")
    generate_box_plots_from_column( ' memoryusage (KB)', csvs_dict, yfactor=(1024*1024), title = "Memory (GB)")



def extract_keyboard_name(file_name):
    print(file_name)
    if "cheetah" in file_name:
        return "cheetah"
    elif  "google" in file_name:
        return "google"
    elif  "go" in file_name:
        return "go"
    elif  "swiftkey" in file_name:
        return "swiftkey"
    elif  "fancykey" in file_name:
        return "fancykey"
    elif  "samsung" in file_name:
        return "samsung"
    else:
        return "bieira"

def extract_keyboard_mode(file_name):
    if "default" in file_name:
        return "default"
    elif  "minimal" in file_name:
        return "minimal"
    else:
        return "bieira"


def generate_box_plots_from_column(col_name , csvs_dict, yfactor=1, title=''):
    fig1, en_box = plt.subplots()
    if title=='':
        title=col_name
    en_box.set_title(title)
    dict_keyboard_samples = OrderedDict() 
    list_all_samples = []
    for x in csvs_dict.keys():
        triple = csvs_dict[x]
        header = triple[0]
        sorted_csv = triple[1]
        values = get_column_values(col_name, header, sorted_csv, factor=yfactor)
        list_all_samples.append(values)
        keyboard_mode = extract_keyboard_mode(x)
        keyboard_name = extract_keyboard_name(x)
        if  keyboard_name in dict_keyboard_samples.keys():
            dict_keyboard_samples[keyboard_name][keyboard_mode] = values
        else:
            dict_keyboard_samples[keyboard_name] = {}
            dict_keyboard_samples[keyboard_name][keyboard_mode] = values

    
    final_res_dic = OrderedDict()
    for kbname in dict_keyboard_samples.keys() :
        kb_modes_dict = dict_keyboard_samples[kbname]
        for kbmode in kb_modes_dict:
            final_res_dic [kbname+"_"+kbmode] = kb_modes_dict[kbmode]
    #en_box.set_ylabel('Energy (J)')
    en_box.set_xlabel('Keyboard')
    bp_dict = en_box.boxplot(final_res_dic.values())
    i = 0
    for line in bp_dict['medians']:
        x, y = line.get_xydata()[1] # top of median line
        xx, yy =line.get_xydata()[0] 
        text(x, y, '%.2f' % y) # draw above, centered
        text(xx, en_box.get_ylim()[1] * 0.98, '%.2f' % np.average(list_all_samples[i]), color='darkkhaki') 
        i = i +1
    #for line in bp_dict['boxes']:
    #    x, y = line.get_xydata()[0] # bottom of left line
    #    text(x,y, '%.2f' % y, horizontalalignment='center', verticalalignment='top')      # below
        #x, y = line.get_xydata()[3] # bottom of right line
       #text(x,y, '%.2f' % y, horizontalalignment='center', verticalalignment='top')      # below
    xtickNames = plt.setp(en_box, xticklabels=final_res_dic.keys())
    plt.setp(xtickNames, rotation=0, fontsize=8)




def get_column_values( header_str,header,sorted_csv, factor=1):
    energy_col_index = header.index(header_str)
    energy_values =map( lambda x :  float(x[energy_col_index]) / factor , sorted_csv )
    return energy_values
    

def generate_test_behaviour_graphs(csvs_dict):
    generate_test_behaviour_graph(" energy cons (J)", csvs_dict )        




def generate_test_behaviour_graph(col_name, csvs_dict):
    fig1, line = plt.subplots()
    list_all_samples = []
    for x in csvs_dict.keys():
        triple = csvs_dict[x]
        label = (extract_keyboard_name(x))
        header = triple[0]
        sorted_csv = triple[1]
        values = get_column_values(col_name, header, sorted_csv )    
        n_tests =  get_column_values("test_id", header, sorted_csv  )
        list_all_samples.append((values,n_tests,label))
        
    for l , s , label in list_all_samples:
        #print( str (l) + "-" + str(s) + "-" + str(label))
        line.plot(s,l, label=label)
        plt.legend()
        

def split_app_and_version(csv_filename):
    version_folder = csv_filename.replace("/all_data.csv", "")
    version_id = version_folder.split("/")[-1]
    app_id = version_folder.split("/")[-2]
    if len(version_folder)>2:
        app_id = version_folder.split("/")[-2]
    else:
        app_id = version_folder.split("/")[0]
    return app_id, version_id
    


def generate_app_versions_dict(all_csvs_of_folder):
    csvs_dict={}
    for csv_file in all_csvs_of_folder:
        app_id, app_version = split_app_and_version(csv_file)
        header, sortedlist, avg_row, other_metrics = sort_csv_test_id(csv_file)
        if len( sortedlist) >= min_csv_row_len :
            #csvs_dict[csv_file] = (header, sortedlist, avg_row)
            if app_id in csvs_dict:
                csvs_dict[app_id][int(app_version)] = (header, sortedlist, avg_row, other_metrics)
            else:
                vv={}
                vv[int(app_version)]= (header, sortedlist, avg_row, other_metrics)
                csvs_dict[app_id] = vv
            #generate_box_plot(header,sortedlist)
        else:
            print(colored("ignoring file :%s " % csv_file ,"red"))
    # sort csv info by app version
    for v in csvs_dict:
        csvs_dict[v] =  OrderedDict(sorted(csvs_dict[v].items())) #collections.OrderedDict( sorted(v.items(), key=lambda kv: kv[0]) )
    

    plotEnergyAcrossVersions(csvs_dict)
    plotLOCAcrossVersions(csvs_dict)
    plotCoverageAcrossVersions(csvs_dict)
    print(other_metrics)
    return csvs_dict

def plotLOCAcrossVersions(csvs_dict):
    # juntar tudo por vid 
    consumption_vers_dict={}
    for x,v in csvs_dict.items():
        i=0
        for av,zz in v.items():
            i = i+1
            if i in consumption_vers_dict:
                
                consumption = zz[3][5][1]
                consumption_vers_dict[i]['total'] = consumption_vers_dict[i]['total'] + float(consumption)
                consumption_vers_dict[i]['count'] =   consumption_vers_dict[i]['count'] +1
                consumption_vers_dict[i]['avg'] =  (consumption_vers_dict[i]['total'] +1)  / (consumption_vers_dict[i]['count'] +1)
            else:
               
                
                consumption = zz[3][5][1]

                consumption_vers_dict[i] = {}
                consumption_vers_dict[i]['count'] = 1
                consumption_vers_dict[i]['total'] =  float(consumption)
                consumption_vers_dict[i]['avg'] =  float(consumption)
    
            #print(str(av) + str(zz))
        #print("---")
    line_plot(consumption_vers_dict.keys(), list(map(lambda x : x['avg'], consumption_vers_dict.values() )) , "versions", "LOC)", "avg LOC across versions" )
    

def plotCoverageAcrossVersions(csvs_dict):
    consumption_vers_dict={}
    for x,v in csvs_dict.items():
        i=0
        for av,zz in v.items():
            i = i+1
            if i in consumption_vers_dict:
                
                consumption = zz[3][4][1]
                consumption_vers_dict[i]['total'] = consumption_vers_dict[i]['total'] + float(consumption)
                consumption_vers_dict[i]['count'] =   consumption_vers_dict[i]['count'] +1
                consumption_vers_dict[i]['avg'] =  (consumption_vers_dict[i]['total'] +1)  / (consumption_vers_dict[i]['count'] +1)
            else:
               
                #print(zz[3][4][2]) 
                consumption = zz[3][4][1]

                consumption_vers_dict[i] = {}
                consumption_vers_dict[i]['count'] = 1
                consumption_vers_dict[i]['total'] =  float(consumption)
                consumption_vers_dict[i]['avg'] =  float(consumption)
    
            #print(str(av) + str(zz))
        #print("---")
    line_plot(consumption_vers_dict.keys(), list(map(lambda x : x['avg'], consumption_vers_dict.values() )) , "versions", "coverage)", "avg coverage across versions" )
    

    

def plotEnergyAcrossVersions(csvs_dict):
    # juntar tudo por vid 
    consumption_vers_dict={}
    for x,v in csvs_dict.items():
        i=0
        for av,zz in v.items():
            i = i+1
            if i in consumption_vers_dict:
                consumption = zz[2][1]
                consumption_vers_dict[i]['total'] = consumption_vers_dict[i]['total'] + float(consumption)
                consumption_vers_dict[i]['count'] =   consumption_vers_dict[i]['count'] +1
                consumption_vers_dict[i]['avg'] =  (consumption_vers_dict[i]['total'] +1)  / (consumption_vers_dict[i]['count'] +1)
            else:
                consumption = zz[2][1]
                consumption_vers_dict[i] = {}
                consumption_vers_dict[i]['count'] = 1
                consumption_vers_dict[i]['total'] =  float(consumption)
                consumption_vers_dict[i]['avg'] =  float(consumption)
    
            #print(str(av) + str(zz))
        #print("---")
    line_plot(consumption_vers_dict.keys(), list(map(lambda x : x['avg'], consumption_vers_dict.values() )) , "versions", "Energy (J)", "avg Energy across versions" )
    

if __name__== "__main__":
    if len(sys.argv) > 1:
        device_folder = sys.argv[1]
        all_csvs_of_folder = fetch_all_data_csvs(device_folder)
        csvs_dict = generate_app_versions_dict(all_csvs_of_folder)

        #generate_test_behaviour_graphs(csvs_dict)
        #generate_box_plots(csvs_dict)
        #plt.show()
    else:
        print ("bad arg len")