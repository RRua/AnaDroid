
import sys, json
import os,fnmatch
from pprint import pprint
from subprocess import call, check_output, Popen, PIPE

min_versions=3

def createDir(dirname, content):
    try:
        if not os.path.isdir(dirname):
            os.mkdir(dirname)
        with open(dirname+"/data.json", 'w') as outfile:
            json.dump(content, outfile)
        print("ja taaa")
    except Exception as e:
        print ("Creation of the directory %s failed" % dirname)

def downloadSauce(obje,url):
    #dirname = "./fdroidApps/" + str(url).replace("https://f-droid.org/repo/","") 
    dirname = ("./fdroidApps/"+obje['pack_name'] ).replace(" ","")
    createDir(dirname,obje)
    cmd =' curl ' + url + ' --output ' + dirname+"/"+ url.replace("https://f-droid.org/repo/","") 
    #.replace(".tar.gz","")
    pipes = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
    std_out, std_err = pipes.communicate()
    pipes.wait()
    if pipes.returncode != 0:
        # an error happened!
        err_msg = "{}. Code: {}".format(std_err.decode("UTF-8"), pipes.returncode)
        print(err_msg)
    else:
        print("ok")

def app_filter(file):
	with open(file, 'r') as json_file:
		data = json.load(json_file)
	ct = len(data)
	print("total apps %d" % ct)
	count=0
	for x in data:
		#print("x->"+str(x))
		ct=ct-1
		if x["versions"] is not None and len(x["versions"])>=min_versions:
		    for version in x["versions"]:
		        print("lo url "+ str(version['url']))
		        print("Downloading apk " + str(ct))
		        downloadSauce(x,version['url'])
		    count=count+1
	print("apps with %d versions: %d" %(min_versions,count))


if __name__ == "__main__":
	if sys.argv>1:
		print(sys.argv)
		file=sys.argv[1]
		app_filter(file)
	else:
		print("specify json file")