# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

use_shim() {
	if [[ -f "$1.sh" ]]; then
		source "$1.sh"
	elif [[ -f "${BEST_SHIM_DIR}/$1.sh" ]]; then
		source "${BEST_SHIM_DIR}/$1.sh"
	else
		if [[ "$__BEST_INSIDE_TEST" = true ]]; then
			fail "Could not find shim: %s" "$1"
		else
			__best_ipc_send_crash "Could not find shim: $1"
			exit 1
		fi
	fi
}
