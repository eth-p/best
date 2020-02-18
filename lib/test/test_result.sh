# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

fail() {
	__best_fn_fail
	if [[ $# -ge 1 ]]; then
		__best_fn_fail_reason "$@"
	fi
	exit 255
}

skip() {
	__best_fn_skip
	exit 0
}
