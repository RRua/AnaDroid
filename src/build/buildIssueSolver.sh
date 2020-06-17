




buildStatusFile=$1






googleError=$(grep "method google() for arguments" $buildStatusFile )
libsError=$(grep "No signature of method: java.util.ArrayList.call() is applicable for argument types: (java.lang.String) values: \[libs\]" $buildStatusFile)
minSDKerror=$(egrep "uses-sdk:minSdkVersion (.+) cannot be smaller than version (.+) declared in" $buildStatusFile)
buildSDKerror=$(egrep "The SDK Build Tools revision \((.+)\) is too low for project ':(.+)'. Minimum required is (.+)" $buildStatusFile)
wrapperError=$(egrep "try editing the distributionUrl" $buildStatusFile | egrep "gradle-wrapper.properties" )
anotherWrapperError=$(egrep "Wrapper properties file" $buildStatusFile  )


