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
#     $2  [string]                -- The result message (printf pattern).
#     ... [string]                -- The pattern arguments.
#
# Example:
#
#     __best_test_set_result SKIP "The test was skipped."
#
__best_test_set_result() {
	# If the reason is downgrading, return early.
	case "$__best_test_status__result->$1" in
		"$__BEST_RESULT_ENUM_FAIL->$__BEST_RESULT_ENUM_SKIP") return 0 ;;
		"$__BEST_RESULT_ENUM_FAIL->$__BEST_RESULT_ENUM_PASS") return 0 ;;
		"$__BEST_RESULT_ENUM_SKIP->$__BEST_RESULT_ENUM_PASS") return 0 ;;
	esac
	
	# Set the result variable.
	__best_test_status__result="$1"
	
	# Send the result IPC message.
	__best_ipc_send_test_result "$1"

	# Send the result reason IPC message.
	if [[ $# -gt 1 ]]; then
		__best_ipc_send_test_result_message "$2"
		
		# Send the reason pattern data.
		if [[ $# -gt 2 ]]; then
			local data
			for data in "${@:3}"; do
				__best_ipc_send_test_result_message_data "$data"
			done
		fi
	fi

	return 0
}

# Aborts the test.
#
# Arguments:
#     $1  ["FAIL"|"PASS"|"SKIP"]  -- The result type.
#     $2  [string]                -- The result message (printf pattern).
#     ... [string]                -- The pattern arguments.
#
# Example:
#
#     __best_test_abort FAIL "The test was aborted."
#
__best_test_abort() {
	__best_test_set_result "$@"
	exit 1
}
