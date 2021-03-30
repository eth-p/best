# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Causes the test to immediately fail.
#
# Arguments:
#     $1  [string]    -- The failure reason (printf pattern).
#     ... [string]    -- The pattern arguments.
#
# Example:
#
#     fail "Could not find '%s'" "bash"
#
:PREFIX:fail() {
	if [[ $# -eq 0 ]]; then
		__best_test_abort "$__BEST_RESULT_ENUM_FAIL" "Test called 'fail' function."
	else
		# shellcheck disable=SC2059
		__best_test_abort "$__BEST_RESULT_ENUM_FAIL" "$(printf "$@")"
	fi
	exit 1
}

# Causes the test to send a fail result, but continue running.
#
# Arguments:
#     $1  [string]    -- The failure reason (printf pattern).
#     ... [string]    -- The pattern arguments.
#
# Example:
#
#     fail "Could not find '%s'" "bash"
#
:PREFIX:deferred_fail() {
	local message="Test called 'deferred_fail' function."
	if [[ $# -gt 0 ]]; then
		# shellcheck disable=SC2059
		message="$(printf "${@:1}")"
	fi
	
	__best_ipc_send_test_result "FAIL"
	__best_ipc_send_test_result_message "$message"
}

# Causes the test to be skipped.
#
# Arguments:
#     $1  [string]    -- The failure reason (printf pattern).
#     ... [string]    -- The pattern arguments.
#
# Example:
#
#     skip "Test disabled on %s." "$(uname -s)"
#
:PREFIX:skip() {
	# shellcheck disable=SC2059
	if [[ $# -gt 0 ]]; then
		__best_test_abort "$__BEST_RESULT_ENUM_SKIP" "$(printf "$@")"
	else
		__best_test_abort "$__BEST_RESULT_ENUM_SKIP" ""
	fi
	exit 255
}
