from os import sys








def check(value, range_min, range_max):
    if range_min <= value <= range_max:
        return True
    return False


def getMatchGradleVersion(value):
	# https://developer.android.com/studio/releases/gradle-plugin
	val_without_dots= value.replace(".","")
	if len(val_without_dots)<0:
		print ("unknown")
	elif val_without_dots[0]=='0':
		# if version is something like 0.1.3
		print ("2.1")
		return
	elif value=="+":
		# if version is something like 0.1.3
		print("5.1.1")
		return
	val = int(val_without_dots)
	if check(val, 100, 113 ):
		print("2.3")

	elif check(val, 120, 131 ):
		print("2.9")		
	
	elif val==150:
		print("2.13")

	elif check(val, 200, 212 ):
		print("2.1")

	elif check(val, 213, 223 ):
		print("2.14.1+")
	
	elif check(val, 230, 299 ):
		print("3.3+")

	elif check(val, 300, 309 ):
		print("4.1+")

	elif check(val, 310, 319 ):
		print("4.4+")

	elif check(val, 320, 321 ):
		print("4.6+")

	elif check(val, 330, 332 ):
		print("4.10.1+")

	elif val >=340 :
		print("5.1.1+")

	elif val <=100:
		print("2.1") # ????

	else:
		return "3.3"

if __name__== "__main__":
	if len(sys.argv) >1:
		if sys.argv[1]=="getMatchGradleVersion":
			getMatchGradleVersion(sys.argv[2])
	else:
		print ("at least 1 args required ( <package-name>  )")
