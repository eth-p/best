# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

:PREFIX:use_shim() {
	local dir
	while read -r -d ':' dir; do
		if [[ -f "${dir}/$1.sh" ]]; then
			source "${dir}/$1.sh" || return $?
			return 0
		fi
	done <<< "$TEST_SHIM_PATH:"

	if [[ "$__BEST_INSIDE_TEST" = true ]]; then
		:PREFIX:fail "Could not find shim: %s" "$1"
	else
		__best_ipc_send_crash "Could not find shim: $1"
		exit 1
	fi
}
