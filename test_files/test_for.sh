#!/bin/bash

for ((i=0; i<10; i++))
do
	echo "$i from expanded for-loop"
done

for ((i=0; i<10; i++)); do
	echo "$i from smaller for-loop"
done
