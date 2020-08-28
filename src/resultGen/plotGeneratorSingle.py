#import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
import os, sys, re
import subprocess
import csv
import itertools
from pylab import *
from termcolor import colored
from collections import OrderedDict 


sep_criteria="major"

min_csv_row_len=1


class DefaultSemanticVersion(object):
    """docstring for DefaultSemanticVersion"""
    def __init__(self, full_version_id):
        super(DefaultSemanticVersion, self).__init__()
        if "-" in full_version_id:
            full_version_id=full_version_id.split("-")[0]
        if re.match(r'^v',full_version_id) or re.match(r'^V',full_version_id):
            full_version_id = re.sub(r'^v',"", full_version_id)
            full_version_id= re.sub(r'^V',"", full_version_id)
        ll= filter( lambda x : x != "",full_version_id.split("."))
        
        if len(ll)>1:
           
            self.major=int(re.sub(r'[a-zA-Z]',"",ll[0]))
            self.minor=int(re.sub(r'[a-zA-Z]',"",ll[1]))
            if len(ll)>2:
                self.patch=int(''.join(re.findall(r'\d+', ll[2])))
            else:
                self.patch=0
        else:
            self.major=0
            self.minor=0
            self.patch=0
    def __str__(self):
        return "%d.%d.%d" %( self.major, self.minor, self.patch )

    def __repr__(self):
        return str(self)
    
    def __eq__(self, other):
        return self.major == other.major and self.major == other.minor and self.major == other.patch

    def __ne__(self, other):
        return not eq(self,other)

    def __le__(self, other):
        return eq(self,other) or lt(self,other)
    
    def __lt__(self, other):
        if self.major < other.major:
            return True
        elif self.major == other.major:
            if self.minor < other.minor:
                return True
            elif self.minor == other.minor:
                if self.patch < other.patch:
                    return True
        return False

    def __ge__(self, other):
        return not lt(self,other) 

    def __gt__(self, other):
        return not eq(self,other) and ge(self,other)



def bar_plot(x_data,y_data, x_label, y_label, plot_title):
    fig, ax = plt.subplots()
    width = 0.3
    y_pos = np.arange(len(x_data))
    ax.bar( y_pos, y_data, align='center', alpha=0.5)
    plt.xticks(y_pos, x_data)
    ax.set(xlabel=x_label, ylabel=y_label, title=plot_title)
    #x.set_xticklabels(x_label)
    fig.savefig(str(plot_title).replace(" ","")+".png")
    
    plt.show()


def box_plot(x_data,y_data, x_label, y_label, plot_title):
    fig, ax = plt.subplots()
    width = 0.3
    print(y_data)
    y_pos = np.arange(len(x_data))
    ax.boxplot( y_data)
    plt.xticks(y_pos, x_data)
    ax.set(xlabel=x_label, ylabel=y_label, title=plot_title)
    #x.set_xticklabels(x_label)
    #fig.savefig(str(plot_title).replace(" ","")+".png")
    
    plt.show()


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


def generate_box_plots_from_column_old(col_name , csvs_dict, yfactor=1, title=''):
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
    
    xtickNames = plt.setp(en_box, xticklabels=final_res_dic.keys())
    plt.setp(xtickNames, rotation=0, fontsize=8)
    #en_box.savefig(str(title).replace(" ","")+".png")


def generate_box_plot_from_metric(csvs_dict, m_type , title, xlabel, ylabel, x, y, z=None, agg_criteria=None, filter_zeros=True, min_samples=1, min_apps=1):
    
    fig1, en_box = plt.subplots()
    en_box.set_title(title)
    consumption_vers_dict={}
    for app_id ,v in csvs_dict.items():
        i=0
        for av,zz in v.items():
            i = i+1
            criteria=getCriteria(av, agg_criteria)
            if criteria in consumption_vers_dict:
                consumption = zz[x][y][z] if z != None else zz[x][y]
                if consumption>0: 
                    consumption_vers_dict[criteria]['total'] = consumption_vers_dict[criteria]['total'] + float(consumption)
                    consumption_vers_dict[criteria]['count'] =   consumption_vers_dict[criteria]['count'] +1
                    consumption_vers_dict[criteria]['diff_apps'].add(app_id)
                    consumption_vers_dict[criteria]['values'].append(float(consumption))
                    consumption_vers_dict[criteria]['avg'] =  (consumption_vers_dict[criteria]['total'] +1)  / (consumption_vers_dict[criteria]['count'] +1)
            else:
                consumption = zz[x][y] if z == None else zz[x][y][z]
                if consumption>0: 
                    consumption_vers_dict[criteria] = {}
                    consumption_vers_dict[criteria]['count'] = 1
                    consumption_vers_dict[criteria]['diff_apps']= set()
                    consumption_vers_dict[criteria]['diff_apps'].add(app_id)
                    consumption_vers_dict[criteria]['values']= [float(consumption)]
                    consumption_vers_dict[criteria]['total'] =  float(consumption)
                    consumption_vers_dict[criteria]['avg'] =  float(consumption)
    
  
    consumption_vers_dict = dict(filter(lambda elem: elem[1]['count'] >= min_samples and  len(elem[1]['diff_apps']) >= min_apps , consumption_vers_dict.items()))
    consumption_vers_dict=OrderedDict(sorted(consumption_vers_dict.items()))
   
    
   #en_box.set_ylabel('Energy (J)')
    en_box.set_xlabel(xlabel)
    bp_dict = en_box.boxplot(map(  lambda elem: elem[1]['values'] , consumption_vers_dict.items() ))
    i = 0
    for line in bp_dict['medians']:
        x, y = line.get_xydata()[1] # top of median line
        xx, yy =line.get_xydata()[0] 
        text(x, y, '%.2f' % y) # draw above, centered
        #text(xx, en_box.get_ylim()[1] * 0.98, '%.2f' % np.average(list_all_samples[i]), color='darkkhaki') 
        i = i +1
    #for line in bp_dict['boxes']:
    #    x, y = line.get_xydata()[0] # bottom of left line
    #    text(x,y, '%.2f' % y, horizontalalignment='center', verticalalignment='top')      # below
        #x, y = line.get_xydata()[3] # bottom of right line
       #text(x,y, '%.2f' % y, horizontalalignment='center', verticalalignment='top')      # below
    xtickNames = plt.setp(en_box, xticklabels=consumption_vers_dict.keys())
    plt.setp(xtickNames, rotation=0, fontsize=8)
    plt.savefig(str(title).replace(" ","")+".png")
    fig1.show()



def generate_box_plots_from_column_old(col_name , csvs_dict, yfactor=1, title=''):
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
    
    folder = csv_filename.replace("/all_data.csv", "")
    if re.match(r'.*[0-9]+\_[0-9]+\_', folder):
       version_folder="/".join(folder.split("/")[:-1])
    else:
        version_folder=folder
    version_id=version_folder.split("/")[-1]
    app_id = version_folder.split("/")[-2]
    if len(version_folder)>2:
        app_id = version_folder.split("/")[-2]
    else:
        app_id = version_folder.split("/")[0]
    print(app_id)
    return app_id, version_id
    


""" 
vv[DefaultSemanticVersion(app_version)]= (header, sortedlist, avg_row, other_metrics)

csv_dict={
        'com.package.app': {
            
            'x.x.x' : ([col_names], [ [test_metrics], [test_metrics1],  [avg_row] , [[other_metrics in pair k v]] ] )
            '2.1.1': (  ['test_id', ' energy cons (J)', ' time elapsed (ms)', ' cpuloadnormalized (%)', ' memoryusage (KB)', ' gpuload (%), coverage (%)'],
                        [   ['1', '61.017459449628575', '102168', '21.11', '1658323.93', '1.18', '15.021459227467812'],
                            ['2', '56.35762433547219', '94758', '21.12', '1648253.89', '0.75', '14.592274678111588']
                        ], 
                        ['average', '58.6875418926', '98463.0', '21.115', '1653288.91', '0'],
                        [   ['total_traced_methods', ' 69'], ['total_complexity', ' 479'], 
                            ['total_loc_java', ' 3775'], ['total_loc_kotlin', ' 0'], 
                            ['total_coverage', ' 15.0214592275'], 
                            ['total_loc', ' 6641']
                        ])
        }
}"""

def generate_app_versions_dict(all_csvs_of_folder):
    csvs_dict={}
    print(all_csvs_of_folder)
    for csv_file in all_csvs_of_folder:
        app_id, app_version = split_app_and_version(csv_file)
        print(app_version)
        header, sortedlist, avg_row, other_metrics = sort_csv_test_id(csv_file)
        if len( sortedlist) >= min_csv_row_len :
            #csvs_dict[csv_file] = (header, sortedlist, avg_row)
            if app_id in csvs_dict:
                csvs_dict[app_id][DefaultSemanticVersion(app_version)] = (header, sortedlist, avg_row, other_metrics)
            else:
                vv={}
                vv[DefaultSemanticVersion(app_version)]= (header, sortedlist, avg_row, other_metrics)
                csvs_dict[app_id] = vv
            #generate_box_plot(header,sortedlist)
        else:
            print(colored("ignoring file :%s " % csv_file ,"red"))
    # sort csv info by app version
    for v in csvs_dict:
        csvs_dict[v] =  OrderedDict(sorted(csvs_dict[v].items())) #collections.OrderedDict( sorted(v.items(), key=lambda kv: kv[0]) )

    return csvs_dict



def getCriteria(app_version, agg_criteria=None ):
    if agg_criteria is None:
        return app_version
    elif agg_criteria is "major":
        return app_version.major
    elif agg_criteria is "minor":
        return str(app_version.major) +"." + str(app_version.minor)
    else:
        return "batata"







def plotMetric(csvs_dict, m_type , title, xlabel, ylabel, x, y, z=None, agg_criteria=None, filter_zeros=True, min_samples=1, min_apps=1):
    consumption_vers_dict={}
    for app_id ,v in csvs_dict.items():
        i=0
        for av,zz in v.items():
            i = i+1
            criteria=getCriteria(av, agg_criteria)
            if criteria in consumption_vers_dict:
                consumption = zz[x][y][z] if z != None else zz[x][y]
                if consumption>0: 
                    consumption_vers_dict[criteria]['total'] = consumption_vers_dict[criteria]['total'] + float(consumption)
                    consumption_vers_dict[criteria]['count'] =   consumption_vers_dict[criteria]['count'] +1
                    consumption_vers_dict[criteria]['diff_apps'].add(app_id)
                    consumption_vers_dict[criteria]['avg'] =  (consumption_vers_dict[criteria]['total'] +1)  / (consumption_vers_dict[criteria]['count'] +1)
            else:
                consumption = zz[x][y] if z == None else zz[x][y][z]
                if consumption>0: 
                    consumption_vers_dict[criteria] = {}
                    consumption_vers_dict[criteria]['count'] = 1
                    consumption_vers_dict[criteria]['diff_apps']= set(app_id)
                    consumption_vers_dict[criteria]['diff_apps'].add(app_id)
                    #consumption_vers_dict[criteria]['total'] =  float(consumption)
                    consumption_vers_dict[criteria]['avg'] =  float(consumption)
    
  
    consumption_vers_dict = dict(filter(lambda elem: elem[1]['count'] >= min_samples and  len(elem[1]['diff_apps']) >= min_apps , consumption_vers_dict.items()))
    consumption_vers_dict=OrderedDict(sorted(consumption_vers_dict.items()))
    
    bar_plot(consumption_vers_dict.keys(), list(map(lambda xx : xx[m_type], consumption_vers_dict.values() )) , xlabel, ylabel, title )


def buildPlots(csvs_dict,criteria=None, filter_zeros=False, min_samples=1, min_apps=5):
    plotMetric(csvs_dict, 'avg', "avg Energy across major versions" , "versions" , "Energy(J)",2,1 ,z=None, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    plotMetric(csvs_dict, 'avg', "LOC across versions" , "versions" , "#LOC",3,5,1, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    plotMetric(csvs_dict, 'avg', "Method Coverage across versions" , "versions" , "%",3,4,1, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples  , min_apps=min_apps )
    plotMetric(csvs_dict, 'avg', "avg Memory across versions" , "versions" , "Mem(kB)",2,4 ,z=None, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )

def buildBoxPlots(csvs_dict,criteria=None, filter_zeros=False, min_samples=1, min_apps=5):
    generate_box_plot_from_metric(csvs_dict, 'avg', "avg Energy across major versions" , "versions" , "Energy(J)",2,1 ,z=None, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    generate_box_plot_from_metric(csvs_dict, 'avg', "LOC across versions" , "versions" , "#LOC",3,5,1, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    generate_box_plot_from_metric(csvs_dict, 'avg', "Method Coverage across versions" , "versions" , "%",3,4,1, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples  , min_apps=min_apps )
    generate_box_plot_from_metric(csvs_dict, 'avg', "avg Memory across versions" , "versions" , "Mem(kB)",2,4 ,z=None, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )

if __name__== "__main__":
    if len(sys.argv) > 1:
        device_folder = sys.argv[1]
        all_csvs_of_folder = fetch_all_data_csvs(device_folder)
        csvs_dict = generate_app_versions_dict(all_csvs_of_folder)
        #buildPlots(csvs_dict, criteria="major", filter_zeros=True, min_samples=5, min_apps=5)
        #generate_test_behaviour_graphs(csvs_dict)
        buildBoxPlots(csvs_dict, criteria="major", filter_zeros=True, min_samples=5, min_apps=5)
        #plt.show()
    else:
        print ("bad arg len")