#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
# Internal Functions:
# ----------------------------------------------------------------------------------------------------------------------

# Prints the current time in milliseconds.
if ! [[ "$(gdate +'%s%3N' 2>/dev/null)" =~ N$ ]]; then
	__best_time() {
		gdate +'%s%3N'
	}
elif ! [[ "$(date +'%s%3N' 2>/dev/null)" =~ N$ ]]; then
	__best_time() {
		date +'%s%3N'
	}
elif command -v python &>/dev/null; then
	__best_time() {
		# This is the slowest thing in test execution overhead.
		python -c 'import time; import math; print int(math.floor(time.time() * 1000))'
	}
else
	__best_time() {
		printf "0\n"
	}
fi

# Prints a skip status.
__best_fn_skip() {
	printf "SKIP\n" 1>&3
}

# Prints a failure status.
__best_fn_fail() {
	printf "FAIL\n" 1>&3
}

# Prints the reason behind a failure.
#
# Arguments:
#     $1  [string]    -- The message.
#     ... [string...] -- Extra message data.
#
__best_fn_fail_reason() {
	printf "FAIL_MSG %s\n" "$1" 1>&3
	local var
	for var in "${@:2}"; do
		printf "FAIL_MSG_DATA %s\n" "$var" 1>&3
	done
}

# An internal command that executes a test.
#
# Arguments:
#     $1  [string]    -- The test function.
#
__best_run() {
	(set -e -o pipefail; "$1")
	return $?
}

# Prints text to STDERR when in terminal REPL mode.
#     $1  [string]    -- The message.
#     ... [string...] -- Extra message data.
#
__best_repl_response() { :; }

# ----------------------------------------------------------------------------------------------------------------------
# Commands:
# ----------------------------------------------------------------------------------------------------------------------

# REPL: LOAD
# Loads a file into the current process.
#
# Arguments:
#     $1  [string]    -- The file to load.
#
__best_cmd_LOAD() {
	# shellcheck disable=SC1090
	if source "$1"; then
		__best_repl_response "OK.\n"
	fi
}

# REPL: EXEC_TEST
# Execute a test function.
#
# Arguments:
#     $1  [string]    -- The function to execute.
#
__best_cmd_EXEC_TEST() {
	local test="$1"
	local stdout="${TMPDIR}/$$.${test}.stdout"
	local stderr="${TMPDIR}/$$.${test}.stderr"
	__best_tempfiles+=("$stdout" "$stderr")
	__best_last_stdout="$stdout"
	__best_last_stderr="$stderr"

	# Print the info.
	printf "EXEC %s\n" "$test" 1>&3
	printf "FD1 %s\n" "$stdout" 1>&3
	printf "FD2 %s\n" "$stderr" 1>&3

	# Run the test.
	printf "TIMER_BEGIN %d\n" "$(__best_time)";
	__best_run "$1" \
		1>"$stdout" \
		2>"$stderr"
	local status="$?"
	printf "TIMER_END %d\n" "$(__best_time)"

	# Print the exit status.
	__best_last_status="$status"
	printf "EXIT %d\n" "$status" 1>&3
}

# REPL: EXEC
# Execute a regular function.
#
# Arguments:
#     $1  [string]    -- The function to execute.
#
__best_cmd_EXEC() {
	if type "$1" &>/dev/null; then
		"$@" || {
			printf "\nERROR_CODE %d" "$?"
			printf "ERROR_SOURCE %s" "$1"
			printf " %s" "${@:2}"
			exit 1
		} 1>&3
	else
		__best_repl_response "ERROR. Unknown command: %s\n" "$1"
	fi
}

# REPL: SKIP
# Skip a test.
# This is basically just a fake EXEC_TEST.
#
# Arguments:
#     $1  [string]    -- The test name.
#
__best_cmd_SKIP() {
	printf "EXEC %s\nSKIP\nEXIT 0\n" "$1" 1>&3
}

# REPL: CLEANUP
# Remove all temporary files created during this instance.
__best_cmd_CLEANUP() {
	local file
	for file in "${__best_tempfiles[@]}"; do
		__best_repl_response "CLEANUP. Removing temporary: %s\n" "$file"
		rm "$file"
	done

	__best_tempfiles=()
}

# REPL: SHOW
# Show information about the last test.
#
# Arguments:
#     $1  ["STATUS"]    -- The exit code of the last test.
#     $1  ["STDOUT"]    -- The STDOUT of the last test.
#     $1  ["STDERR"]    -- The STDERR of the last test.
#
__best_cmd_SHOW() {
	case "$1" in
		STATUS) echo "$__best_last_status" ;;
		STDOUT|OUT|FD1) cat "$__best_last_stdout" ;;
		STDERR|ERR|FD12) cat "$__best_last_stderr" ;;
		*) __best_repl_response "ERROR. Unknown SHOW target: %s\n" "$1" ;;
	esac
}

# ----------------------------------------------------------------------------------------------------------------------
# Init:
# ----------------------------------------------------------------------------------------------------------------------
if [[ -t 1 ]]; then
	trap '__best_cmd_CLEANUP; exit 0' INT
	__best_repl_response() {
		# shellcheck disable=SC2059
		printf "$@" 1>&2
	}
fi

# Load test libraries.
if [[ -n "${BEST_TEST_LIB}" ]]; then
	shopt -s nullglob
	for __file in "${BEST_TEST_LIB}"/*; do
		# shellcheck disable=SC1090
		source "$__file"
	done
	shopt -u nullglob
	unset __file
else
	__best_repl_response "WARNING: 'BEST_TEST_LIB' is not specified. Test libraries are missing.\n"
fi

# ----------------------------------------------------------------------------------------------------------------------
# REPL:
# ----------------------------------------------------------------------------------------------------------------------
__best_repl_counter=0
__best_tempfiles=()
__best_repl_response "[%d]> " "$__best_repl_counter"
while read -r command args; do
	if [[ -n "${command}" ]]; then
		((__best_repl_counter++)) || true

		# shellcheck disable=SC2086
		__best_cmd_"${command}" $args 3>&1
	fi

	__best_repl_response "[%d]> " "$__best_repl_counter"
done
