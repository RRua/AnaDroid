#import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
import os, sys, re
import subprocess
import csv,json
import itertools
from pylab import *
from termcolor import colored
from collections import OrderedDict 
from ordered_set import OrderedSet

from generate_behaviour_plot import *

sep_criteria="app_id" # "with"  #"app_id" # #"app_id" #"patch" #"app_category_major" #"major" #"minor # categories

min_csv_row_len=1

test_type="monkey" # "monkey", "crawler" or "all"
sep_by_type=False #False
compareValues="threshold" # default or "threshold"
threshold=0.1

def isclose(a, b, rel_tol=threshold , abs_tol=0.005):
    if compareValues== "default":
        return False
    return abs(a-b) <= max(rel_tol * max(abs(a), abs(b)), abs_tol)

def getPercentageChange(a,b):
    return safe_division( b, a )

def is_bigger(a,b,threshold=threshold, tol=0.005):
    return a > b and not isclose(a,b,rel_tol=threshold, abs_tol=tol) 

def is_lower(a,b,threshold=threshold, tol=0.005):
    return  a < b and not isclose(a,b,rel_tol=threshold, abs_tol=tol)

def safe_division(n, d):
    return n / d if d else 0

def canBeFloat(element):
    try:
        float(element)
        return True
    except Exception as e:
        return False

class DefaultSemanticVersion(object):
    """docstring for DefaultSemanticVersion"""
    def __init__(self, full_version_id):
        super(DefaultSemanticVersion, self).__init__()
        full_version_id=full_version_id.replace("`","").replace("_","")
       # print(full_version_id)
        if "-" in full_version_id:
            full_version_id=full_version_id.split("-")[0]
        if re.match(r'^v',full_version_id) or re.match(r'^V',full_version_id):
            full_version_id = re.sub(r'^v',"", full_version_id)
            full_version_id= re.sub(r'^V',"", full_version_id)
        ll= list(filter( lambda x : x != "",full_version_id.split(".")))
        
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
        return self.major == other.major and self.minor == other.minor and self.patch == other.patch

    def __ne__(self, other):
        return not self.__eq__(other)

    def __le__(self, other):
        return self.__eq__(other) or self.__lt__(other)
    
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

    def __hash__(self):
        return hash((self.major, self.minor, self.patch))

class Statistics(object):
    """docstring for Statistics"""
    def __init__(self):
        super (Statistics, self).__init__()
        self.total_apps=0
        self.total_tests=0
        self.total_value_increases=0
        self.total_value_decreases=0
        self.total_value_equal=0
        self.total_value_increases_major=0
        self.total_value_decreases_major=0
        self.total_value_equal_major=0
        self.total_value_increases_major_wide=0
        self.total_value_decreases_major_wide=0
        self.total_value_equal_major_wide=0
        self.total_value_increases_minor=0
        self.total_value_decreases_minor=0
        self.total_value_equal_minor=0
        self.total_value_increases_minor_wide=0
        self.total_value_decreases_minor_wide=0
        self.total_value_equal_minor_wide=0
        self.total_value_increases_patch=0
        self.total_value_decreases_patch=0
        self.total_value_equal_patch=0
        self.total_value_increases_patch_wide=0
        self.total_value_decreases_patch_wide=0
        self.total_value_equal_patch_wide=0


    def fill(self, app_list_pairs_version_value):
        # assuming that list is sorted
        lastx,lasty = app_list_pairs_version_value[0]
        fst_lasty = lasty
        for x,y in app_list_pairs_version_value[1:]:    
            print("-"+str(x))
            print("-%s vs %s" %( lasty , y ) )
            if is_bigger(float(y),float(lasty)):
                print(getPercentageChange(float(lasty),float(y)))
                self.total_value_increases+=1
            elif is_lower(float(y),float(lasty)):
                print(getPercentageChange(float(lasty),float(y)))
                self.total_value_decreases+=1
            else:
                self.total_value_equal+=1
            lasty = float(y) 
            lastx = x
            print("---")

        if is_bigger( float(lasty) , float(fst_lasty)):
            print("wide major increase-" + str(getPercentageChange(float(fst_lasty),float(lasty))))
            self.total_value_increases_major_wide+=1
        elif is_lower( float(lasty) , float(fst_lasty)):
            self.total_value_decreases_major_wide+=1
            print("wide major decrease-" + str(getPercentageChange(float(fst_lasty),float(lasty))))
        else:
            self.total_value_equal_major_wide+=1
        
        # see bt2 major versions only
        # get > minor version of each major
        app_v_dict={}
        diff_biggest_majors=[]
        app_diff_majors = OrderedSet ( map( lambda z : z[0].major,  app_list_pairs_version_value ))
        #print("########")
        #print(app_list_pairs_version_value)
        for mj in app_diff_majors:
            app_v_dict[mj]={}
            app_v_minors = OrderedSet ( map( lambda x : x[0].minor ,  filter( lambda z : z[0].major == mj  ,  app_list_pairs_version_value )))
            #print( "v's com major " + str(mj) + " - " + str(app_v_minors)   )
            for mn in app_v_minors:
                app_v_dict[mj][mn] = OrderedSet()
                app_v_patches = OrderedSet ( filter( lambda z : z[0].major == mj and z[0].minor == mn  ,  app_list_pairs_version_value ))     
                #print( "v's com major " + str(mj) + "and minor " + str(mn) + " - " + str(app_v_patches)   )
                app_v_dict[mj][mn] = app_v_patches

            # now that we have all patches with same minor version, account minor version changes
            # compara latest patch versions btween diff minors
        
            lasty = list(list(app_v_dict[mj].values())[0] )[0][1] # actualy is the first
            last_minor_lasty = list(list(app_v_dict[mj].values())[-1] )[-1][1] # last val of bigg. minor
            
            if  is_bigger ( float(last_minor_lasty) , float(lasty)):
                self.total_value_increases_minor_wide+=1
            elif is_lower (float(last_minor_lasty) , float(lasty)):
                self.total_value_decreases_minor_wide+=1
            else:
                self.total_value_equal_minor_wide+=1

            for mn,pt_set in list(app_v_dict[mj].items())[1:]:
                y = list(pt_set)[-1][1]
                fst_patch_y = list(pt_set)[0][1]
                if is_bigger( float(y) , float(lasty)):
                    self.total_value_increases_minor+=1
                elif is_lower (float(y) , float(lasty)):
                    self.total_value_decreases_minor+=1
                else:
                    self.total_value_equal_minor+=1

                if is_bigger (float(y) , float(fst_patch_y)):
                    self.total_value_increases_patch_wide+=1
                elif is_lower (float(y) , float(fst_patch_y)):
                    self.total_value_decreases_patch_wide+=1
                else:
                    self.total_value_equal_patch_wide+=1
                
                # get changes across patch versions( of same major and minor)
                lasty = float(y)  
                for pat_vers in pt_set:
                    y=pat_vers[1]
                    if is_bigger(float(y) , float(fst_patch_y)):
                        self.total_value_increases_patch+=1
                    elif is_lower(float(y), float(fst_patch_y)):
                        self.total_value_decreases_patch+=1
                    else:
                        self.total_value_equal_patch+=1
                    fst_patch_y=y
    
       # print(app_v_dict)    

        ### TODO fazer esta diff para cada tipo de v
        for a in app_diff_majors:
            diff_biggest_majors.append ( list( filter ( lambda x : x[0].major ==a, app_list_pairs_version_value )  )[-1] )
        lastx,lasty = diff_biggest_majors[0]
        for x,y in diff_biggest_majors[1:]:    
            if is_bigger(float(y) , float(lasty)):
                self.total_value_increases_major+=1
            elif is_lower(float(y) , float(lasty)):
                self.total_value_decreases_major+=1
            else:
                self.total_value_equal_major+=1
            lasty = float(y) 
            lastx = x

        

    def printStats(self, metric_name):
        print( "%s increases overall %.2f" %( metric_name , 100* safe_division( self.total_value_increases ,  ( self.total_value_increases + self.total_value_decreases +self.total_value_equal ) ) ) )
        print( "%s decreases overall %.2f" %( metric_name , 100* safe_division( self.total_value_decreases ,  ( self.total_value_increases + self.total_value_decreases + self.total_value_equal  ) ) ) )
        
        print( "%s increases major %.2f" %( metric_name ,100*  safe_division(self.total_value_increases_major ,  ( self.total_value_increases_major + self.total_value_decreases_major  + self.total_value_equal_major  ) ) ) )
        print( "%s decreases major %.2f" %( metric_name ,100*  safe_division(self.total_value_decreases_major ,  ( self.total_value_increases_major + self.total_value_decreases_major + self.total_value_equal_major ) ) ) )
        
        print( "%s increases major_wide %.2f" %( metric_name ,100*  safe_division(self.total_value_increases_major_wide ,  ( self.total_value_increases_major_wide + self.total_value_decreases_major_wide+ self.total_value_equal_major_wide  ) ) ) ) 
        print( "%s decreases major_wide %.2f" %( metric_name , 100* safe_division(self.total_value_decreases_major_wide ,  ( self.total_value_increases_major_wide + self.total_value_decreases_major_wide + self.total_value_equal_major_wide ) ) ) ) 
        
        print( "%s increases minors %.2f" %(metric_name , 100*  safe_division(self.total_value_increases_minor ,  ( self.total_value_increases_minor + self.total_value_decreases_minor + self.total_value_equal_minor ) ) ) )
        print( "%s decreases minors %.2f" %(metric_name , 100*  safe_division(self.total_value_decreases_minor ,  ( self.total_value_increases_minor + self.total_value_decreases_minor + self.total_value_equal_minor ) ) ) )
        
        print( "%s increases minor_wide %.2f" %( metric_name ,100*  safe_division(self.total_value_increases_minor_wide ,  ( self.total_value_increases_minor_wide + self.total_value_decreases_minor_wide+ self.total_value_equal_minor_wide  ) ) ) )
        print( "%s decreases minor_wide %.2f" %( metric_name ,100*  safe_division(self.total_value_decreases_minor_wide ,  ( self.total_value_increases_minor_wide + self.total_value_decreases_minor_wide+ self.total_value_equal_minor_wide  ) ) ) )
        
        print( "%s increases patch %.2f" %( metric_name ,100*  safe_division(self.total_value_increases_patch ,  ( self.total_value_increases_patch + self.total_value_decreases_patch+ self.total_value_equal_patch  ) ) ) )
        print( "%s decreases patch %.2f" %( metric_name ,100*  safe_division(self.total_value_decreases_patch ,  ( self.total_value_increases_patch + self.total_value_decreases_patch+ self.total_value_equal_patch ) ) ) )
        
        print( "%s increases patch_wide %.2f" %( metric_name , 100* safe_division(self.total_value_increases_patch_wide ,  ( self.total_value_increases_patch_wide + self.total_value_decreases_patch_wide + self.total_value_equal_patch_wide  ) ) ) ) 
        print( "%s decreases patch_wide %.2f" %( metric_name ,100*  safe_division(self.total_value_decreases_patch_wide ,  ( self.total_value_increases_patch_wide + self.total_value_decreases_patch_wide + self.total_value_equal_patch_wide  ) ) ) ) 
        

def getTestType(filename):
    if "MonkeyTest" in filename:
        return "monkey"
    elif "CrawlerTest" in filename:
        return "crawler"
    elif "unner" in filename:
        return "monkeyrunner"
    elif "unit" in filename:
        return "junit"
    elif "eranTest" in filename:
        return "reran"
    else:
        return "unknown"



def bar_plot(x_data,y_data, x_label, y_label, plot_title):
    fig, ax = plt.subplots()
    width = 0.3
    y_pos = np.arange(len(x_data))
    ax.bar( y_pos, y_data, align='center', alpha=0.5)
    plt.xticks(y_pos, x_data)
    ax.set(xlabel=x_label, ylabel=y_label, title=plot_title)
    #x.set_xticklabels(x_label)
    xtickNames = plt.setp(ax, xticklabels=x_data)
    setp(xtickNames, rotation=90, fontsize=8)
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

    ax.set(xlabel=x_label, ylabel=y_label,title=plot_title)
    
    ax.grid()

    fig.savefig(str(plot_title)+".png")
    plt.show()


def fetch_all_data_csvs(folder):
    ret_list = []
    output = subprocess.check_output("find %s -type f -name \"all_data.csv\"" % folder, shell=True)
    for x in output.decode("utf-8").strip().split("\n"):
        if test_type =="all" or test_type == getTestType(x):
            ret_list.append(x)
            #print(x)
    return ret_list


def sort_csv_test_id(csv_file):
    reader = csv.reader(open(csv_file), delimiter=";")
    header = next(reader)
    #print(header)
    csv_row_list = list(reader)
    avg_row = csv_row_list[-7]
    other_metrics = csv_row_list[-6:]
    
    sortedlist = sorted(csv_row_list[:-7], key=lambda row: int(row[0]))
    return header, sortedlist, avg_row , other_metrics


def bbox_plots_from_column_old(col_name , csvs_dict, yfactor=1, title=''):
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


def generate_box_plot_from_metric(csvs_dict, m_type , title, xlabel, ylabel, x, y, z=None, agg_criteria=None, filter_zeros=True, min_samples=3, min_apps=3):
    
    fig1, en_box = plt.subplots()
    en_box.set_title(title)
    consumption_vers_dict={}
    for app_id ,v in csvs_dict.items():
        i=0
       
        for av,zz in v.items():
            # for each app version get tests executed for that app
            i = i+1
            criteria=(str(getCriteria(app_id,av, agg_criteria,app_category=(zz[1][0][-1] if len(zz)>0 else 'unknown'))) + "_" + zz[4][0]) if sep_by_type else str(getCriteria(app_id,av, agg_criteria,app_category=(zz[1][0][-1] if len(zz)>0 else 'unknown'))) 
            if criteria in consumption_vers_dict:
                consumption = zz[x][y][z] if z != None else zz[x][y]
                #print(consumption)
                if float(consumption)>=0: 
                    consumption_vers_dict[criteria]['total'] = consumption_vers_dict[criteria]['total'] + float(consumption)
                    consumption_vers_dict[criteria]['count'] =   consumption_vers_dict[criteria]['count'] +1
                    consumption_vers_dict[criteria]['diff_apps'].add(av)
                    consumption_vers_dict[criteria]['values'].append(float(consumption))
                    consumption_vers_dict[criteria]['avg'] =  (consumption_vers_dict[criteria]['total'] +1)  / (consumption_vers_dict[criteria]['count'] +1)
            else:
                consumption = zz[x][y] if z == None else zz[x][y][z]
                #print(consumption)
                if float(consumption)>=0: 
                    consumption_vers_dict[criteria] = {}
                    consumption_vers_dict[criteria]['count'] = 1
                    consumption_vers_dict[criteria]['diff_apps']= set()
                    consumption_vers_dict[criteria]['diff_apps'].add(av)
                    consumption_vers_dict[criteria]['values']= [float(consumption)]
                    consumption_vers_dict[criteria]['total'] =  float(consumption)
                    consumption_vers_dict[criteria]['avg'] =  float(consumption)
    
  

   
    consumption_vers_dict = dict(filter(lambda elem: elem[1]['count'] >= min_samples and  len(elem[1]['diff_apps']) >= min_apps , consumption_vers_dict.items()))
   

    consumption_vers_dict=OrderedDict(sorted(consumption_vers_dict.items()))
   
    

    #for v,vals in consumption_vers_dict.items():
    #    print(v)
    #    for value in consumption_vers_dict[v]['diff_apps']:
    #        print(value)
    #    print("--")
    
    #en_box.set_ylabel('Energy (J)')
    #en_box.set_xlabel(xlabel)
    bp_dict = en_box.boxplot(list(map(  lambda elem: elem[1]['values'] , consumption_vers_dict.items() )),   patch_artist=True)
    i = 0
    for line in bp_dict['medians']:
        x, y = line.get_xydata()[1] # top of median line
        xx, yy =line.get_xydata()[0] 
        text(x, y, '%.2f' % y, fontsize=6) # draw above, centered
        #text(xx, en_box.get_ylim()[1] * 0.98, '%.2f' % np.average(list_all_samples[i]), color='darkkhaki') 
        i = i +1
    #for line in bp_dict['boxes']:
    #    x, y = line.get_xydata()[0] # bottom of left line
    #    text(x,y, '%.2f' % y, horizontalalignment='center', verticalalignment='top')      # below
        #x, y = line.get_xydata()[3] # bottom of right line
       #text(x,y, '%.2f' % y, horizontalalignment='center', verticalalignment='top')      # below
    
    # set colors
    colors = ['lightblue', 'darkkhaki','darkseagreen','salmon','pink','gold']
    i=0
    for bplot in bp_dict['boxes']:
        i=i+1
        bplot.set_facecolor(colors[i%len(colors)])

    xtickNames = plt.setp(en_box, xticklabels=consumption_vers_dict.keys())
    plt.setp(xtickNames, rotation=90, fontsize=10)
    plt.savefig(str(title).replace(" ","")+".png")
    plt.show()



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
        print(csvs_dict)
        header = triple[0]
        print(header)
        exit(0)
        sorted_csv = triple[1]
        values = get_column_values(col_name, header, sorted_csv )    
        n_tests =  get_column_values("test_id", header, sorted_csv  )
        list_all_samples.append((values,n_tests,label,reds))

    for l , s , label, reds in list_all_samples:
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
    #print(app_id)
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
                        ['average', '58.6875418926', '98463.0', '21.115', '1653288.91', '0', 'perf_issue_nr'],
                        [   ['total_loc', ' 6641'],
                            ['total_traced_methods', ' 69'], ['total_complexity', ' 479'], 
                            ['total_loc_java', ' 3775'], ['total_loc_kotlin', ' 0'], 
                            ['total_coverage', ' 15.0214592275'],
                        ])
        }
}"""

# merge tests from != testing frameworks or executions in one dataset 
# sometimes headers are !=, making brainless merge not possible
def mergeIndividualTests(current_vals, new_vals):
    
    (current_header, current_test_list, curr_avg_row, curr_other_metrics, curr_test_types,curr_appid) = current_vals
    (new_header, new_test_list, new_avg_row, new_other_metrics, new_test_types,new_app_ids) = current_vals
    merged_header = []
# merge headers
    for header in current_header:
       merged_header.append(header)
    for header in new_header:
        if header not in merged_header:
            merged_header.append(header)
# merge test list
    merged_list = []
    for i,test in enumerate(current_test_list):
        merged_test = test
        for x in range(0, len(merged_header) - len(current_header) ):
            merged_test.append(0)
        merged_list.append(merged_test)
    
    merged_list.append(new_test_list)

    x='''should be this, but too inefficient for i,test in enumerate(new_test_list):
        test_list = []
        for j,head in enumerate(merged_header):
            if head in new_header:
                idx = new_header.index(head)
                test_list.append(test[idx])
            else:
                test_list.append[0]

        merged_list.append( test_list  )'''

        # average and other metrics
    merged_avg_row=[]
    for idx, avg in enumerate(new_avg_row):
        if canBeFloat(avg):
            merged_avg_row.append(  safe_division ( float(curr_avg_row[idx]) * (len(merged_list) - len(new_test_list) )  + ( len(new_test_list) *  float(avg) ) , len(merged_list) ) )  
        else:
            merged_avg_row.append( curr_avg_row[idx] )
    merged_other_metrics=[]
    for idx, other in enumerate(new_other_metrics):
        if canBeFloat(other[1]):
            merged_other_metrics.append([other[0], safe_division(((  float(curr_other_metrics[idx][1]) * (len(new_app_ids) -1 ))  + float( other[1] )) , len(new_app_ids) ) ]) 
        else:
            merged_other_metrics.append([other[0], curr_other_metrics[idx][1] + "_" + other[1]])



    return (merged_header,merged_list,merged_avg_row,merged_other_metrics, new_test_types , new_app_ids )
            
 


def generate_app_versions_dict(all_csvs_of_folder):
    csvs_dict={}

    #print(all_csvs_of_folder)
    for csv_file in all_csvs_of_folder:
        app_identifier, app_version = split_app_and_version(csv_file)
        test_type=getTestType(csv_file)
        header, sortedlist, avg_row, other_metrics = sort_csv_test_id(csv_file)
        app_category = sortedlist[0][-1] if len(sortedlist)>0 else 'unknown'
        if len( sortedlist) >= min_csv_row_len :
            #csvs_dict[csv_file] = (header, sortedlist, avg_row)
            app_id = getCriteria(app_identifier,DefaultSemanticVersion(app_version) , sep_criteria,app_category , getWith(csv_file))
            #print(getWith(csv_file))
            if app_id in csvs_dict:
                if DefaultSemanticVersion(app_version) in csvs_dict[app_id]:
                    new_app_ids = csvs_dict[app_id][DefaultSemanticVersion(app_version)][5] + [(app_identifier)]
                    test_types =  csvs_dict[app_id][DefaultSemanticVersion(app_version)][4] + [(test_type)]
                    csvs_dict[app_id][DefaultSemanticVersion(app_version)] = mergeIndividualTests( csvs_dict[app_id][DefaultSemanticVersion(app_version)] , (header, sortedlist, avg_row, other_metrics, test_types,new_app_ids )  )
                else:    
                    csvs_dict[app_id][DefaultSemanticVersion(app_version)] = (header, sortedlist, avg_row, other_metrics,[test_type],[app_identifier])
            else:
                vv={}
                vv[DefaultSemanticVersion(app_version)]= (header, sortedlist, avg_row, other_metrics,[test_type],[app_identifier])
                csvs_dict[app_id] = vv
            #generate_box_plot(header,sortedlist)
        else:
            print(colored("ignoring file :%s " % csv_file ,"red"))


    #print(stats.total_value_increases + stats.total_value_decreases  )
    #print(stats.total_value_increases_major + stats.total_value_decreases_major  )    
   
    return csvs_dict



def getStatistics(csv_dict):

    energy_stats=Statistics()
    time_stats = Statistics()
    gpu_stats = Statistics()
    mem_stats = Statistics()
    cpu_stats = Statistics()
    cov_stats = Statistics()
    method_stats = Statistics()
    loc_stats = Statistics()
    perf_issues_stats = Statistics()
    for v in csvs_dict:
        print("-%s" % v)
       
       # sort csv info by app version
        csvs_dict[v] =  OrderedDict(sorted(csvs_dict[v].items())) #collections.OrderedDict( sorted(v.items(), key=lambda kv: kv[0]) )
        #generate_app_behaviour_plot(v, csvs_dict[v])
        app_list_pairs_version_energy = list( map( lambda zz : (zz[0],zz[1][2][1]) , csvs_dict[v].items()))
        print(app_list_pairs_version_energy)
        
        energy_stats.fill(app_list_pairs_version_energy)
       
        app_list_pairs_version_time = list( map( lambda zz : (zz[0],zz[1][2][2]) , csvs_dict[v].items()))
        time_stats.fill(app_list_pairs_version_time)

        app_list_pairs_version_mem = list( map( lambda zz : (zz[0],zz[1][2][4]) , csvs_dict[v].items()))
        mem_stats.fill(app_list_pairs_version_mem)

        app_list_pairs_version_gpu = list( map( lambda zz : (zz[0],zz[1][2][5]) , csvs_dict[v].items()))
        gpu_stats.fill(app_list_pairs_version_gpu)

        app_list_pairs_version_cpuload = list( map( lambda zz : (zz[0],zz[1][2][3]) , csvs_dict[v].items()))
        cpu_stats.fill(app_list_pairs_version_cpuload)

        app_list_pairs_version_cov = list( map( lambda zz : (zz[0],zz[1][3][5][1]) , csvs_dict[v].items()))
        cov_stats.fill(app_list_pairs_version_cov)
        app_list_pairs_version_methods = list( map( lambda zz : (zz[0],zz[1][3][4][1]) , csvs_dict[v].items()))
        method_stats.fill(app_list_pairs_version_methods)
        app_list_pairs_version_loc = list( map( lambda zz : (zz[0],zz[1][3][0][1]) , csvs_dict[v].items()))
        loc_stats.fill(app_list_pairs_version_loc)
        

        app_list_pairs_version_perfs  = list( map( lambda zz : (zz[0],zz[1][2][6]) , csvs_dict[v].items()))
        perf_issues_stats.fill(app_list_pairs_version_perfs)
    

    #generate_allapps_box_plots_categories(csvs_dict)
    #generate_allapps_behaviour(csvs_dict)
    #generate_allapps_box_plots(csvs_dict)
    #generate_allapps_line_box_by_category(csvs_dict)
    print("### Energy ###")
    energy_stats.printStats("energy")
    print("### Time ###")
    time_stats.printStats("Time")
    print("### MEM ###")
    mem_stats.printStats("Mem")
    print("### GPU LOAD ###")
    gpu_stats.printStats("GPU")
    print("### CPU LOAD ###")
    cpu_stats.printStats("CPU")
    print("### Perf Issues  ###")
    perf_issues_stats.printStats("Performance Issues")
    #print("### Coverage ###")
    #cov_stats.printStats("coverage")
    #print("### Total methods ###")
    #method_stats.printStats("total methods")
    #print("### Total LoC ###")
    #loc_stats.printStats("loc")
    print("TEM QUE SER CHAMADO COM APPI ID E CADA FRAMEWORK SEPARADAMENTE")

def getCriteria(app_id ,app_version, agg_criteria=None, app_category=None, with_type=None ):
    ret_criteria = ""
    if agg_criteria is None:
        return app_version
    if "app_id" in agg_criteria:
        return app_id   
    if "app_category" in agg_criteria:
        ret_criteria=app_category + ret_criteria
    if "major" in agg_criteria:
        crit =  str(app_version.major) 
        ret_criteria = crit  + ( ("_" + ret_criteria) if ret_criteria!="" else "" ) 
    if "minor" in agg_criteria:
        crit =  str(app_version.major) +"." + str(app_version.minor) 
        ret_criteria = crit  + ( ("_" + ret_criteria) if ret_criteria!="" else "" ) 
    if "patch" in agg_criteria:
        crit =  str(app_version.major) +"." + str(app_version.minor) + "."+ str(app_version.patch)
        ret_criteria = crit  + ( ("_" + ret_criteria) if ret_criteria!="" else "" ) 
    if "with" in agg_criteria and with_type!=None :
        ret_criteria+= "_" + with_type
    if "with" in agg_criteria and with_type==None :
        ret_criteria+= "_" + app_id
    if ret_criteria=="":
        return agg_criteria
    return ret_criteria


def getWith(filename):
    if "/com/" in filename:
        return "com"
    elif "/sem/" in filename:
        return "sem"
    else:
        return None


def plotMetric(csvs_dict, m_type , title, xlabel, ylabel, x, y, z=None, agg_criteria=None, filter_zeros=True, min_samples=1, min_apps=1):
    consumption_vers_dict={}
    for app_id ,v in csvs_dict.items():
        i=0
        for av,zz in v.items():
            i = i+1
           
            criteria=(str(getCriteria(app_id,av, agg_criteria,app_category=(zz[1][0][-1] if len(zz)>0 else 'unknown')) + "_" + zz[4][0]) if sep_by_type else str(getCriteria("",av, agg_criteria,app_category=(zz[1][0][-1] if len(zz)>0 else 'unknown')))) 
            if criteria in consumption_vers_dict:
                consumption = zz[x][y][z] if z != None else zz[x][y]
                
                if  canBeFloat(consumption) and float(consumption)>0: 
                    consumption_vers_dict[criteria]['total'] = consumption_vers_dict[criteria]['total'] + float(consumption)
                    consumption_vers_dict[criteria]['count'] =   consumption_vers_dict[criteria]['count'] +1
                    consumption_vers_dict[criteria]['diff_apps'].add(app_id)
                    consumption_vers_dict[criteria]['avg'] =  (consumption_vers_dict[criteria]['total'] +1)  / (consumption_vers_dict[criteria]['count'] +1)
            else:
                consumption = zz[x][y] if z == None else zz[x][y][z]
                if  canBeFloat(consumption) and float(consumption)>0: 
                    consumption_vers_dict[criteria] = {}
                    consumption_vers_dict[criteria]['count'] = 1
                    consumption_vers_dict[criteria]['diff_apps']= set(app_id)
                    #consumption_vers_dict[criteria]['diff_apps'].add(app_id)
                    consumption_vers_dict[criteria]['total'] =  float(consumption)
                    consumption_vers_dict[criteria]['avg'] =  float(consumption)
    

    consumption_vers_dict = dict(filter(lambda elem: elem[1]['count'] >= min_samples and  len(elem[1]['diff_apps']) >= min_apps , consumption_vers_dict.items()))
    consumption_vers_dict=OrderedDict(sorted(consumption_vers_dict.items()))
    
    bar_plot(consumption_vers_dict.keys(), list(map(lambda xx : xx[m_type], consumption_vers_dict.values() )) , xlabel, ylabel, title )


def buildPlots(csvs_dict,criteria=None, filter_zeros=False, min_samples=1, min_apps=5):
    plotMetric(csvs_dict, 'avg', "avg Energy across major versions" , "versions" , "Energy(J)",2,1 ,z=None, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    plotMetric(csvs_dict, 'avg', "LOC across versions" , "versions" , "#LOC",3,5,1, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    plotMetric(csvs_dict, 'avg', "Method Coverage across versions" , "versions" , "%",3,4,1, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples  , min_apps=min_apps )
    plotMetric(csvs_dict, 'avg', "avg Memory across versions" , "versions" , "Mem(kB)",2,4 ,z=None, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    plotMetric(csvs_dict, 'avg', "Elapsed time" , "versions" , "time (s)",2,2 ,z=None, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )

def drawLinePlots(csv_dict,criteria=None, filter_zeros=False, min_samples=1, min_apps=5):
    print("must be used with app_id  as sep_criteria")
    for v in csvs_dict:
        print("-%s" % v)
        csvs_dict[v] =  OrderedDict(sorted(csvs_dict[v].items())) #collections.OrderedDict( sorted(v.items(), key=lambda kv: kv[0]) )
        generate_app_behaviour_plot(v, csvs_dict[v])


def buildBoxPlots(csvs_dict,criteria=None, filter_zeros=False, min_samples=1, min_apps=5):
    generate_box_plot_from_metric(csvs_dict, 'avg', "Energy across versions(%s)" %criteria , "versions" , "Energy(J)",2,1 ,z=None, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    generate_box_plot_from_metric(csvs_dict, 'avg', "LOC across versions(%s)" %criteria , "versions" , "#LOC",3,0,1, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    generate_box_plot_from_metric(csvs_dict, 'avg', "Method Coverage across versions(%s)" %criteria , "versions" , "%",3,5,1, agg_criteria=criteria, filter_zeros=filter_zeros , min_samples=min_samples  , min_apps=min_apps )
    generate_box_plot_from_metric(csvs_dict, 'avg', " Performance Issues(%s)" %criteria , "versions" , "#Issues",2,7 ,z=None, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    
    generate_box_plot_from_metric(csvs_dict, 'avg', " Memory across versions(%s)" %criteria , "versions" , "Mem(kB)",2,4 ,z=None, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )
    generate_box_plot_from_metric(csvs_dict, 'wtver',"elapsed time(%s)" %criteria , "versions" , "time (s)",2,2 ,z=None, agg_criteria=criteria , filter_zeros=filter_zeros , min_samples=min_samples , min_apps=min_apps )




if __name__== "__main__":
    if len(sys.argv) > 1:
        device_folder = sys.argv[1]
        all_csvs_of_folder = fetch_all_data_csvs(device_folder)
        csvs_dict = generate_app_versions_dict(all_csvs_of_folder)
        #for x,y in csvs_dict.items():
        #    print(x)
        #    for v,vv in y.items():
        #        print(v)
        drawLinePlots(csvs_dict)
        #getStatistics(csvs_dict)
        #buildPlots(csvs_dict, criteria="minor", filter_zeros=True, min_samples=5, min_apps=5)
        #generate_test_behaviour_graphs(csvs_dict)
        #buildBoxPlots(csvs_dict, criteria=sep_criteria, filter_zeros=True, min_samples=8, min_apps=8)
        #plt.show()
    else:
        print ("bad arg len")