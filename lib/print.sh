# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Printf, but with optional colors.
# This uses the same syntax and arguments as printf.
#
# Arguments:
#     $1  [string] -- The formatting string.
#     ... [string] -- The formatting arguments.
#
# Example:
#     printc "%{RED}This is red %s.%{CLEAR}\n" "text"
#
printc() {
	# shellcheck disable=SC2059
	printf "$(sed "$_PRINTC_PATTERN" <<< "$1")" "${@:2}"
}

# Initializes the color tags for printc.
#
# Arguments:
#     $1  [true|false] -- Turns on/off color output.
#
# shellcheck disable=SC2120
printc_init() {
	case "$1" in
		true) _PRINTC_PATTERN="$_PRINTC_PATTERN_ANSI" ;;
		false) _PRINTC_PATTERN="$_PRINTC_PATTERN_PLAIN" ;;
		auto|'') {
			_PRINTC_PATTERN_ANSI=""
			_PRINTC_PATTERN_PLAIN=""

			local name
			local ansi
			while read -r name ansi; do
				if [[ -z "${name}" && -z "${ansi}" ]] || [[ "${name:0:1}" = "#" ]]; then
					continue
				fi

				_PRINTC_PATTERN_PLAIN="${_PRINTC_PATTERN_PLAIN}s/%{${name}}//g;"
				_PRINTC_PATTERN_ANSI="${_PRINTC_PATTERN_ANSI}s/%{${name}}/${ansi//\\/\\\\}/g;"
			done

			if [ -t 1 ]; then
				_PRINTC_PATTERN="$_PRINTC_PATTERN_ANSI"
			else
				_PRINTC_PATTERN="$_PRINTC_PATTERN_PLAIN"
			fi
		} ;;
	esac
}


# ----------------------------------------------------------------------------------------------------------------------
# Initialization:
# ----------------------------------------------------------------------------------------------------------------------
printc_init << "END"
	CLEAR	\x1B[0m
	DIM     \x1B[2m
	ERROR   \x1B[31m
	WARNING \x1B[33m
	DEBUG   \x1B[2;37m

	SEPARATOR \x1B[0;2;37m
	HEADER    \x1B[37m
	
	LIST_ITEM             \x1B[0m
	LIST_ITEM_DESCRIPTION \x1B[0;2m

	SUITE_NAME        \x1B[35m
	TEST_NAME         \x1B[34m
	TEST_DESCRIPTION  \x1B[0m
	FILE              \x1B[39m

	RESULT_PASS \x1B[32m
	RESULT_SKIP \x1B[37m
	RESULT_FAIL \x1B[31m
END
