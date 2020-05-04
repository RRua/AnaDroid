
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

	method['threadID']=spacesplit[0]
	method['inout']=spacesplit[1]
	i=2
	while spacesplit[i]=="":
		i=i+1
	time=spacesplit[i]
	if "-" in time:
		x=time.split("-")
		method['time']=int(x[0])
		method['method']=re.sub(r'^(\.)+','',x[1])
	else:
		method['time']= int(time)
		#time is right, get method
		method['method']=re.sub(r'^(\.)+','',spacesplit[i+1])
		i=i+1
	method['args']= getArgList( (spacesplit[i+1]).split(")")[0] ) 
	method['return']= getArgList( (spacesplit[i+1]).split(")")[1] ) [0]
	method['file'] = spacesplit[i+2]
	method['id'] = generateMethodId(method)
	return method


def loadprocesstraces(fileName):
	with open(fileName) as f:
		all_traces = f.read().splitlines()
	m_dict={}
	methods=[]
	method_traces=False
	m1=None
	for trace in all_traces:
		
		if trace.startswith("Trace"):
			method_traces=True
			continue			

		if method_traces:
			m2=dummySeparator(trace)
			methods.append(m2)
			m2id=generateMethodId(m2)
			if m2id in m_dict:
				m_dict[m2id].append(m2)
			else:
				m_dict[m2id]= []
				m_dict[m2id].append(m2)
			

			
			#print(i)
	return methods,m_dict

def generateMethodId(method_obj):
	return hash(method_obj['method'] + str(method_obj['args']) + method_obj['return'] )



def allMethodsBetween(startI, methodsList ,maxTime, threadID):
	startIndex=startI
	calledMethod={}	
	if startIndex<len(methodsList):
		method=methodsList[startIndex]
		mtime= method['time'] 
		while startIndex<len(methodsList):
			method=methodsList[startIndex]
			mtime= method['time']
			if not mtime < maxTime or threadID !=  method['threadID'] :
				break
			if method['id'] in calledMethod : #and 
				if method['inout'] != "xit":
					calledMethod[ method['id'] ] = calledMethod[ method['id'] ] +1 
			else:
				calledMethod[ method['id'] ] = 1
			startIndex=startIndex+1
			#print(mtime)
	return calledMethod

def buildCallInfo(methodsList,m_dict):
	methods_of_package_counter=0
	for x in xrange(0,len(methodsList)):
		method=methodsList[x]
		if method['inout'] == "ent":
			#print(method)
			if app_package is not None and method['method'].startswith(app_package):
				print(method['method'] + "e do pack")
			mid = method['id']
			mtime= method['time']
			tid= method['threadID']
			end_time = mtime
			calledmethods=[]
			all_method_calls= m_dict[mid]
			skipp_calls = 1
			i=1
			# find matching exit call
			while skipp_calls>0 and i < len(all_method_calls):
				target_method = all_method_calls[i]
				if target_method['time'] > mtime:
					# candidate
					if target_method['inout'] == "xit":
						skipp_calls=skipp_calls-1	
						end_time = all_method_calls[i]['time']		
					else:
						skipp_calls=skipp_calls+1
				i=i+1
			#print(end_time)
			method['duration']= end_time - mtime
			method['methods_invoked'] = allMethodsBetween(x+1, methodsList, end_time ,tid )
			#method['methods_invoked'] = calledmethods
	
	methodsList[:] = filter(lambda y: y['inout'] == "ent" , methodsList)
	return methodsList


					

#adb shell dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp'

def processtraces(fileName):
	methods, m_dict = loadprocesstraces(fileName)
	print("building call info")
	methodList = buildCallInfo(methods,m_dict)
	print("dumping to json file")
	#print(methods)
	with open("out.json", "w") as outfile:
		json.dump( methodList , outfile)


if __name__ == "__main__":
	fileName="o.out"
	app_package=None
	if len(sys.argv)>2:
		print(sys.argv)
		fileName=sys.argv[1]
		app_package=sys.argv[2]
		print("package: "+ app_package)
	elif len(sys.argv)==2:
		fileName=sys.argv[1]
	else:
		print("using default trace file " + fileName)
	processtraces(fileName)
	

