#!/bin/bash

word="hello"
sent="hello, world!"
newsent='hello, world!'
tricky="\"hello,word\"";
tricky2="\"hello, 'world!\""
echo ${param:-$word}

declare someVar
declare -X someOtherVar

#this is a comment

