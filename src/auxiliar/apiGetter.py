import sys
import json
from pprint import pprint


def main(argv):
    list={}
    with open(argv[0]) as f:
        for line in f:
            methods=line[line.find("{")+1:line.find("}")]
            classofmethod=line[:line.find("{")]
            eachmethod=methods.split(",")
            for met in eachmethod:
                fmd= classofmethod + "." + met.replace(" ", "").replace("(","").replace(")","")
                list[fmd] = met
    

    #for x in list:
    with open('redAPIS.json') as f:
        data = json.load(f)
    for x in data:
        if(x["fullMethodDefinition"] in list):
            print(x["fullMethodDefinition"])

if __name__ == "__main__":
    main(sys.argv)