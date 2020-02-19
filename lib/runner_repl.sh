# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# This file contains a list of override functions that replace the normal best-runner.sh functions.
# The functions themselves will not be documented here.

__best_repl_count=0
__best_repl_padding=3
__best_file_printer=(cat)
__best_cleanup_files=()

if command -v bat &>/dev/null; then __best_file_printer=(bat --paging=never --style=grid,numbers); fi
trap 'printf "\n"; __best_cmd_CLEANUP 3>&1; exit 0' INT

__best_runner_main() {
	local command
	local command_upper
	local args

	# Read the command.
	# The real STDIN should be FD4 (if this was run through `best --repl`).
	read -e -r -p "[${__best_repl_count}]> " command args 0<&4
	if [[ -z "$command" ]]; then
		return 0
	fi

	# Increment the repl counter.
	((__best_repl_count++)) || true
	__best_repl_padding="$(( ${#__best_repl_count} + 2 ))"

	# Run the command.
	command_upper="$(tr '[:lower:]' '[:upper:]' <<< "$command")"
	if ! [[ "$(type -t __best_cmd_"${command_upper}" 2>&1)" =~ function$ ]]; then
		__best_runner_message_error "unknown command"
	elif [[ "${command_upper}" = "TEST" && "$BEST_RUNNER_QUIET" = true ]]; then
		__best_runner_main_test "$args"
	else
		__best_cmd_"${command_upper}" "$args" 3>&1
	fi

	return 0
}

__best_runner_main_test() {
	# Check to make sure a valid test was specified.
	if [[ -z "$1" ]]; then
		__best_runner_message_error "No test specified."
		return 1
	fi

	if ! type -t "$1" &>/dev/null; then
		__best_runner_message_error "Unknown test specified."
		return 1
	fi

	# Run the test.
	__best_runner_report < <(__best_cmd_TEST "$1" 3>&1)

	# Add the output files to cleanup.
	__best_cleanup_files+=("$REPORT_OUTPUT_STDOUT" "$REPORT_OUTPUT_STDERR")

	# Print test information.
	local code_color="%{RESULT_${REPORT_RESULT}}"

	printc "Finished with ${code_color}%s%{CLEAR} and exit code ${code_color}%d%{CLEAR} in %d ms.\n" \
		"$REPORT_RESULT" \
		"$REPORT_EXIT" \
		"$REPORT_DURATION"

	local message
	for message in "${REPORT_RESULT_MESSAGES[@]}"; do
		printc "${code_color}%s%{CLEAR}\n" "$message"
	done

	# Print test outputs.
	if [[ "$(__best_stat_size "$REPORT_OUTPUT_STDOUT")" -gt 0 ]]; then
		printc "\n%{HEADER}STDOUT:%{CLEAR}\n"
		"${__best_file_printer[@]}" "$REPORT_OUTPUT_STDOUT"
	fi

	if [[ "$(__best_stat_size "$REPORT_OUTPUT_STDERR")" -gt 0 ]]; then
		printc "\n%{HEADER}STDERR:%{CLEAR}\n"
		"${__best_file_printer[@]}" "$REPORT_OUTPUT_STDERR"
	fi

	printf "\n"
}

__best_runner_message_success() {
	printc "%{SUCCESS}%-${__best_repl_padding}s> $1%{CLEAR}\n" "OK" "${@:2}"
}

__best_runner_message_error() {
	printc "%{ERROR}%-${__best_repl_padding}s> $1%{CLEAR}\n" "ERR" "${@:2}"
}


# ----------------------------------------------------------------------------------------------------------------------
# Extra Commands:
# ----------------------------------------------------------------------------------------------------------------------

# REPL: HELP
# Show a list of commands.
__best_cmd_HELP() {
	printc "%{HEADER}Commands:%{CLEAR}\n"

	local command;
	while read -r command; do
		printc "%{LIST_ITEM}%s%{CLEAR}\n" "$command"
	done < <(declare -F | grep '^declare -f __best_cmd_' | sed 's/^declare -f __best_cmd_//')
}

# REPL: SHOW
# Show information about the last test.
#
# Arguments:
#     $1  ["STATUS"]    -- The exit code of the last test.
#     $1  ["STDOUT"]    -- The STDOUT of the last test.
#     $1  ["STDERR"]    -- The STDERR of the last test.
#
__best_cmd_SHOW() {
	local target="$(tr '[:lower:]' '[:upper:]' <<< "$1")"
	case "$target" in
		STATUS) echo "$REPORT_EXIT" ;;
		STDOUT | OUT | FD1) "${__best_file_printer[@]}" "$REPORT_OUTPUT_STDOUT" ;;
		STDERR | ERR | FD12) "${__best_file_printer[@]}" "$REPORT_OUTPUT_STDERR" ;;
		TESTS) {
			declare -F | grep '^declare -f test[A-Z_:]' | sed 's/^declare -f //'
		} ;;
		''|*) {
			printc "SHOW TESTS  -- Show the list of runnable tests.\n"
			printc "SHOW STATUS -- Show the exit code of the last test.\n"
			printc "SHOW OUT    -- Show the STDOUT contents of the last test.\n"
			printc "SHOW ERR    -- Show the STDERR contents of the last test.\n"
		} ;;
	esac
}

# REPL: CLEANUP
# Remove all temporary files created during this instance.
__best_cmd_CLEANUP() {
	local file
	for file in "${__best_cleanup_files[@]}"; do
		rm "$file"
	done
}
