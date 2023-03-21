# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
# shellcheck disable=SC2034 disable=SC2155

# This file contains a list of override functions that replace the normal best-runner.sh functions.
# The functions themselves will not be documented here.

__best_repl_count=0
__best_repl_padding=3
__best_repl_last_command=
__best_repl_last_command_args=()
__best_file_printer=(cat)
__best_cleanup_files=()

# shellcheck disable=SC2054
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
	if [[ "$command_upper" = "!!" ]]; then
		command_upper="${__best_repl_last_command}"
		args=("${__best_repl_last_command_args[@]}")
	else
		__best_repl_last_command="$command_upper"
		__best_repl_last_command_args=("${args[@]}")
	fi

	if ! [[ "$(type -t __best_cmd_"${command_upper}" 2>&1)" =~ function$ ]]; then
		__best_runner_message_error "unknown command"
	else
		__best_cmd_"${command_upper}" "$args" 3>&1
	fi

	return 0
}

__best_runner_message_success() {
	printc "%{SUCCESS}%-${__best_repl_padding}s> $1%{CLEAR}\n" "OK" "${@:2}"
}

__best_runner_message_error() {
	printc "%{ERROR}%-${__best_repl_padding}s> $1%{CLEAR}\n" "ERR" "${@:2}"
}


# ----------------------------------------------------------------------------------------------------------------------
# Help:
# ----------------------------------------------------------------------------------------------------------------------
__best_cmdhelp_ECHO="Prints a message."
__best_cmdhelp_EVAL="Executes a bash command."
__best_cmdhelp_LOAD="Loads a file into the current process."
__best_cmdhelp_TEST="Executes a test function."

# ----------------------------------------------------------------------------------------------------------------------
# Override Commands:
# ----------------------------------------------------------------------------------------------------------------------

__best_cmd_TEST() {
	local errored=false

	# Check to make sure a valid test was specified.
	if [[ -z "$1" ]]; then
		__best_runner_message_error "No test specified."
		return 1
	fi

	if ! [[ "$1" =~ ^test[A-Z_:] ]]; then
		__best_runner_message_error "Please use fully-qualified test names."
		return 1
	fi

	if ! type -t "$1" &>/dev/null; then
		__best_runner_message_error "Unknown test specified."
		return 1
	fi

	# Run the test.
	__best_runner_report < <(__best_run_test "$1" 3>&1)
	if [[ $? -ne 0 ]]; then errored=true; fi

	# Add the output files to cleanup.
	__best_cleanup_files+=("$REPORT_OUTPUT_STDOUT" "$REPORT_OUTPUT_STDERR")

	# Print test information.
	if [[ "$errored" = true ]]; then
		__best_runner_message_error "The test runner crashed."
	else
		local code_color="%{RESULT_${REPORT_RESULT}}"

		printc "Finished with ${code_color}%s%{CLEAR} and exit code ${code_color}%d%{CLEAR} in %d ms.\n" \
			"$REPORT_RESULT" \
			"$REPORT_EXIT" \
			"$REPORT_DURATION"

		local message
		for message in "${REPORT_RESULT_MESSAGES[@]}"; do
			printc "${code_color}%s%{CLEAR}\n" "$message"
		done
	fi

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


# ----------------------------------------------------------------------------------------------------------------------
# Extra Commands:
# ----------------------------------------------------------------------------------------------------------------------

# REPL: HELP
# Shows a list of commands.
__best_cmdhelp_HELP="Shows a list of commands."
__best_cmd_HELP() {
	printc "%{HEADER}Commands:%{CLEAR}\n"

	local command
	local helpvar
	while read -r command; do
		if ! [[ "$command" =~ ^ASYNC ]]; then
			local helpvar="__best_cmdhelp_${command}"
			local helptext="${!helpvar}"
			if [[ -z "$helptext" ]]; then
				printc "%{LIST_ITEM}%s%{CLEAR}\n" "$command"
			elif [[ "$helptext" != "!HIDE" ]]; then
				printc "%{LIST_ITEM}%-10s -- %{LIST_ITEM_DESCRIPTION}%s%{CLEAR}\n" "$command" "$helptext"
			fi
		fi
	done < <(declare -F | grep '^declare -f __best_cmd_' | sed 's/^declare -f __best_cmd_//')
}

# REPL: EXIT
# Exits the REPL.
__best_cmdhelp_EXIT="Exits the REPL."
__best_cmd_EXIT() {
	__best_cmd_CLEANUP 3>&1
	exit 0
}

# REPL: SHOW
# Shows information about the last test.
#
# Arguments:
#     $1  ["STATUS"]    -- The exit code of the last test.
#     $1  ["STDOUT"]    -- The STDOUT of the last test.
#     $1  ["STDERR"]    -- The STDERR of the last test.
#     $1  ["TESTS"]     -- A list of runnable tests.
#
__best_cmdhelp_SHOW="Shows information about the last test."
__best_cmd_SHOW() {
	local target="$(tr '[:lower:]' '[:upper:]' <<< "$1")"
	local show=""
	case "$target" in
		STATUS) show="REPORT_EXIT" ;;
		STDOUT | OUT | FD1) show="REPORT_OUTPUT_STDOUT" ;;
		STDERR | ERR | FD2) show="REPORT_OUTPUT_STDERR" ;;
		TESTS) {
			declare -F | grep '^declare -f test[A-Z_:]' | sed 's/^declare -f //'
			return 0
		} ;;
		''|*) {
			printc "SHOW TESTS  -- Show the list of runnable tests.\n"
			printc "SHOW STATUS -- Show the exit code of the last test.\n"
			printc "SHOW OUT    -- Show the STDOUT contents of the last test.\n"
			printc "SHOW ERR    -- Show the STDERR contents of the last test.\n"
			return 0
		} ;;
	esac
	
	if [[ -z "$REPORT_EXIT" ]]; then
		__best_runner_message_error "No test has been run yet."
		return 1
	fi
	
	case "$show" in
		REPORT_EXIT) echo "${!show}" ;;
		*)           "${__best_file_printer[@]}" "${!show}" ;;
	esac
}

# REPL: CLEANUP
# Removes all temporary files created during this instance.
__best_cmdhelp_CLEANUP="!HIDE"
__best_cmd_CLEANUP() {
	local file
	for file in "${__best_cleanup_files[@]}"; do
		rm "$file"
	done
}
