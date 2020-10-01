# plobf
A bash shrinker/obfuscator written in bash!

Just a warning, this is very under-tested, so always keep a copy of the original code!

## Currently supports: 
- Encoding modules
	-So far only 1: an atomic module mainly used to test the script
- Minifying/Shrinking bash code by reducing spaces and new lines.
  - NOTE: This minifier is by no means perfect and makes a few assumptions about how bash scripts are formatted, namely:
	1. There will be no strangely crafted expressions, particularily involving strings/literals.
		- It would be good to avoid multi-line strings and strings that hold bash code or bash keywords.
	2. The script provided is largely un-minified (although there is a check for 100% minified input).

## Usage

    usage: plobf.sh [options] [-f file] OR [command_string]
      -o, --output 	Output file
      -m, --module 	Select an obfuscation module
        1: Atoms
      -s, --shrink	Shrink/Minify code (happens before encoding) |SLOW|
          --quiet 	Quiet (debug)
          --prep  	Only run the prep module (debug)
      -h, --help  	Show this message
 
