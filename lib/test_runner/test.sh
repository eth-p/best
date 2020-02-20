# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Sets the test result (and sends an IPC message) if the result was not already set earlier.
#
# Arguments:
#     $1  ["FAIL"|"PASS"|"SKIP"]  -- The result type.
#     $2  [string]                -- The result message.
#
# Example:
#
#     __best_test_set_result SKIP "The test was skipped."
#
__best_test_set_result() {
	if [[ -n "$__best_test_status__result" ]]; then
		return 0
	fi

	# Set the result variable.
	__best_test_status__result="$1"

	# Send the result IPC message.
	__best_ipc_send_test_result "$1"
	if [[ $# -gt 1 ]]; then
		__best_ipc_send_test_result_message "${@:2}"
	fi

	return 0
}

# Aborts the test.
#
# Arguments:
#     $1  ["FAIL"|"PASS"|"SKIP"]  -- The result type.
#     $2  [string]                -- The result message.
#
# Example:
#
#     __best_test_abort FAIL "The test was aborted."
#
__best_test_abort() {
	__best_ipc_send_test_result "$1"
	if [[ $# -gt 1 ]]; then
		__best_ipc_send_test_result_message "${@:2}"
	fi
	exit 1
}
