# !/bin/bash


# script to execute lint over every project processed 

#copy jar to that location if not exists
test ! -f ~/.android/lint/greenlab.org.ebugslocator-1.0.jar && mkdir -p ~/.android/lint && cp $ANADROID_PATH/resources/jars/greenlab.org.ebugslocator-1.0.jar ~/.android/lint/greenlab.org.ebugslocator-1.0.jar

mkdir lints

curr_dir=$(pwd)

for f in $(cat $ANADROID_PATH/.ana/logs/processedApps.log ); do 
	cd "$f"
	app_simp_name=$(basename $f)
	mkdir -p "$curr_dir/lints/$app_simp_name"
	if [[ -f "$f/gradlew" ]]; then
		#statements
		./gradlew lint > "$curr_dir/lints/$app_simp_name" 2>&1
	else
		gradle lint
	fi

	cd "curr_dir"
done	 