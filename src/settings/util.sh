#!/bin/bash

function matching_brackets {
	filepath=$1
	line=$2
	if [[ (-z "$filepath") || (-z "$line" ) ]]; then
		return -1
	else
		content=$(sed "${line}q;d" $filepath)
		br_open=$(echo $content | grep -o "{" | wc -l)
		br_close=$(echo $content | grep -o "}" | wc -l)
		let "count=$br_open - $br_close"
		while [[ (("$count" > "0")) ]]; do
			((line++))
			content=$(sed "${line}q;d" $filepath)
			br_open=$(echo $content | grep -o "{" | wc -l)
			br_close=$(echo $content | grep -o "}" | wc -l)
			let "count = count - $br_close + $br_open"
		done
		return $line
	fi
}
