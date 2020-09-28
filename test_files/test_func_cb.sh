#!/bin/bash

func() {
	if [[ $1 -eq 0 ]]
	then
		echo "if"
	elif [ "$1" == "1" ]; then
		echo "elif"
		for((i=0; i<1; i++))
		do
			echo "$i"
			case "$i" in
			*)
				echo "case"
			;;
			esac
		done
	else
		echo "else"
	fi
	echo "fi"
}

# this is a comment

if [ "a" == 'a' ]
then
	echo "dq = sq" # this is also a comment
else
	echo "dq != sq"
fi


