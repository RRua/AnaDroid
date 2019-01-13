#!/usr/bin/python

import xml.sax, sys

class ManifestHandler( xml.sax.ContentHandler ):
   def __init__(self, path):
      self.path = path
      self.CurrentData = ""
      self.target = ""
      self.package = ""
      self.launcher = False

   # Call when an element starts
   def startElement(self, tag, attributes):
      self.CurrentData = tag
      if tag == "instrumentation":
         if "android:targetPackage" in attributes:
            self.target = attributes["android:targetPackage"]
      elif tag == "manifest":
         if "package" in attributes:
            self.package = attributes["package"]
      elif tag == "category":
         if attributes["android:name"]:
            if attributes["android:name"] == "android.intent.category.LAUNCHER":
               self.launcher = True

def getLauncher(handlers):
   if len(handlers) > 0:
      for h in handlers:
         if h.launcher:
            return h.path, h.package
   else:
      return "", ""
  
def main(argv):
   lst = []
   lst_cpy = []
   for arg in argv:
      path = arg.replace("/AndroidManifest.xml", "")
      # create an XMLReader
      parser = xml.sax.make_parser()
      # turn off namepsaces
      #parser.setFeature(xml.sax.handler.feature_namespaces, 0)

      # override the default ContextHandler
      handler = ManifestHandler(path)
      parser.setContentHandler( handler )
      
      parser.parse(arg)

      lst.append(handler)
      lst_cpy = lst
      #print(handler.package)

   p, source, tests, package, testPack="","","","",""
   res=[]
   #count=0
   for h in lst:
      if h.target != "":
         #test project found!!
         tests=h.path
         p=h.target
         #count+=1
         if p != "":
            for x in lst:
               isSubstring = (x.package in p) and (x.package != "")   # and (x.target == "")
               if isSubstring:
                  #found a match!
                  testPack=h.package
                  source=x.path
                  package=x.package
                  res.append(source + ":" + tests + ":" + package + ":" + testPack)
                  #break
         #lst.remove(h)

   
   if len(res) == 0:
      source, package = getLauncher(lst_cpy)
      tests, testPack = "-", "-"
      res.append(source + ":" + tests + ":" + package + ":" + testPack)

   for a in res:
      print(a)

if __name__ == "__main__":
   main(sys.argv[1:])
