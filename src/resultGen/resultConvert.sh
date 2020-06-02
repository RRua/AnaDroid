#!/bin/bash

# script para converter resultados do anadroid no formato antigo para o atual, separado por versoes de app
#copia resultados para nova pasta com o formato necessario
# so é util qdo se quer processar resultados antigos

target_dir="new_results"
version_threshold=3
test_threshold=5

change_format='''
# mudar formato das pastas
for full_dir in $(find $target_dir/ -maxdepth 1  ! -path  $target_dir/  -type d ); do
	#echo $full_dir
	my_dir=$(echo $full_dir | sed 's#new_results/##g' | sed 's/_src.tar.gz//g' | cut -f2 -d/ )
	#echo "my dir $my_dir"
	vers_id=$(echo $my_dir | cut -f2 -d_ )
	app_pack=$(echo $my_dir | cut -f1 -d_ )
	new_dir="modified_results/$app_pack/$vers_id"
	#echo "--  $new_dir"
	mkdir -p "$new_dir"
	#echo "cp -r \"$full_dir/\" \"$new_dir/\""
	cp -r "$full_dir/" "$new_dir/"
done
'''
# remover as que têm menos de 3 v

xx='''for f in $(find modified_results/ -maxdepth 1  ! -path modified_results/ ); do 
	#echo "efe - $f"
	version_count=$(find $f -maxdepth 1 ! -path $f -type d  | wc -l)
	#echo "$f tem $version_count versoes"
	if [[ $version_count -lt $version_threshold ]]; then
		echo "tem poucas"
		rm -rf "$f"
	fi
done'''

#remover as que têm menos de x testes
x='''for app_folder in $(find modified_results/ -maxdepth 1  ! -path modified_results/ ); do 
	#for version_folder in $(find $app_folder -maxdepth 1  ! -path $app_folder ); do
	for version_folder in $(find "$app_folder" -maxdepth 1 ! -path "$app_folder" -type d ); do
		#statements
		#echo "efe -$version_folder-"
		test_count=$(find $version_folder -maxdepth 2 -type f -name "GreendroidResultTrace*"  | wc -l)
		#echo "$f tem $version_count versoes"
		echo "tem $test_count"
		if [[ $test_count -lt $test_threshold ]]; then
			#echo "$version_folder" >> to_remove.out
			rm -rf "$version_folder"
			#rm -rf "$app_folder"
			
		fi
	done
done
'''

# to generate resuls again with analyzer
for app_folder in $(find modified_results/ -maxdepth 1  ! -path modified_results/ ); do 
	#for version_folder in $(find $app_folder -maxdepth 1  ! -path $app_folder ); do
	for version_folder in $(find "$app_folder" -maxdepth 1 ! -path "$app_folder" -type d ); do
		#statements
		#echo "efe -$version_folder-"
		java -jar "./resources/jars/AnaDroidAnalyzer.jar" "-TestOriented" "$version_folder" "-monkey" "NONE"
		echo "mais um"
	done
done




