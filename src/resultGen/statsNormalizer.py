#!/usr/bin/env python
# -*- coding: utf-8 -*-
import re
import sys
import os
import io
import json
from termcolor import colored
from jsoncomment import JsonComment
import subprocess
import os.path
from os import path

output_folder = '/Users/ruirua/repos/Anadroid/aux_test_results_dir/'

list_of_fields = ['cpuloadnormalized','memoryusage','energyconsumed','elapsedtime']
all_fields = ['begin_used_cpu','batteryremaining','cpu1load','cpu4load','begin_main_cpu_freq','cpu3frequency','begin_nr_procceses','begin_nr_files_keyboard_folder','end_ischarging','memoryusage','end_used_mem_kernel','cpu1frequency','cpu2load','cpuloadnormalized','end_main_cpu_freq','end_battery_temperature','end_used_cpu','begin_keyboard','batterystatus','begin_battery_temperature','begin_used_mem_kernel','cpuload','batterypower','end_nr_files_keyboard_folder','applicationstate','begin_ischarging','begin_used_mem_pss','gpuload','cpu4frequency','gpufrequency','begin_battery_level','cpu3load','elapsedtime','screenbrightness','end_used_mem_pss','end_battery_level','begin_battery_voltage','end_keyboard','cpu2frequency','description','end_battery_voltage','end_nr_procceses','energyconsumed']
fields_w_3_values = ['batteryremaining','cpu1load','cpu4load','cpu3frequency','memoryusage','cpu1frequency','cpu2load','cpuloadnormalized','batterystatus','cpuload','batterypower','applicationstate','gpuload','cpu4frequency','gpufrequency','cpu3load','screenbrightness','cpu2frequency','description']
special_fields = ['begin_used_cpu','end_used_cpu']



def getCategoryPlayStore(string_folder):
    filename=string_folder+"app_play_category.log"
    f = open (filename, "r") 
    s= f.read().replace("\n","")
    return "unknown" if s=="" else s

# vai buscar os dados ao file de outrput da ferramenta scc
def getSourceCodeMetrics(metrics_dict,string_folder):
    #print(string_folder)

    loc_info=string_folder+"/cloc.out"    
    try:
        metrics_dict['total_loc']=int(subprocess.check_output(" grep \"Total\" %s | xargs | cut -f6 -d\ " % loc_info, shell=True).decode("utf-8").strip().split("\n")[0])
    except Exception as e:
        metrics_dict['total_loc']=-1

    try:
        metrics_dict['total_complexity']=int(subprocess.check_output(" grep \"Total\" %s | xargs | cut -f7 -d\ " % loc_info, shell=True).decode("utf-8").strip().split("\n")[0])
    except Exception as e:
        metrics_dict['total_complexity']=-1

    
    try:
        metrics_dict['total_loc_java']=int(subprocess.check_output(" grep \"Java\" %s | xargs | cut -f6 -d\ " % loc_info, shell=True).decode("utf-8").strip().split("\n")[0])
    except Exception as e:
        metrics_dict['total_loc_java']=0
    try:
        metrics_dict['total_loc_kotlin']=int(subprocess.check_output(" grep \"Kotlin\" %s | xargs | cut -f6 -d\ " % loc_info, shell=True).decode("utf-8").strip().split("\n")[0])
    except Exception as e:
        metrics_dict['total_loc_kotlin']=0
    return metrics_dict


# vai buscar os dados aos files de log 
def getCoverageMetrics(metrics_dict,string_folder):
    total_traced_methods_file= string_folder +"/total_traced_methods.log"
    total_coverage_file= string_folder +"/total_coverage.log"
    try:
        metrics_dict['total_traced_methods']=int(subprocess.check_output(" cat %s " % total_traced_methods_file, shell=True).decode("utf-8").strip().split("\n")[0])
    except Exception as e:
        metrics_dict['total_traced_methods']=0
    try:
        metrics_dict['total_coverage']=float(subprocess.check_output(" cat %s " % total_coverage_file, shell=True).decode("utf-8").strip().split("\n")[0])
    except Exception as e:
        metrics_dict['total_coverage']=0

    return metrics_dict


def getPermissionsAsString(string_folder):
        filename= string_folder + "appPermissions.json"
        if (not path.exists(filename)):
            return ''
        with open(filename) as json_file:
            data = json.load(json_file)
        #print(data)
        return " ".join( list( map ( lambda x : x['permission'], data ) ))
    
def getInvokedAPISAsString(string_folder,test_id):
        filename= string_folder + "redAPIs.json"
        if not path.exists(filename):
            return ''
        with open(filename,encoding='utf-8') as json_file:
            data = json.load(json_file)
        if test_id not in data:
            return ''      
        return " ".join(   [j for i in data[test_id].values() for j in i] )

def getPerformanceLintIssues(string_folder, filter_severity=False , filter_threshold=6 ):
    filename= string_folder + "lintIssues.json"
    if not path.exists(filename):
        return ''
    with open(filename,encoding='utf-8') as json_file:
        data = json.load(json_file)

    if filter_severity and "Performance" in data:
        z = list( filter ( lambda x : int(x[1]) >=filter_threshold , data["Performance"]   ) )
        #print("%s has %d perf issues" % ( string_folder, len(z) ))
        if len(z)>0:
            print("olha este " + string_folder)
        return z
    
    else:
        return data["Performance"] if "Performance" in data else []



def getBandAStats(string_folder, test_id, end=True):
    filename = string_folder + "end_state" + test_id +".json" if end else string_folder + "begin_state" + test_id +".json"
    if (not path.exists(filename)):
            return {}
    #print(filename)
    f = open (filename, "r") 
    s= f.read()
    string=s.replace("\n\"","\"")
    string = re.sub(",[ \t\r\n]+}", "}", string)
    string = re.sub(",[ \t\r\n]+\]", "]", string)
    data = json.loads(string, strict=False) 
    for key, value in data.items():
        if value == "FALSE":
            data[key] = 0
        elif value == "TRUE":
            data[key] = 1
    #print(data)
    return data

# vai buscar outras metricas relativas à globalidade dos testes executados
# e linhas de codigo obtidas com o scc
def getOtherMetricsFromFolder(string_folder):
    metrics_dict={}
    metrics_dict=getSourceCodeMetrics(metrics_dict,string_folder)
    metrics_dict=getCoverageMetrics(metrics_dict,string_folder)
    #for x in output.decode("utf-8").strip().split("\n"):)
    return metrics_dict

def data_to_csv(data,string_folder):
    app_category=getCategoryPlayStore(string_folder)
    perms_col = getPermissionsAsString(string_folder)
    begin_metrics = getBandAStats(string_folder, "1", end=False)
    end_metrics = getBandAStats(string_folder, "1", end=True)
    total_gpuload = 0
    total_cpuloadnormalized = 0
    total_memoryusage = 0
    total_enegyconsumed = 0
    total_elapsedtime = 0
    total_coverage = 0
    otherMetrics = getOtherMetricsFromFolder(string_folder)
    f = open(string_folder + "all_data.csv", "w")
    f.write("test_id; energy cons (J); time elapsed (ms); cpuloadnormalized (%); memoryusage (KB); gpuload (%); coverage (%)")
    for x in otherMetrics.keys():
        f.write(";"+str(x))
    for x in begin_metrics.keys():
        f.write(";"+str(x)+"_begin")
    for x in end_metrics.keys():
        f.write(";"+str(x)+"end")
    f.write(";"+"perf_issues")
    f.write(";"+"red_apis")
    f.write(";"+"app_category")
    f.write('\n')
    for line in data: 
        #total_gpuload = total_gpuload + float(line['gpuload'])
        total_cpuloadnormalized = total_cpuloadnormalized + float(line['cpuloadnormalized'])
        total_memoryusage = total_memoryusage + float(line['memoryusage'])
        total_enegyconsumed = total_enegyconsumed + float(line['energyconsumed'])
        total_elapsedtime = total_elapsedtime + float(line['elapsedtime'])
        total_elapsedtime = total_elapsedtime + float(line['elapsedtime'])
        total_coverage = total_coverage + float(line['coverage'])
        f.write(str(line['test_id']) + ';' + str(line['energyconsumed'])+ ';' + str(line['elapsedtime']) + ';' + str(line['cpuloadnormalized']) + ';' + str(line['memoryusage']) + ';' + str(line['gpuload']) + ';' + str(line['coverage']))
        for y in otherMetrics.values():
            f.write(";"+str(y))
        for y in begin_metrics.values():
            f.write(";"+str(y))
        for y in end_metrics.values():
            f.write(";"+str(y))
        f.write(";"+getInvokedAPISAsString(string_folder,line['test_id'] ))
        f.write(";" + str(len(getPerformanceLintIssues(string_folder, filter_severity=True,filter_threshold=6))))
        #print( string_folder + "tem n issues " + str(len(getPerformanceLintIssues(string_folder))))
        f.write(";" + str(len(getInvokedAPISAsString(string_folder,line['test_id'] ))))
        f.write(";" + app_category)
        f.write("\n")
        
    size = len(data)
    average_gpuload =  total_gpuload / size
    average_cpuloadnormalized = total_cpuloadnormalized / size
    average_memoryusage = total_memoryusage / size
    average_enegyconsumed = total_enegyconsumed / size
    average_elapsedtime = total_elapsedtime / size
    average_coverage = total_coverage / size
    f.write('average' + ';' + str(average_enegyconsumed)+ ';' + str(average_elapsedtime) + ';' + str(average_cpuloadnormalized) + ';' + str(average_memoryusage) + ';' + str(average_gpuload) + ';' + str(average_coverage) + ";" +  str(len(getPerformanceLintIssues(string_folder,filter_severity=True,filter_threshold=6))) )
    f.write('\n')
   
    for x,y in otherMetrics.items():
        f.write("%s; %s\n" %(str(x),str(y)))
    f.close()


def sort_and_filter_data(data):
    new = {}
    for stat in data:
        new['test_id'] = stat['test_results']
        if stat['metric'] == 'cpuloadnormalized':
            value = stat['value_text'].split(',')[1]
            new[stat['metric']] = value
        elif stat['metric'] == 'memoryusage':
            value = stat['value_text'].split(',')[1]
            new[stat['metric']] = value
        elif stat['metric'] == 'coverage':
            value = stat['value_text']
            new[stat['metric']] = value
        elif stat['metric'] == 'gpuload':
            value = stat['value_text'].split(',')[1]
            new[stat['metric']] = value
        else:
            if stat['metric'] in list_of_fields:
                new[stat['metric']] = stat['value_text']
    return new

def getStats(all_folders):
    total=0
    for folder in all_folders:
        stats = []
        string_folder = folder + "/"
        for filename in os.listdir(folder):
            if filename.endswith(".json") and "resume" in filename and filename.startswith('test'):
                with open(string_folder + filename) as json_file:
                    #print(string_folder + filename)
                    new = []
                    try:
                        data = json.load(json_file)
                    except Exception as e:
                        continue
                    stats.append(sort_and_filter_data(data))
            #if filename.endswith("coverage.log") and filename.startswith('test'):
            #    jo={}
            #    jo['test_coverage']=float(subprocess.check_output(" cat %s " % (string_folder + filename), shell=True).decode("utf-8").strip().split("\n")[0])
            #    stats.append(jo)
                
        if len(stats)>0:
            data_to_csv(stats,string_folder)
            total=total+1
    return total

def getFolders():
    all_folders = []
    for (dirpath, dirnames, filenames) in os.walk(output_folder):
        if "oldRuns" not in str(dirpath):
            all_folders.append(dirpath)
    return all_folders

def cleanFolders(keyboard_folders):
    for folder in keyboard_folders:
        for filename in os.listdir(folder):
            str_filename = folder + '/' + filename
            if os.path.isfile(str_filename):
                os.remove(str_filename)


if __name__== "__main__":
    all_folders = getFolders()
    #print(all_folders)
    #cleanFolders(statsfolders)
    x=getStats(all_folders)
    #getKeyboardsStats(all_folders)
    print(colored("[Success] Created " + str(x) + " resume files!","green"))
    
            
                        
        

