from androguard.misc import AnalyzeAPK, AnalyzeDex
from androguard.core.analysis.analysis import ExternalMethod
import matplotlib.pyplot as plt
import networkx as nx
import time
import sys
import pprint
import re
import json
#start = time.time()


#fa, d, dx = AnalyzeAPK("simiasque-debug.apk")

knownRetTypes  = {
	"V" : "Void" ,
	"Z"	: "boolean",
	"B"	: "byte",
	"S"	: "short",
	"C"	: "char",
	"I"	: "int",
	"J"	: "long",
	"F"	:"float",
	"D"	: "double",

}

# Note: If you create the CFG from many classes at the same time, the drawing
# will be a total mess...


def inferType(st):
	if(len(st)>0):
		if "[" in st:
			#array . ex: I[]
			return "[" + inferType(st[1:]) + "]"
		if len(st) >1:
			return parseMethod( st)
		elif st[0] in knownRetTypes:
			return knownRetTypes[st]
	return ""



def parseMethod( full):
	return full.replace("^L",'' ).replace("/",".").replace(";","").replace("_","")

def rreplace(mystr, reverse_removal, reverse_replacement):
	return mystr[::-1].replace(reverse_removal, reverse_replacement, 1)[::-1]


def trolhaSep( mystr, separator):
	r = ""
	l = mystr.split(separator)
	for i  in range(0, len(l)-1 ):
		r+= l[i]+ separator
	return rreplace(r, separator, "")


def parseDescriptors(descriptor):
	st = "("
	defaultsep=" "
	real = re.search(r"\(.*\)", descriptor)
	if real is not None:
		for s in real.group(0).split(defaultsep):
			x = s.replace("(","").replace(")","")
			if len(x)>0:
				st += inferType(x)+ ","
		return rreplace(st, ",","") + ")" 
	else:
		return "()"



def descriptorToJSON(jsonObj, descriptor):
	st = ""
	defaultsep=" "
	jsonObj['return'] = inferType(descriptor.split(")")[1])
	jsonObj['args'] = []
	real = re.search(r"\(.*\)", descriptor)
	if real is not None:
		for s in real.group(0).split(" "):
			rs= s.replace("(","").replace(")","")
			if len(rs)>0:
				jsonObj['args'].append( inferType(rs))
	return jsonObj

def parseArgs(descriptor):
	l = []
	defaultsep=" "
	real = re.search(r"\(.*\)", descriptor)
	if real is not None:
		for s in real.group(0).split(defaultsep):
			x = s.replace("(","").replace(")","")
			if len(x)>0:
				l.append(inferType(x))
	return l
	



def methodStringToJSON(method_string):
	jsonObj = {}
	z =  re.search(r'->.*\)([A-Za-z]|\/)+', method_string)
	if z is not None:
		method_name = z.group(0)
		jsonObj['return'] = inferType(method_name.split(")")[1])
		jsonObj['args'] = []
		l = method_string.split("->")
		if len(l)==2:
			class_name = parseMethod(l[0])
			x = method_name.replace("->","").split("(")
			method_name_s = x[0]
			jsonObj['name'] =  parseMethod( class_name + "." + method_name_s)
			jsonObj['args'] = (parseArgs("("+x[1]))
	return jsonObj

		



def eval(path, pack ):
	fa, d, dx = AnalyzeAPK(path)
	CFG = nx.DiGraph()
	graph = {}
	pack_redefined = pack.replace(".","/")
	pack_redefined = trolhaSep(pack_redefined, "/")
	for c in dx.find_classes(name=(".*"+ pack_redefined+  ".*")):
		for m  in dx.find_methods():
			orig_method = m.get_method()
			if re.match(".*"+ trolhaSep(pack_redefined, "/")  +".*", m.get_method().get_class_name()):
				m_id = {}
				m_id['name'] = ( parseMethod(orig_method.get_class_name() + orig_method.get_name()))
				descriptorToJSON(m_id, orig_method.get_descriptor() )
				m_id['apis'] = []
				#print(m_id)
				if len(m.get_xref_to()) >0:
					graph[m_id['name']] = m_id
				#print("\n | \n v \n")
				for other_class, callee, offset in m.get_xref_to():
					#print(callee.get_class_name() + "." + callee.get_name())
					#print( callee)
					z = methodStringToJSON(str(callee))
					m_id['apis'].append(z)
						#graph[m_id['name']].append()
						#print(calle_id)
	new_dic = list(graph.values())
	with open( pack+".json", 'w') as outfile:  
		json.dump(new_dic, outfile)
	

if __name__== "__main__":
	if len(sys.argv) > 1:
		eval(sys.argv[1], sys.argv[2])
	else:
		print ("2 args required ( <apk-path> <package-name>  )")
