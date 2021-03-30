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
#     assert ! false
#
:PREFIX:expect() {
	if [[ "$1" = "!" ]]; then
		if ! "$@" &>/dev/null; then
			return 0
		fi
	else
		if "$@" &>/dev/null; then
			return 0
		fi
	fi

	__best_test_set_result "$__BEST_RESULT_ENUM_FAIL" "Expectation failed: %s" "$*"
}

# Expects one value equals another value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#     $3  {"--"}      -- An optional specifier that enables custom failure messages.
#     $4  {string}    -- The custom failure message pattern, with "%s" for the values provided.
#
# Example:
#
#     expect_equal 2 2
#
:PREFIX:expect_equal() {
	if [[ "$3" = "--" && -n "$4" ]]; then
		[[ "$1" = "$2" ]] || __best_test_set_result "$__BEST_RESULT_ENUM_FAIL" "Expected $4" "$1" "$2"
		return $?
	else
		:PREFIX:expect [ "$1" = "$2" ]
		return $?
	fi
}

# Expects one value does not equal another value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#     $3  {"--"}      -- An optional specifier that enables custom failure messages.
#     $4  {string}    -- The custom failure message pattern, with "%s" for the values provided.
#
# Example:
#
#     expect_not_equal 1 2
#
:PREFIX:expect_not_equal() {
	if [[ "$3" = "--" && -n "$4" ]]; then
		[[ "$1" != "$2" ]] || __best_test_set_result "$__BEST_RESULT_ENUM_FAIL" "Expected $4" "$1" "$2"
		return $?
	else
		:PREFIX:expect [ "$1" != "$2" ]
		return $?
	fi
}

# Expects one value is less than the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#     $3  {"--"}      -- An optional specifier that enables custom failure messages.
#     $4  {string}    -- The custom failure message pattern, with "%s" for the values provided.
#
# Example:
#
#     expect_less 1 2
#
:PREFIX:expect_less() {
	if [[ "$3" = "--" && -n "$4" ]]; then
		[[ "$1" -lt "$2" ]] || __best_test_set_result "$__BEST_RESULT_ENUM_FAIL" "Expected $4" "$1" "$2"
		return $?
	else
		:PREFIX:expect [ "$1" -lt "$2" ]
		return $?
	fi
}

# Expects one value is less than or equal to the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#     $3  {"--"}      -- An optional specifier that enables custom failure messages.
#     $4  {string}    -- The custom failure message pattern, with "%s" for the values provided.
#
# Example:
#
#     expect_less_or_equal 2 2
#
:PREFIX:expect_less_or_equal() {
	if [[ "$3" = "--" && -n "$4" ]]; then
		[[ "$1" -le "$2" ]] || __best_test_set_result "$__BEST_RESULT_ENUM_FAIL" "Expected $4" "$1" "$2"
		return $?
	else
		:PREFIX:expect [ "$1" -le "$2" ]
		return $?
	fi
}

# Expects one value is greater than the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#     $3  {"--"}      -- An optional specifier that enables custom failure messages.
#     $4  {string}    -- The custom failure message pattern, with "%s" for the values provided.
#
# Example:
#
#     expect_greater 5 2
#
:PREFIX:expect_greater() {
	if [[ "$3" = "--" && -n "$4" ]]; then
		[[ "$1" -gt "$2" ]] || __best_test_set_result "$__BEST_RESULT_ENUM_FAIL" "Expected $4" "$1" "$2"
		return $?
	else
		:PREFIX:expect [ "$1" -gt "$2" ]
		return $?
	fi
}

# Expects one value is greater than or equal to the other value.
#
# Arguments:
#     $1  [string]    -- The first value.
#     $2  [string]    -- The second value.
#     $3  {"--"}      -- An optional specifier that enables custom failure messages.
#     $4  {string}    -- The custom failure message pattern, with "%s" for the values provided.
#
# Example:
#
#     expect_greater_or_equal 2 2
#
:PREFIX:expect_greater_or_equal() {
	if [[ "$3" = "--" && -n "$4" ]]; then
		[[ "$1" -ge "$2" ]] || __best_test_set_result "$__BEST_RESULT_ENUM_FAIL" "Expected $4" "$1" "$2"
		return $?
	else
		:PREFIX:expect [ "$1" -ge "$2" ]
		return $?
	fi
	return $?
}
