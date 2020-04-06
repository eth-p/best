# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Checks that an array contains a value.
#
# Arguments:
#     $1  [string]    -- The value to check.
#     $2  "in"        -- The string "in".
#     ... [string]    -- The array contents.
#
# Example:
#
#     array_contains "world" in "${MY_ARRAY[@]}"
#
:PREFIX:array_contains() {
	if [[ "$2" != "in" ]]; then
		echo "array_contains: expected string 'in' for second argument" 1>&2
		return 2
	fi

	local search="$1"
	local value
	for value in "${@:3}"; do
		if [[ "$search" = "$value" ]]; then
			return 0
		fi
	done

	return 1
}
