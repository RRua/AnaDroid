import sys
import json
import os,fnmatch
from pprint import pprint
from subprocess import call, check_output, Popen, PIPE



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



def getSauce(url):
    cmd ='scrapy runspider sourceCodeCrawler.py -a url=\"' +url  + '\" -s LOG_ENABLED=False'
    #process = Popen(cmd,shell=True, stdout=PIPE)
    pipes = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
    std_out, std_err = pipes.communicate()
    pipes.wait()
    if pipes.returncode != 0:
        # an error happened!
        err_msg = "{}. Code: {}".format(std_err.decode("UTF-8"), pipes.returncode)
        print(err_msg)
    else:
        print("ok")
        #print("cajo" + std_out.strip().encode("UTF-8",'ignore'))
        print(std_out.strip())
        jo = json.loads(std_out.strip().replace("\'","\"").encode("UTF-8",'ignore'))
        return jo

# coloca em pages.json todas as apps contidas no repo, indo pagina a pagina
def getAppPageFromListPage(url):
    cmd ='scrapy runspider appListCrawler.py -a url=\"' +url  + '\" -s LOG_ENABLED=False'
    #process = Popen(cmd,shell=True, stdout=PIPE)
    pipes = Popen(cmd, shell=True, stdout=PIPE)
    std_out, std_err = pipes.communicate()
    pipes.wait()
    if pipes.returncode != 0:
        # an error happened!
        err_msg = "{}. Code: {}".format(std_err.decode("UTF-8"), pipes.returncode)
        print(err_msg)
    else:
        print("ok")
        page_obj=json.loads(std_out.strip().replace("\'","\""))
        return page_obj
        #print("ai que obj " + str(obj) )


def main(args):
    if len(args)>0:
        task=args[0]
        top_url = "https://f-droid.org/pt_BR/packages/"
        numpages = 3 #  TODO 
        start_index = 2
        all_pages = []

        if task == "crawlPackages":
            print("crawling all apps")
             #getSauce(one_app_url)
            for x in range(start_index,numpages):
                new_list_url = ( "https://f-droid.org/pt_BR/packages/%i/index.html" % x)
                new_page = getAppPageFromListPage(new_list_url)
                all_pages.append(new_page)
                print("page %i processed..." %x )

            all_sauce = []
            for x in all_pages:
                print(x)
                for url in x:
                    real_url = "https://f-droid.org" + url
                    try:
                        jo_app = getSauce(real_url)
                        all_sauce.append(jo_app)
                        print("processed " + real_url)
                    except Exception as e:
                        print(e.message)
                        print("ignored " + real_url)
                   
            with open("all_sources.json", 'w') as outfile:
                json.dump(all_sauce, outfile)

        #elif task == "crawlEachApp":
            data=all_sauce
            ct = len(data)
            for x in data:
                print("x->"+str(x))
                ct=ct-1
                if x["versions"] is not None and len(x["versions"])>1:
                    for versao in x["versions"]:
                        url = versao['url']
                        print("Downloading apk " + str(ct))
                        downloadSauce(x,url)
                else:
                    print("Less than 2 version. Ignoring...")
                

        elif task == "crawlEachApp":

            with open("all_sources.json", 'r') as json_file:
                data = json.load(json_file)
            #data=all_sauce
            ct = len(data)
            for x in data:
                print("x->"+str(x))
                ct=ct-1
                if x["versions"] is not None and len(x["versions"])>1:
                    for url in x["versions"]:
                        print("Downloading apk " + str(ct))
                        downloadSauce(x,url)
                else:
                    print("Less than 1 version. Ignoring...")
        else:
            print("Bad arg")
        #one_app_url = "https://f-droid.org/pt_BR/packages/com.uberspot.a2048/"   

    else:
        print("Bad argument len")

    


if __name__ == "__main__":
   main(sys.argv[1:])
