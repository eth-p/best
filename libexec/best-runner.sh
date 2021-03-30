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
	for __file in "${TEST_LIB_DIR}"/*; do eval "$(__best_lib_preprocess < "$__file")"; done
	shopt -u nullglob
}
# ----------------------------------------------------------------------------------------------------------------------
__best_cleanup_files=()
__best_async_pids=()
__best_async_reports=()

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
	local test="$1"
	local test_safe="${test//[^A-Za-z0-9_]/_}"
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

# Checks to see if a test function name is valid.
#
# Arguments:
#     $1  [string]    -- The test function to execute.
#
# Returns:
#     0  -- If the function is valid.
#     1  -- Otherwise.
__best_check_test_valid() {
	# Check to make sure a valid test was specified.
	if [[ -z "$1" ]]; then
		__best_runner_message_error "No test specified."
		return 1
	fi

	if ! type -t "$1" &> /dev/null; then
		__best_runner_message_error "Unknown test specified."
		return 1
	fi

	return 0
}

# Waits for the next async test job to complete.
__best_async_helper_wait() {
	# `wait -n` doesn't work, so we need to poll.
	local jobpid
	while true; do
		local index=0
		for jobpid in "${__best_async_pids[@]}"; do
			if ! kill -0 "$jobpid" 2> /dev/null; then
				__best_ipc_send "ASYNC_END" "$jobpid"
				unset __best_async_pids["$index"]
				__best_async_pids=("${__best_async_pids[@]}")
				return 0
			fi
			((index++)) || true
		done
		sleep 0.01
	done
}

# Attempts to print the report of the oldest async test jobs spawned.
#
# If the oldest job is not complete yet, this will print nothing and return 1.
# This is to prevent incorrect ordering.
__best_async_helper_print() {
	local status=1

	# If the first report is complete, print it.
	while [[ -f "${__best_async_reports[0]}.complete" ]]; do
		cat "${__best_async_reports[0]}.complete"
		rm "${__best_async_reports[0]}.complete"
		__best_async_reports=("${__best_async_reports[@]:1}")
		status=0
	done

	return $status
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
# Executes a test function.
#
# Arguments:
#     $1  [string]    -- The function to execute.
#
__best_cmd_TEST() {
	__best_check_test_valid "$1" || return $?
	__best_run_test "$@"
}

# REPL: ASYNC_TEST
# Execute a test function asynchronously.
#
# Arguments:
#     $1  [string]    -- The function to execute.
#
__best_cmd_ASYNC_TEST() {
	__best_check_test_valid "$1" || return $?

	{
		# Read the test report file name.
		local reportfile
		read -r reportfile
	} < <({
		# Set BASHPID for bash < 4.
		if [[ -z "$BASHPID" ]]; then
			BASHPID="$(bash -c 'echo $PPID')"
		fi

		# Run the test in the background.
		local reportfile="${TMPDIR}/$$.async_${BASHPID}.report"
		printf "%s\n" "$reportfile"

		exec 3> "$reportfile"
		__best_run_test  "$@"
		mv "$reportfile" "${reportfile}.complete"
	})

	# Read the job pid and store the pid/report file in an array.
	local jobpid="$!"
	__best_async_pids+=("$jobpid")
	__best_async_reports+=("$reportfile")

	# Send the async test IPC and return.
	__best_ipc_send "ASYNC_TEST" "$jobpid"
}

# REPL: ASYNC_WAIT_NEXT
# Waits for one of the async test to complete.
# If the completed test is the oldest one executed, this will print its report.
__best_cmd_ASYNC_WAIT_NEXT() {
	if [[ "${#__best_async_pids[@]}" -eq 0 ]]; then return 0; fi

	__best_async_helper_wait
	__best_async_helper_print || true
}

# REPL: ASYNC_WAIT_ALL
# Waits for all of the async test to complete, and prints their reports.
__best_cmd_ASYNC_WAIT_ALL() {
	if [[ "${#__best_async_pids[@]}" -eq 0 ]]; then return 0; fi

	# Wait for all the jobs and try to print all the reports.
	while [[ "${#__best_async_pids[@]}" -gt 0 ]]; do
		__best_async_helper_wait
		__best_async_helper_print || true
	done
}

# REPL: EVAL
# Evaluates a string.
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

	__best_cmd_"${command}" "$args" 3>&1 <<< ""  # We give it an empty STDIN to prevent tests from eating IPC commands.
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
