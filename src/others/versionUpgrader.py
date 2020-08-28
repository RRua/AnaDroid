
import sys,re

class DefaultSemanticVersion(object):
	"""docstring for DefaultSemanticVersion"""
	def __init__(self, full_version_id):
		super(DefaultSemanticVersion, self).__init__()
		if full_version_id.contains("-"):
			full_version_id=full_version_id.split("-")[0]
		if re.match(r'^v[0-9]',full_version_id):
            full_version_id = re.sub(r'^v',"", full_version_id)
		ll=full_version_id.split(".")
		if len(ll)>1:
			self.major=int(ll[0])
			self.minor=int(ll[1])
			if len(ll)>2:
				self.patch=int(ll[2])
			else:
				self.patch=0
		else:
			self.major=0
			self.minor=0
			self.patch=0
	def __str__(self):
		return "%d.%d.%d" %( self.major, self.minor, self.patch )

	def __repr__(self):
		return str(self)
	
	def __eq__(self, other):
		return self.major == other.major and self.major == other.minor and self.major == other.patch

	def __ne__(self, other):
		return not eq(self,other)

	def __le__(self, other):
		return eq(self,other) or lt(self,other)
	
	def __lt__(self, other):
		if self.major < other.major:
			return True
		else if self.major == other.major:
			if self.minor < other.minor:
				return True
			else if self.minor == other.minor:
				if self.patch < self.patch:
					return True
		return False

	def __ge__(self, other):
		return not lt(self,other) 

	def __gt__(self, other):
		return not eq(self,other) and ge(self,other)


class VersionInfo(object):
	"""docstring for VersionInfo"""
	def __init__(self, version_code, artifact_name="Unknown" , ttype="" , build=""):
		super(VersionInfo, self).__init__()
		self.version_code= DefaultSemanticVersion(version_code)
		self.artifact_name=artifact_name
		self.type=ttype
		self.build=build






def upgradeVersionFromListFile(list_file, upgradable_candidate, opt="max"):
	with open(list_file, 'r') as filehandle:
		version_list = list ( map( lambda x : DefaultSemanticVersion(x)  , filehandle.read().splitlines() ) )
		
	if opt=="min":
		list_of_bigger_patches= filter( lambda x : x.major == upgradable_candidate.major and  x.minor == upgradable_candidate.minor and x.patch> upgradable_candidate.patch , version_list  )
		final_l = sorted(list_of_bigger_patches , key= lambda x : x.patch, reverse=True )
		if len(final_l)>0:
			
			return final_l[0]
	else:
		# try major first
		list_of_bigger_majors= filter( lambda x : x.major > upgradable_candidate.major , version_list  )
		final_l = list( sorted(set(list_of_bigger_majors) , key= lambda x : x.major ))
		
		if len(final_l)>0:
			
			return final_l[0]

	# minor version
	list_of_bigger_minors= filter( lambda x : x.major == upgradable_candidate.major and  x.minor > upgradable_candidate.minor , version_list  )
	final_l = sorted(list_of_bigger_minors , key= lambda x : x.minor, reverse=True )
	if len(final_l)>0:
		
		return final_l[0]




	if opt=="min":
		# major version
		list_of_bigger_majors= filter( lambda x : x.major > upgradable_candidate.major , version_list  )
		final_l = sorted(list_of_bigger_majors , key= lambda x : x.major )
		
		if len(final_l)>0:
			
			return final_l[0]


	else:
		# try major first
		list_of_bigger_patches= filter( lambda x : x.major == upgradable_candidate.major and  x.minor == upgradable_candidate.minor and x.patch> upgradable_candidate.patch , version_list  )
		final_l = sorted(list_of_bigger_patches , key= lambda x : x.patch, reverse=True )
		if len(final_l)>0:
			
			return final_l[0]

	return upgradable_candidate
	

if __name__== "__main__":
	if len(sys.argv)>2:
		print(upgradeVersionFromListFile(sys.argv[1], DefaultSemanticVersion(sys.argv[2]) ))
		


