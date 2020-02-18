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
		fail "Could not find shim: %s" "$1"
	fi
}
