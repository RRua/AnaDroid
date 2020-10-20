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
from ordered_set import OrderedSet
from plotGenerator import DefaultSemanticVersion


def safe_division(n, d):
	return n / d if d else 0




def generate_allapps_box_plots_by_category(apps_dict):
	
	min_vers_samples = 2
	min_diff_apps = 2
	vers_energy_pairs = {}
	for app in apps_dict:
		app_category = list(apps_dict[app].values())[0][1][0][-1]
		app_list_pairs_version_energy = list(filter( lambda y : str(y[0])!='0.0.0'  , map( lambda zz : (str(zz[0]),float(zz[1][-3][1])) , apps_dict[app].items())))
		#max_energy_app = 0 if len(app_list_pairs_version_energy)==0 else  max( list( map( lambda x : float(x[1]) , app_list_pairs_version_energy  ) ) )
		#xy_data = list(map( lambda x : (x[0],safe_division(float(x[1]), max_energy_app)) , app_list_pairs_version_energy ))
		if app_category not in vers_energy_pairs:
			vers_energy_pairs[app_category]={}			
		for version,energy in app_list_pairs_version_energy:
			vv=DefaultSemanticVersion( version).major
			if vv not in vers_energy_pairs[app_category]:
				vers_energy_pairs[app_category][vv] = {}
				vers_energy_pairs[app_category][vv]['count']=0
				vers_energy_pairs[app_category][vv]['total']=0
				vers_energy_pairs[app_category][vv]['values']=[]
				vers_energy_pairs[app_category][vv]['diffs']=set()
			vers_energy_pairs[app_category][vv]['count']+=1
			vers_energy_pairs[app_category][vv]['total']+=energy
			vers_energy_pairs[app_category][vv]['values'].append(energy)
			vers_energy_pairs[app_category][vv]['diffs'].add(app)

	final_vers_energy_pairs = {}
	for cat, vers_vals in vers_energy_pairs.items():
		temp_dict={}
		for v,data in vers_vals.items():
			if data['count'] >= min_vers_samples and len(data['diffs']) >= min_diff_apps:
				temp_dict[v] = data
		if len(temp_dict.keys())>0:
			final_vers_energy_pairs[cat]=temp_dict

	print(final_vers_energy_pairs)
	# ordenar

	for category, vdata in final_vers_energy_pairs.items():
		fig1, en_box = plt.subplots()
		print("---")
		print(final_vers_energy_pairs[category])
		print("---")
		bp_dict = en_box.boxplot(list(map(  lambda elem: elem[1]['values'] , final_vers_energy_pairs[category].items() )),   patch_artist=True)
		print("---")

		i = 0
		for line in bp_dict['medians']:
			x, y = line.get_xydata()[1] # top of median line
			xx, yy =line.get_xydata()[0] 
			text(x, y, '%.2f' % y, fontsize=6) # draw above, centered
			#text(xx, en_box.get_ylim()[1] * 0.98, '%.2f' % np.average(list_all_samples[i]), color='darkkhaki') 
			i = i +1
	  
		# set colors
		colors = ['lightblue', 'darkkhaki']
		i=0
		for bplot in bp_dict['boxes']:
			i=i+1
			bplot.set_facecolor(colors[i%len(colors)])

		xtickNames = plt.setp(en_box, xticklabels=vdata.keys())
		plt.setp(xtickNames, rotation=90, fontsize=5)
		plt.show()

# categoria sem distinguir versoes. da os valores absolutos e filtra
#por categoria com varias samples e varias apps diffs

def generate_allapps_box_plots_categories(apps_dict):
	fig1, en_box = plt.subplots()
	min_vers_samples = 20
	min_diff_apps = 5 
	vers_energy_pairs = {}
	for app in apps_dict:
		app_category = list(apps_dict[app].values())[0][1][0][-1]
		app_list_pairs_version_energy = list(filter( lambda y : str(y[0])!='0.0.0'  , map( lambda zz : (str(zz[0]),float(zz[1][-3][1])) , apps_dict[app].items())))
		#max_energy_app = 0 if len(app_list_pairs_version_energy)==0 else  max( list( map( lambda x : float(x[1]) , app_list_pairs_version_energy  ) ) )
		#xy_data = list(map( lambda x : (x[0],safe_division(float(x[1]), max_energy_app)) , app_list_pairs_version_energy ))
		for version,energy in app_list_pairs_version_energy:
			if app_category not in vers_energy_pairs:
				vers_energy_pairs[app_category] = {}
				vers_energy_pairs[app_category]['count']=0
				vers_energy_pairs[app_category]['total']=0
				vers_energy_pairs[app_category]['values']=[]
				vers_energy_pairs[app_category]['diffs']=set()
			vers_energy_pairs[app_category]['count']+=1
			vers_energy_pairs[app_category]['total']+=energy
			vers_energy_pairs[app_category]['values'].append(energy)
			vers_energy_pairs[app_category]['diffs'].add(app)

	final_vers_energy_pairs = {}
	for v, data in vers_energy_pairs.items():
		if data['count'] > min_vers_samples and len(data['diffs']) > min_diff_apps:
			final_vers_energy_pairs[v] = data
	# ordenar

	bp_dict = en_box.boxplot(list(map(  lambda elem: elem[1]['values'] , final_vers_energy_pairs.items() )),   patch_artist=True)
	i = 0
	for line in bp_dict['medians']:
		x, y = line.get_xydata()[1] # top of median line
		xx, yy =line.get_xydata()[0] 
		text(x, y, '%.2f' % y, fontsize=6) # draw above, centered
		#text(xx, en_box.get_ylim()[1] * 0.98, '%.2f' % np.average(list_all_samples[i]), color='darkkhaki') 
		i = i +1
  
	# set colors
	colors = ['lightblue', 'darkkhaki']
	i=0
	for bplot in bp_dict['boxes']:
		i=i+1
		bplot.set_facecolor(colors[i%2])

	xtickNames = plt.setp(en_box, xticklabels=final_vers_energy_pairs.keys())
	plt.setp(xtickNames, rotation=90, fontsize=5)
	plt.show()


# gera boxplots para versoes

def generate_allapps_box_plots(apps_dict):
	fig1, en_box = plt.subplots()
	x_samples = 8 
	vers_energy_pairs = {}
	for app in apps_dict:
		app_list_pairs_version_energy = list(filter( lambda y : str(y[0])!='0.0.0'  , map( lambda zz : (str(zz[0]),zz[1][-3][1]) , apps_dict[app].items())))
		max_energy_app = 0 if len(app_list_pairs_version_energy)==0 else  max( list( map( lambda x : float(x[1]) , app_list_pairs_version_energy  ) ) )
		xy_data = list(map( lambda x : (x[0],safe_division(float(x[1]), max_energy_app)) , app_list_pairs_version_energy ))
		for version,energy in xy_data:
			vv = DefaultSemanticVersion(version).major
			if vv not in vers_energy_pairs:
				vers_energy_pairs[vv] = {}
				vers_energy_pairs[vv]['count']=0
				vers_energy_pairs[vv]['total']=0
				vers_energy_pairs[vv]['values']=[]
			vers_energy_pairs[vv]['count']+=1
			vers_energy_pairs[vv]['total']+=energy
			vers_energy_pairs[vv]['values'].append(energy)

	final_vers_energy_pairs = {}
	for v, data in vers_energy_pairs.items():
		#print(data)
		if data['count'] > x_samples:
			final_vers_energy_pairs[v] = data

	final_vers_energy_pairs = OrderedDict(sorted(final_vers_energy_pairs.items(),key=(lambda x : int(x[0])) ))
	print(final_vers_energy_pairs.keys())

	bp_dict = en_box.boxplot(list(map(  lambda elem: elem[1]['values'] , final_vers_energy_pairs.items() )),   patch_artist=True)
	i = 0
	for line in bp_dict['medians']:
		x, y = line.get_xydata()[1] # top of median line
		xx, yy =line.get_xydata()[0] 
		text(x, y, '%.2f' % y, fontsize=6) # draw above, centered
		#text(xx, en_box.get_ylim()[1] * 0.98, '%.2f' % np.average(list_all_samples[i]), color='darkkhaki') 
		i = i +1
  
	# set colors
	colors = ['lightblue', 'darkkhaki']
	i=0
	for bplot in bp_dict['boxes']:
		i=i+1
		bplot.set_facecolor(colors[i%len(colors)])

	xtickNames = plt.setp(en_box, xticklabels=final_vers_energy_pairs.keys())
	plt.setp(xtickNames, rotation=90, fontsize=5)
	plt.show()

#generates line plot for pairs version, energy for all apps
# filters version with < x samples
def generate_allapps_behaviour(apps_dict):
	x_samples = 8 
	vers_energy_pairs = {}
	for app in apps_dict:
		app_list_pairs_version_energy = list(filter( lambda y : str(y[0])!='0.0.0'  , map( lambda zz : (str(zz[0]),zz[1][-3][1]) , apps_dict[app].items())))
		max_energy_app = 0 if len(app_list_pairs_version_energy)==0 else  max( list( map( lambda x : float(x[1]) , app_list_pairs_version_energy  ) ) )
		xy_data = list(map( lambda x : (x[0],safe_division(float(x[1]), max_energy_app)) , app_list_pairs_version_energy ))
		for version,energy in xy_data:
			if version not in vers_energy_pairs:
				vers_energy_pairs[version] = {}
				vers_energy_pairs[version]['count']=0
				vers_energy_pairs[version]['total']=0
				vers_energy_pairs[version]['values']=[]
			vers_energy_pairs[version]['count']+=1
			vers_energy_pairs[version]['total']+=energy
			vers_energy_pairs[version]['values'].append(energy)

	final_vers_energy_pairs = {}
	for v, data in vers_energy_pairs.items():
		#print(data)
		if data['count'] > x_samples:
			final_vers_energy_pairs[v] = data

	final_vers_energy_pairs= OrderedDict(sorted(final_vers_energy_pairs.items(), key=sortPair))
	print(final_vers_energy_pairs)

	final_list_pairs= list ( map( lambda x : ( x[0] , safe_division ( x[1]['total']  , x[1]['count']  )  ) , final_vers_energy_pairs.items() ) )
	final_list_pairs.sort(key=sortPair)
	#print(final_list_pairs)
	line_plot( list( map ( lambda x : x[0] , final_list_pairs ) ) , list( map ( lambda x : x[1] , final_list_pairs ) ) ,'ww','ss','ss' )


def sortPair(xy):
	return DefaultSemanticVersion(xy[0])

def generate_app_behaviour_plot(appname,app_dict):
	print(appname)
	#print(app_dict)
	avg_coverage = max(list( map( lambda zz : float(zz[1][-3][6]) , app_dict.items())))
	#print(avg_coverage)
	#exit(0)
	app_list_pairs_version_energy = list( map( lambda zz : (zz[0],zz[1][-3][1]) , app_dict.items()))
	x_data = list( map( lambda x : str(x[0]) , app_list_pairs_version_energy ) )
	y_data = list( map( lambda x : float(x[1]) , app_list_pairs_version_energy ) )
	max_y = max(y_data)
	y_data = list(map( lambda x : safe_division(x, max_y) , y_data ))
	
	if(max_y>10 and avg_coverage > 10.0):
		print("filtering > 10 julios and coverage > 10")
		print("coverage =" + str(avg_coverage))
		line_plot(x_data,y_data, "versions", "energy", "%s max: %f" % (appname , max_y) )


def line_plot(x_data,y_data, x_label, y_label, plot_title):
	
	fig, ax = plt.subplots()
	ax.plot(x_data, y_data)

	ax.set(xlabel=x_label, ylabel=y_label,title=plot_title)
	ax.set_ylim(0,1)
	ax.grid()

	#fig.savefig(str(plot_title)+".png")
	plt.show()
