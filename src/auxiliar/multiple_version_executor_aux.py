import sys
import os
import json
import shutil


def main(argv):
    if argv>1:
        data={}
        data_json_file = argv[0]
        data_json_dir= os.path.dirname(data_json_file)
        with open(data_json_file) as f:
            data = json.load(f)
        if data["versions"] is None:
            exit(-1)
        for version in data['versions']:
            target_folder_of_apk_version = data_json_dir+"/"+(str(version['id']) + "--"+str(version['date'])).replace(" ","").replace("Verso","")
            if not os.path.exists(target_folder_of_apk_version):
                os.mkdir(target_folder_of_apk_version)
            target_apk = version['url'].replace("https://f-droid.org/repo/","")
            newPath = shutil.copy(data_json_dir+"/"+target_apk,  target_folder_of_apk_version + "/" + target_apk)



if __name__ == "__main__":
    main(sys.argv[1:])