# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Printc, but only when $VERBOSE is true.
#
# Arguments:
#     $1  [string] -- The formatting string.
#     ... [string] -- The formatting arguments.
#
# Example:
#     printv "%{RED}This is red %s.%{CLEAR}\n" "text"
#
printv() {
	if [[ "$VERBOSE" = true || "$VERBOSE" = 1 ]]; then
		printc "$@"
	fi
}

# Printc, but only when $DEBUG is true.
# This will print to STDERR instead of STDOUT.
#
# Arguments:
#     $1  [string] -- The formatting string.
#     ... [string] -- The formatting arguments.
#
# Example:
#     printvd "%{RED}This is red %s.%{CLEAR}\n" "text"
#
printvd() {
	if [[ "$VERBOSE" = true || "$VERBOSE" = 1 ]] && [[ "$DEBUG" = true || "$DEBUG" = 1 ]]; then
		printc "%{DEBUG}[DEBUG] %{CLEAR}$1" "${@:2}" 1>&2
	fi
}

# Defers printing of warning and error messages using `print_warning` and `print_error`
#
# Arguments:
#     $1  [true]  -- Turns on deferred printing.
#     $1  [false] -- Turns off deferred printing, and prints the existing messages.
print_defer() {
	case "$1" in
		true) {
			PRINT_DEFER=true
		} ;;

		false) {
			PRINT_DEFER=false
		} ;;

		flush) {
			# Print any warnings.
			if [[ "${#MSG_WARNINGS[@]}" -gt 0 ]]; then
				printf "\n" 2>&1
				for warning in "${MSG_WARNINGS[@]}"; do
					printf "%s\n" "$warning" 1>&2
				done
			fi

			# Print any errors.
			if [[ "${#MSG_ERRORS[@]}" -gt 0 ]]; then
				printf "\n" 2>&1
				for warning in "${MSG_ERRORS[@]}"; do
					printf "%s\n" "$warning" 1>&2
				done
			fi

			# Clear the buffers.
			MSG_WARNINGS=()
			MSG_ERRORS=()
		} ;;
	esac
}

# Prints an error message.
# This automatically adds a newline.
#
# Arguments:
#     $0  [string] -- The formatting string.
#     ... [string] -- The formatting arguments.
#
# Example:
#     print_error "an error happened in %s" "myfile.sh"
#
print_error() {
	if [[ "$PRINT_DEFER" = true ]]; then
		MSG_ERRORS+=("$(printc "%{ERROR}%s: $1%{CLEAR}" "$PROGRAM" "${@:2}")")
	else
		printc "%{ERROR}%s: $1%{CLEAR}\n" "$PROGRAM" "${@:2}" 1>&2
	fi
}

# Prints an error message and exits.
# This automatically adds a newline.
#
# Arguments:
#     $0  [string] -- The formatting string.
#     ... [string] -- The formatting arguments.
#
# Example:
#     print_error "an error happened in %s" "myfile.sh"
#
fatal_error() {
	print_error "$@"
	print_defer flush
	exit 1
}

# Prints a warning message.
# This automatically adds a newline.
#
# Arguments:
#     $1  [string] -- The formatting string.
#     ... [string] -- The formatting arguments.
#
# Example:
#     print_warning "a warning happened in %s" "myfile.sh"
#
print_warning() {
	if [[ "$PRINT_DEFER" = true ]]; then
		MSG_WARNINGS+=("$(printc "%{WARNING}%s: $1%{CLEAR}" "$PROGRAM" "${@:2}")")
	else
		printc "%{WARNING}%s: $1%{CLEAR}\n" "$PROGRAM" "${@:2}" 1>&2
	fi
}

# Prints a horizontal separator.
print_separator() {
	printc "%{SEPARATOR}%s%{CLEAR}\n" "$H_SEPARATOR"
}

print_header() {
	printc "%{SEPARATOR}%s\n%s%{CLEAR}%{HEADER} %-$((${#H_SEPARATOR} - 4))s %{CLEAR}%{SEPARATOR}%s\n%s%{CLEAR}\n" \
		"$H_SEPARATOR" \
		"$V_SEPARATOR_CHAR" "$1" "$V_SEPARATOR_CHAR" \
		"$H_SEPARATOR"
}

# ----------------------------------------------------------------------------------------------------------------------
# Initialization:
# ----------------------------------------------------------------------------------------------------------------------
H_SEPARATOR_CHAR="-"
V_SEPARATOR_CHAR="|"
H_SEPARATOR="$(printf "%$(term_width)s" "" | tr ' ' "$H_SEPARATOR_CHAR")"
