#!/bin/bash
# This is a payload obfuscator for Bash

usage=\
'usage: plobf.sh [options] [-f file] OR [command_string]
	-o, --output 	Output file
	-m, --module 	Select an obfuscation module
		1: Atoms
	-s, --shrink	Shrink/Minify code (happens before encoding) |SLOW|
	    --quiet 	Quiet (debug)
	    --prep  	Only run the prep module (debug)
	-h, --help  	Show this message
'

PL1_NUM_MOD=1

# These store the payload in between steps
PL1_RET=""
PL1_FINAL=""

# newline char
nl='
';

calc(){ awk "BEGIN { print "$*" }"; }

readfile() { echo -n "$(cat "$1")"; }

join_by() { local IFS="$1"; shift; echo "$*"; }

# Thanks, SE!
posix_replace() {
	f="$1"
	s=$3
	t=$2
	[ "${f%$t*}" != "$f" ] && f="${f%$t*}$s${f#*$t}"
	echo "$f"
}

# Check for a cf and return the cf keyword
check_for_cf() {
	local l="$1"
	local len=${#l}
	local curr=""
	local ret="nope"
	for((k=0; k<len; k++)); do
		curr="${curr}${l:$k:1}"
		if [ ! -z ${kwp["$curr"]} ]; then
			ret="$curr"
			break
		fi
	done
	echo "$ret"
}

 # prog status
PLPROG_TMPFILE=".pltmp"
plprog() {
	PLPROG_MSG="$1"
	PLPROG_TOTAL=$2
	echo "0" > $PLPROG_TMPFILE
	while true; do
		t="$(cat ${PLPROG_TMPFILE})"
		if [[ "$t" == "done" ]]; then break; fi
		if [ -z $t ] || [ "$t" == "" ]; then continue; fi
		p="$(calc "100*(${t}/${PLPROG_TOTAL})")"
		p="${p%%.*}" # remove decimal point
		printf "\r%s...%s%%" "$PLPROG_MSG" "$p"
		#printf "\r%s / %s" "$t" "$PLPROG_TOTAL"
		sleep .1
	done
	printf "\r%s...%s%%\n" "$PLPROG_MSG" "100"	
}
updateprog() {
	echo "$1" > $PLPROG_TMPFILE
	if [ "$1" == "done" ]; then
		sleep .5 # give prog time to finish
		rm $PLPROG_TMPFILE
	fi
}

# Global vars
declare -A delims # delimiters
delims["{"]=1; delims["["]=1; delims["[["]=1; delims["("]=1; delims["(("]=1
delims["}"]=-1; delims["]"]=-1; delims["]]"]=-1;delims["))"]=-1; delims[")"]=-1
declare -A kwp # cf-specific keywords and their delimiters
kwp["for"]="do"; kwp["while"]="do"; kwp["if"]="then"; kwp["elif"]="then"

# This is a more broad keword array for use in certain parts of the minifier
# It excludes final delimiters like "fi" and "done" because we need those to be followed by a ;
declare -A kw
kw["for"]=1; kw["while"]=1; kw["if"]=1; kw["elif"]=1; kw["else"]=1;

declare -A strtable # data arrays
declare -A vartable
declare -A funtable

# This is the prep module for the bash payload.
# We read the script into an array line-by-line while removing comments/indenting and collecting strings and names.
pl1_prep() {
	local cmdarr=( ) 	# line array for the script
	local currs="" 		# current string
	local nstrs=0 		# number of strings
	local ins=0; 		# in string flag
	local c="" 			# current line
	
	plprog "Doing code prep" ${#1} &
	k=0
	
	while read -r line; do
		local tmp="" # temp variable for holding partial lines
		local len=${#line}
		local inc=0; # in comment flag
		local inbrace=0; # brace level
		for((i=0; i<len; i++)); do
			c="${line:$i:1}"
			if [ ! -z ${delims["$c"]} ]; then inbrace=$(($inbrace + ${delims["$c"]})); fi
			if [ $ins -gt 0 ]; then currs="${currs}$c"; fi
			if [ "$c" == "#" ] && [ $ins -eq 0 ] && [ $inbrace -eq 0 ]; then
				break
			elif ( [ "$c" == "'" ] && [ ! $ins -eq 1 ] ) || ( [ "$c" == "\"" ] && [ ! "${line:$i-1:1}" == "\\" ] ); then # do we have a (non-escaped) string?
				if [ $ins -eq 0 ]; then 
					if [ "$c" == "'" ]; then
						ins=2;
					else
						ins=1;
					fi
					currs="$c"
				else
					ins=0;
					strtable["str_${nstrs}"]="$currs$c"
					currs=""
					((nstrs++))
				fi
			fi
			tmp="${tmp}$c"
			((k++))
		done
		# strip trailing and leading whitespace space
		tmp="${tmp#"${tmp%%[![:space:]]*}"}"
		tmp="${tmp%"${tmp##*[![:space:]]}"}"
		if [ ! "$tmp" == "" ]; then cmdarr+=( "$tmp" ); fi
		
		updateprog "$k"
	
	done <<< $1
	
	updateprog "done"
	PL1_RET=( "${cmdarr[@]}" )
}

# Adapted from code written by 0xddaa
pl1_atoms() {
	# octal -> param expansion strings
	local n=( )
	n[0]="\$#"
	n[1]="\${##}"
	n[2]="\$((${n[1]}<<${n[1]}))"
	n[3]="\$((${n[2]}#${n[1]}${n[1]}))"
	n[4]="\$((${n[1]}<<${n[2]}))"
	n[5]="\$((${n[2]}#${n[1]}${n[0]}${n[1]}))"
	n[6]="\$((${n[2]}#${n[1]}${n[1]}${n[0]}))"
	n[7]="\$((${n[2]}#${n[1]}${n[1]}${n[1]}))"
	
	local ostrs=( )
	local args=('bash' '-c' "$1")
	
	plprog "Applying Atoms..." $((${#1} + 6)) &
	k=0
	
	for str in "${args[@]}"; do
		s="\$\\'" 	# $\'
    	for ((i=0; i<${#str}; i++)); do
        	char="${str:$i:1}"
        	oct=$(printf "%03o" \'"${char}")
        	e="\\\\"
        	for ((j=0; j<${#oct}; j++)); do
            	e+="${n[${oct:$j:1}]}"
        	done
        	s+="${e}"
			
			((k++))
			updateprog "$k"
		done
    	s+="\\'"
    	ostrs+=( "${s}" )
	done
	
	updateprog "done"
	
	# Print out the joined (and {} enclosed) octal array
	PL1_RET="bash<<<{$(join_by , "${ostrs[@]}")}";
}

# Minify/Shrink module
pl1_shrink() {
	local c=""; local ret="";
	local cmdarr=( "${PL1_RET[@]}" )
	local len=${#cmdarr[@]}
	if [ $len -eq 1 ]; then echo "This program is minified already!"; exit 0; fi
	
	local setnow=0; # flags
	local incf=0; local kwrd=""; local dl=""; local cftmp=""; # in control-flow 
	local infnc=0; # in function
	local incase=0;
	local fw_search_limit=10; # unused
	local la=""; # this is our lookahead line (currently unused)
	local ft=""; local lp="";

	plprog "Running PL1 Minifier" $len &

	for((i=0; i<len; i++)); do
		setnow=0
		c="${cmdarr[$i]}"
		#la="${cmdarr[$i+1]}" 
		ft=${c%%" "*}; lp=${c#*" "}; # first token, last part
		
		updateprog "$i"
		
		# first, is this a cf that we recognize? that is, one with the format: [keyword] [expression]; [delimiter]
		cf="$(check_for_cf "$c")"
		if [ ! "$cf" == "nope" ]; then
			kwrd="$cf"
			dl="${kwp["$cf"]}"
			cftmp="$c"
			incf=1; setnow=1
			continue
		fi
		# are we in a cf that we recognize?
		if [ $incf -eq 1 ]; then
			if [[ "$c" == *"$dl"* ]]; then
				if [[ ! "$c" == *";"*(" ")"$dl" ]]; then # no ; aready present before delimiter
					c="$( posix_replace "$c" "$dl" "; $dl" )"
				fi
				# check if this is the same line that triggered the incf flag
				if [ $setnow -eq 1 ]; then
					ret="${ret}${c}"
				else
					ret="${ret} ${cftmp}${c}"
				fi
				incf=0; kwrd=""; dl=""; cftmp=""; # reset cf stuff
				continue
			elif [ $setnow -eq 0 ]; then # if we find no delimiter, then add to the cftmp chunk and move on
				cftmp="${cftmp}$c"
			fi
		fi
		
		# is this a case statement?
		# Single-line case statement: a="hello"; case "$a" in hello) echo "help";; *) echo "anything";; esac
		if [ "$ft" == "case" ]; then
			incase=1; setnow=1;
		fi
		# are we in a case statement?
		if [ $incase -eq 1 ]; then
			ret="${ret} $c"
			if [[ "$c" == *"esac"* ]]; then
				incase=0
			fi
			continue
		fi
		
		# is there a function keyword or ()? then we are dealing with a function.
		if [ $infnc -eq 0 ]; then
			if [[ "$c" == "function"* ]] || [[ "$c" == *"()" ]]; then
				infnc=1; setnow=1
			fi
		fi
		
		# check for a command: if the first token of the line is a command, then we check for the next command or keyword and join with a ;
		# we use the kw array since the command -v test will return false positives on cf statements, which we aren't looking for
		if  [ -z ${kw["$ft"]} ] && [ $(command -v "$ft" ) ] && [ ! "${c: -1}" == ";" ]; then
			ret="${ret} ${c};"
			continue
		fi
		
		# check for some kind of expression/assignment
		if [[ "$c" == **("="|"+"|"-"|"*"|"/")"="* ]] && [ ! "${c: -1}" == ";" ]; then
			ret="${ret} ${c};"
			continue
		fi
		
		# if this is an emty line (and this isn't part of a string...), then ignore it.
		if [ "$c" == "" ]; then continue; fi
		
		# if nothing we checked is true, then we just hope for the best
		ret="${ret} $c"
	done
	
	updateprog "done"
	
	if [ "${ret:0:1}" == " " ]; then
		PL1_RET="${ret:1}" # remove leading space
	else
		PL1_RET="$ret"
	fi
}

main() {
	if [ -z $PL1_HAS_ACTION ]; then
		echo "No action specified!" >&2
		exit -1
	fi
	echo "Running plobf..."
	pl1_prep "$1" # returns array of code lines
	prepString="" # string for modules that take a string
	local len=${#PL1_RET[@]}
	for((i=0; i<len; i++)); do
		prepString="${prepString}${nl}${PL1_RET[$i]}"
	done
	
	if [ "$PL1_DEBUG_PREPONLY" == "true" ]; then
		PL1_FINAL="$prepString"
		return
	fi
	
	if [ ! -z $PL1_SHRINK ]; then
		pl1_shrink
	else
		PL1_RET="$prepString"
	fi
	
	if [ ! -z $PL1_MODULE ]; then
		case "$PL1_MODULE" in
		1)
			pl1_atoms "$PL1_RET"
		;;
		*)
			echo "Oops in pl1 module select" >&2
			exit -1
		;;
		esac
	fi
	PL1_FINAL="$PL1_RET"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -f)
    	shift
    	file="$1"
    	if [ -z "$file" ]; then
    		echo "-f option requires a file!" >&2
    		exit 1
    	fi
    	CMD="$(readfile "$file")"
    	shift
    ;;
    -o|--output)
    	shift
    	FOUT="$1"
    	if [ -z "$FOUT" ]; then
    		echo "-o needs an output file!" >&2
    		exit 1
    	fi
    	shift
    ;;
	-m|--module)
		shift
		PL1_MODULE=$1
		if [ -z "$PL1_MODULE" ]; then
			echo "Needs a module number" >&2
			exit -1
		elif [ $PL1_MODULE -gt $PL1_NUM_MOD ] || [ $PL1_MODULE -lt 1 ]; then
			echo "Invalid module number!" >&2
			exit -1
		else
			PL1_HAS_ACTION="true"
		fi
		shift
	;;
	-s|--shrink)
		PL1_SHRINK=1
		PL1_HAS_ACTION="true"
		shift
	;;
	--quiet)
		PL1_DEBUG_QUIET="true"
		shift
	;;
	--prep)
		PL1_DEBUG_PREPONLY="true"
		PL1_HAS_ACTION=1
		shift
    ;;
    -h|--help)
    	echo "$usage"
    	exit
    ;;
    -*) echo "Unknown option: $1" >&2
    	exit 1
    ;;
    *)
    	if [ -z "$file" ]; then
    		CMD="$*"
    	else
    		echo "You cannot specify -f and a command"
    		echo "$usage"
    		exit
    	fi
    	break
    ;;
    esac
done

if [ -z "$CMD" ]; then
	echo "No command/options given!"
	echo "$usage"
else
	main "${CMD}"
	
	if [ -z "$PL1_FINAL" ]; then
		printf "\nSomething went wrong!\n" >&2
		exit 1
	fi
	
	printf "\n"
	
	if [ "$PL1_DEBUG_QUIET" == "true" ]; then exit 0; fi
	if [ -z "$FOUT" ]; then
		echo "$PL1_FINAL"
	else
		echo "Writing to ${FOUT}..."
		echo "$PL1_FINAL" > $FOUT
		chmod +x "$FOUT"
	fi
	
	printf "\nall done!\n"
fi
