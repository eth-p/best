# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

use_shim() {
	source "${BEST_SHIM_DIR}/$1.sh"
}

fail() {
	__best_fn_fail
	if [[ $# -ge 1 ]]; then
		__best_fn_fail_reason "$@"
	fi
	exit 255
}

assert() {
	if "$@" &>/dev/null; then
		return 0
	fi

	__best_fn_fail
	__best_fn_fail_reason "Assertion failed: %s" "$*"
	return 1
}

assert_equals() {
	assert [[ "$1" = "$2" ]]
	return $?
}
