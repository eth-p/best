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
fail() {
	__best_fn_fail
	if [[ $# -ge 1 ]]; then
		__best_fn_fail_reason "$@"
	fi
	exit 255
}

# Causes the test to be skipped.
skip() {
	__best_fn_skip
	exit 0
}
