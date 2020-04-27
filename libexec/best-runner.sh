#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
__BEST_ROOT="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")" && pwd)")"
__BEST_RUNNER_LIB="${__BEST_ROOT}/lib/test_runner"
# ----------------------------------------------------------------------------------------------------------------------
# shellcheck disable=SC1090
{
	shopt -s nullglob
	for __file in "${__BEST_RUNNER_LIB}"/*.sh; do source "$__file"; done
	for __file in "${TEST_LIB_DIR}"/*; do source <(__best_lib_preprocess < "$__file"); done
	shopt -u nullglob
}
# ----------------------------------------------------------------------------------------------------------------------
__best_cleanup_files=()

# shellcheck disable=SC2059
{
	__best_runner_message_success() { :; }
	__best_runner_message_error()  { __best_ipc_send_crash "$(printf "$@")"; }
}

# An internal function that executes a test function inside a subshell.
#
# Arguments:
#     $1  [string]    -- The test function.
#
__best_run() {
	(
		__BEST_INSIDE_TEST=true
		set -e -o pipefail
		"$1"
	)
	return $?
}

# An internal function that runs a test.
# This performs all the necessary setup and cleanup before calling __best_run to run the test function.
#
# Arguments:
#     $1  [string]    -- The function to execute.
#
__best_run_test() {
	# Set variables.
	local stdout="${TMPDIR}/$$.${test_safe}.stdout"
	local stderr="${TMPDIR}/$$.${test_safe}.stderr"

	# Print the info.
	__best_ipc_send_test_name "$test"
	__best_ipc_send_test_output "$__BEST_OUTPUT_ENUM_STDOUT" "$stdout"
	__best_ipc_send_test_output "$__BEST_OUTPUT_ENUM_STDERR" "$stderr"

	# Run the test.
	__best_ipc_send_test_timestamp "$__BEST_TIMESTAMP_ENUM_START" "$(__best_time)"
	__best_run "$1" \
		1> "$stdout" \
		2> "$stderr"
	local status="$?"
	__best_ipc_send_test_timestamp "$__BEST_TIMESTAMP_ENUM_FINISH" "$(__best_time)"
	__best_ipc_send_test_complete "$status"

	# Update global variables.
	__best_cleanup_files+=("$stdout" "$stderr")
}


# ----------------------------------------------------------------------------------------------------------------------
# Commands:
# ----------------------------------------------------------------------------------------------------------------------

# COMMAND: LOAD
# Loads a file into the current process.
#
# Arguments:
#     $1  [string]    -- The file to load.
#
__best_cmd_LOAD() {
	# shellcheck disable=SC1090
	if ! source "$1"; then
		__best_runner_message_error "Failed to load '%s'." "$1"
	fi
}

# REPL: TEST
# Execute a test function.
#
# Arguments:
#     $1  [string]    -- The function to execute.
#
__best_cmd_TEST() {
	local test="$1"
	local test_safe="${test//[^A-Za-z_]/_}"

	# Check to make sure a valid test was specified.
	if [[ -z "$test" ]]; then
		__best_runner_message_error "No test specified."
		return 1
	fi

	if ! type -t "$test" &>/dev/null; then
		__best_runner_message_error "Unknown test specified."
		return 1
	fi

	# Run the test.
	__best_run_test "$@"
}

# REPL: EVAL
# Evaluate a string.
#
# Arguments:
#     $1  [string]    -- The string to evaluate.
#
__best_cmd_EVAL() {
	local status
	eval "$1" || {
		status="$?"
		__best_runner_message_error "failed with exit code %s" "$status"
	}
}

# REPL: ECHO
# Prints a message back.
#
# Arguments:
#     $1  [string]    -- The message.
#
__best_cmd_ECHO() {
	printf "%s\n" "$1" 1>&3
}


# ----------------------------------------------------------------------------------------------------------------------
# Main:
# ----------------------------------------------------------------------------------------------------------------------

__best_runner_main() {
	local command
	local args

	read -r command args || return $?

	if [[ "$BEST_RUNNER_QUIET" != true ]]; then
		__best_ipc_send_executing_message "$command" "$args" 3>&1
	fi

	__best_cmd_"${command}" "$args" 3>&1
	return 0
}

# shellcheck disable=SC2181
#
# While I would prefer a simple `while __best_runner_main "$@"; do :; done` loop, that can't be used because of the
# rules surrounding `set -e` being ignored.
#
# See https://unix.stackexchange.com/a/65564 for more information.
while true; do
	__best_runner_main "$@"
	if [[ $? -ne 0 ]]; then
		break
	fi
done
