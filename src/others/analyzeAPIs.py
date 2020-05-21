#!/usr/bin/python3.6
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
	"D"	: "double"
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
	full = re.sub(r'^\[', '',full)
	return re.sub(r'^L','',full ).replace("/",".").replace(";","").replace("_","")

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



def methodDescriptorToJSON(jsonObj, descriptor):
	st = ""
	defaultsep=" "
	jsonObj['method_return'] = inferType(descriptor.split(")")[1])
	jsonObj['method_args'] = []
	real = re.search(r"\(.*\)", descriptor)
	if real is not None:
		for s in real.group(0).split(" "):
			rs= s.replace("(","").replace(")","")
			if len(rs)>0:
				jsonObj['method_args'].append( inferType(rs))
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
	



def methodAPIStringToJSON(method_string):
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



def parseClassName(classname):
	x = re.sub(r'\$[0-9]+', '', classname)
	return re.sub(r'\$', '.', x)


def inferPackage(classname):
	last_tok_list = classname.split('.')[:-1]
	return '.'.join(last_tok_list)

def eval(path, pack ):
	fa, d, dx = AnalyzeAPK(path)
	graph = {}
	pack_redefined = pack.replace(".","/")
	pack_redefined = trolhaSep(pack_redefined, "/")
	for c in dx.find_classes(name=(".*"+ pack_redefined+  ".*")):
		classe = {}
		class_name  = parseClassName(parseMethod(c.name))
		classe['class_name'] = class_name
		#print("classname ->" + c.name)
		classe['class_superclass'] = parseMethod(c.extends)
		classe['class_implemented_ifaces'] = list(map(parseMethod, c.implements)) # parseMethod(c.implements)
		classe['class_fields'] =[]
		classe['class_package'] = inferPackage(parseMethod(c.name))
		#print(c)
		for field in c.get_fields():
			classe['class_fields'].append(inferType(field.get_field().get_descriptor()))
			#print("field->"+field.get_field().get_class_name())
		classe['class_methods'] = {}
		m_index = 0
		for m  in c.get_methods():
			orig_method = m.get_method()
			# class encodedmethod
			#print(orig_method.get_name() +"limpo :"  + parseMethod(orig_method.get_name()))
			#if re.match(".*"+ trolhaSep(pack_redefined, "/")  +".*", m.get_method().get_class_name()+".*"):
			m_id = {}
			#print(orig_method.get_access_flags_string())
			m_id['method_name'] = ( class_name +"->"+ (orig_method.get_name())) 
			methodDescriptorToJSON(m_id, orig_method.get_descriptor() )
			m_id['method_modifiers'] = orig_method.get_access_flags_string()
			m_id['method_apis'] = []
			m_id['method_class']= class_name
			try:
				m_id['method_locals']= orig_method.get_locals()
				m_id['method_length'] = orig_method.get_length()
				m_id['method_nr_instructions'] = len(list(orig_method.get_instructions()))
			except Exception as e:
				m_id['method_length'] = -1
				m_id['method_nr_instructions'] = -1 #len(list(orig_method.get_instructions()))
			
			str_id = m_id['method_name'] + "#" + str(m_index)
			m_index = m_index +1
			if len(m.get_xref_to()) >0:
				classe['class_methods'][str_id] = m_id
			for other_class, callee, offset in m.get_xref_to():
				m_id['method_apis'].append(methodAPIStringToJSON(str(callee)))
			classe['class_methods'][ str_id ] = m_id
		graph[classe['class_name']] = classe
	with open( pack+".json", 'w') as outfile:  
		json.dump(graph, outfile, indent=3)
	

if __name__== "__main__":
	if len(sys.argv) > 2:
		#print("apk analyzer called with " + sys.argv[1] + "  " +sys.argv[2] )
		eval(sys.argv[1], sys.argv[2])
	else:
		print ("2 args required ( <apk-path> <package-name>  )")
