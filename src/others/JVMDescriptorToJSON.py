
import re,sys, json

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
	return re.sub(r'^L','',full ).replace("/",".").replace(";","").replace("_","")

def getArgList(argList):
	l = []
	defaultsep=";"
	i=0
	while i < len(argList):
		char=argList[i]
		if char=='[':
			innerType = str(getArgList(argList[(i+1):])[0])
			l.append( "[" + innerType + "]")
			i=i+len(innerType)
		elif char=='L':
			i2 = argList.find(";", i, len(argList))
			l.append( parseMethod( argList[i:i2]))
			i=i2
		elif char in knownRetTypes:
			l.append( knownRetTypes[str(char)])
		i=i+1
	return l
	

def buildMethodObjFromLine(matcherObj):
	method={}
	method['threadID']=int(matcherObj.groups()[0])
	method['inout']=matcherObj.groups()[2]
	method['time']= int(matcherObj.groups()[4])
	method['method']=re.sub(r'^(\.)+','',matcherObj.groups()[6])
	method['args']= getArgList(matcherObj.groups()[8]) 
	method['return']= getArgList(matcherObj.groups()[9])[0] 
	method['file'] = matcherObj.groups()[11]
	return method


def loadprocesstracesRegex(fileName):
	with open(fileName) as f:
		all_traces = f.read().splitlines()
	i = 0
	methods=[]
	for trace in all_traces:
		
		#print(trace)
		# tem erro
		x=re.search(r"^([0-9]+)*(\s)+(xit|ent)(\s)+([0-9]+)+(\s|\-)([\w+.$]+)(\s)+\((.*?)\)(.*)(\s)+(.*)", trace)
		#print(len(x.groups()))
		# well formed trace line
		if x and len(x.groups())==12:
			#print(x.groups())
			method = buildMethodObjFromLine(x)
			methods.append(method)
			print(i)
		i=i+1

def dummySeparator(traceLine):
	#print(traceLine)
	spacesplit=traceLine.replace("\t"," ").split(" ")
	method={}
	#method['method']=re.sub(r'^(\.)+','',spacesplit[0])
	method['name']= re.sub(r'^(\.)+','',spacesplit[0]).split(".")[-1]
	method['class']= re.sub(r'^(\.)+','',spacesplit[0]).replace("."+method['name'],"")
	method['args']= getArgList( (spacesplit[1]).split(")")[0] ) 
	method['return']= getArgList( (spacesplit[1]).split(")")[1] ) [0]
	method['file'] = spacesplit[-1]
	#method['id'] = generateMethodId(method)
	return method


def parseDescriptorsFile(filename):
	all_descriptors=[]
	methods_dict={}
	with open(filename) as f:
		all_descriptors = f.read().splitlines()
	for line in all_descriptors:
		jo={}
		jo = dummySeparator(line)
		if jo['class'] in methods_dict:
			methods_dict[jo['class']].append(jo)
		else:
			methods_dict[jo['class']]=[]
			methods_dict[jo['class']].append(jo)

	with open( filename.replace(".txt",".json"), "w") as outfile:
		json.dump( methods_dict , outfile,indent=2)


if __name__== "__main__":
	if len(sys.argv) > 1:
		print("parsing descriptors of file " + sys.argv[1]  )
		parseDescriptorsFile(sys.argv[1])
	else:
		print ("arg required ( filename )")



