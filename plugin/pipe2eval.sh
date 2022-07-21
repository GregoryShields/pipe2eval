#!/bin/bash

# TODO: Each buffer should have its own context.

INPUT_LANG=$1
INPUT_FILE="$2"
echo " " >> log.txt
#echo "INPUT_FILE: $INPUT_FILE" >> log.txt

# If not exported from .bashrc, use default path.
if [ -z "$PIPE2EVAL_TMP_FILE_PATH" ]; then
	PIPE2EVAL_TMP_FILE_PATH=/dev/shm/
fi

PREFIX="repl"
TMP_FILE=$PIPE2EVAL_TMP_FILE_PATH$PREFIX.$INPUT_LANG

echo "--------------------------------------------------" >> log.txt
#$(sed '' < "$TMP_FILE.new") >> log.txt
echo "TMP_FILE: $TMP_FILE" >> log.txt
echo "is made of these 3 combined..." >> log.txt
echo "PIPE2EVAL_TMP_FILE_PATH: $PIPE2EVAL_TMP_FILE_PATH" >> log.txt
echo "PREFIX:                           $PREFIX." >> log.txt
echo "INPUT_LANG:                            $INPUT_LANG" >> log.txt
echo "-------------------------" >> log.txt

fn_exists() {
	declare -F $1 &> /dev/null
	return $?
}

fn_call() {
	echo "fn_call $1 body" >> log.txt

	if fn_exists $INPUT_LANG\_$1; then
		$INPUT_LANG\_$1 ${@:2}
	else
		default_$1 ${@:2}
	fi
}

process_commands() {
	echo "process_commands body" >> log.txt

	cmd="$( sed -n '1 s/^[#\/;-]\{1,2\}> \([a-zA-Z0-9_-]\+\) \?\(.*\)\?$/\1/p' < $TMP_FILE.new)"
	args="$(sed -n '1 s/^[#\/;-]\{1,2\}> \([^ ]\+\) \(.*\)$/\2/p' < $TMP_FILE.new)"

	echo "\$cmd=$cmd" >> log.txt
	echo "\$args=$args" >> log.txt

	if [ -n "$cmd" ]; then
		echo "fn_call command_$cmd '$args'"
		fn_call command_$cmd "$args"
		exit 0
	fi
}

hr() {
	echo "hr body" >> log.txt

	echo -n "$1"
	pad=$(printf '%0.1s' "-"{1..80})
	padlen=$((80 - ${#1} - ${#2}))
	printf '%0.*s' $padlen $pad
	echo "$2"
}

# commands ---------------------------------------------------------------------

default_command_files() {
	echo "default_command_files body" >> log.txt

	find $PIPE2EVAL_TMP_FILE_PATH -maxdepth 1 -name "$PREFIX.$INPUT_LANG*"
}

default_command_reset() {
	echo "default_command_reset body" >> log.txt

	find $PIPE2EVAL_TMP_FILE_PATH -maxdepth 1 -name "$PREFIX.$INPUT_LANG*" -exec rm -f {} \;
}

default_command_set() {
	echo "default_command_set body" >> log.txt

	if [ -n "$1" ]; then
		echo $2 > $TMP_FILE.$1
	fi
}


# default ----------------------------------------------------------------------

default_comment() {
	echo "default_comment body" >> log.txt

	# do nothing
	:
}

default_init() {
	echo "default_init body" >> log.txt

	fn_call reset > /dev/null
}

default_reset() {
	echo "default_reset body" >> log.txt

	> $TMP_FILE
	> $TMP_FILE.error
	echo '# context cleared'
}

default_error() {
	echo "# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
	sed -e 's/^\(.*\)$/#     \1/' < "$TMP_FILE.error"
	echo "# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
}

default_merge() {
	echo "default_merge body" >> log.txt

	# do nothing
	:
}

default_eval() {
	echo "default_eval body" >> log.txt

	echo $TMP_FILE "$TMP_FILE.new" >> log.txt

	# This appears to retrieve the contents of these two files...
	# TMP_FILE
	# TMP_FILE.new
	# ...concatenated together, and then redirects any errors
	# errors to the file...
	# TMP_FILE.error
	# ...and then finally takes the result and executes it,
	# outputting the result prefixed with a hash to make it a comment.
	# I do not understand what the $INPUT_LANG followed by a hyphen means.
	cat $TMP_FILE "$TMP_FILE.new" | \
		$INPUT_LANG - 2> "$TMP_FILE.error" | \
		sed -e 's/^\(.*\)$/# \1/'
}

# main -------------------------------------------------------------------------

main() {
	echo "main body" >> log.txt
	echo "Before we tee it, TMP_FILE.new still has its old value:" >> log.txt
	$(sed '' < "$TMP_FILE.new") >> log.txt
	tee $TMP_FILE.new
	echo "After we tee it, TMP_FILE.new has the new value:" >> log.txt
	$(sed '' < "$TMP_FILE.new") >> log.txt

# 	echo "Frankly, I don't understand why we care about $TMP_FILE right here." >> log.txt
# 	# This block of logging code helps make sense of the block of code below it.
# 	if [ ! -f "$TMP_FILE" ]; then
# 		echo "$TMP_FILE either DOES NOT exist or IS NOT a regular file, so call: fn_call 'init'." >> log.txt
# 	else
# 		echo "$TMP_FILE exists and is a regular file, so DO NOT call: fn_call 'init'." >> log.txt
# 	fi
# 

 	if [ ! -f "$TMP_FILE" ]; then
 		echo "fn_call 'init'" >> log.txt
 		fn_call 'init'
 	fi

	if [ -z "$(sed '/^$/d' < "$TMP_FILE.new")" ]; then
		fn_call 'reset'
		echo "fn_call 'reset'" >> log.txt
		exit 0
	fi

	echo "-------------------------" >> log.txt
	process_commands

	echo "-------------------------" >> log.txt
	echo "fn_call 'eval'" >> log.txt
	# See NOTE 1
	fn_call 'eval'

	if [ -s "$TMP_FILE.error" ]; then
		fn_call 'error'
	else
		fn_call 'merge'
	fi
}

main


# NOTE 1:
# Let's say INPUT_LANG is "sh".
# If we have defined a function named "sh_eval" (which we haven't), call it.
# (There is, however, a "bash_eval" function, but my &filetype is "sh", not "bash".)
# Otherwise, call our default function "default_eval".
#
# Since in this case we didn't pass any arguments to fn_call other than the
# function name suffix 'eval', no arguments are passed in the call to default_eval.
# In fact, I can find no place in this entire script where fn_call is passed more
# than a single argument. Thus, the...
# ${@:2}
# ...argument construction inside of fn_call never even comes into play. Nevertheless,
# it is there should we ever need it in the future.




