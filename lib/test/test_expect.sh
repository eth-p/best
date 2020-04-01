# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Expects a statement returns true.
#
# Arguments:
#     ... [string]    -- The command and arguments to execute.
#
# Example:
#
#     expect [ "true" = false ]
#
expect() {
	if "$@" &>/dev/null; then
		return 0
	fi

	__best_ipc_send_test_result "FAIL"
	__best_ipc_send_test_result_message "Expectation failed: %s"
	__best_ipc_send_test_result_message_data "$*"
}

# Expects one value equals another value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#
# Example:
#
#     expect_equal 2 2
#
expect_equal() {
	expect [ "$1" = "$2" ]
	return $?
}

# Expects one value does not equal another value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#
# Example:
#
#     expect_not_equal 1 2
#
expect_not_equal() {
	expect [ "$1" != "$2" ]
	return $?
}

# Expects one value is less than the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#
# Example:
#
#     expect_less 1 2
#
expect_less() {
	expect [ "$1" -lt "$2" ]
	return $?
}

# Expects one value is less than or equal to the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#
# Example:
#
#     expect_less_or_equal 2 2
#
expect_less_or_equal() {
	expect [ "$1" -le "$2" ]
	return $?
}

# Expects one value is greater than the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#
# Example:
#
#     expect_greater 5 2
#
expect_greater() {
	expect [ "$1" -gt "$2" ]
	return $?
}

# Expects one value is greater than or equal to the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#
# Example:
#
#     expect_greater_or_equal 2 2
#
expect_greater_or_equal() {
	expect [ "$1" -ge "$2" ]
	return $?
}
