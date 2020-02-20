# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
source "${LIB}/runner.sh"
source "${LIB}/runner_report.sh"
source "${LIB}/runner_snapshot.sh"
source "${LIB}/stat.sh"
# ----------------------------------------------------------------------------------------------------------------------
if [[ "${#SUITE_FILES[@]}" -eq 0 ]]; then
	fatal_error "No test suites found."
fi
# ----------------------------------------------------------------------------------------------------------------------
# Functions:
# ----------------------------------------------------------------------------------------------------------------------

run_test() {
	printvd "running: %s\n" "$TEST_NAME"
	runner:run "$TEST_NAME"
}

run_test_maybe() {
	if [[ "${#RUN_TESTS[@]}" -eq 0 ]]; then
		run_test
		return $?
	fi

	# If a subset of tests are run, we have to check if the test ID is within this subset.
	local key
	for key in "${!RUN_TESTS[@]}"; do
		local test="${RUN_TESTS[$key]}"
		if [[ "$TEST_ID" == "${RUN_TESTPREFIX}${test}" || "$TEST_ID" == "${test}" ]]; then
			RUN_TESTS=("${RUN_TESTS[@]/$key/}")
			run_test
			return $?
		fi
	done

	# We aren't running the test.
	runner:skip "$TEST_NAME"
}

run_suite() {
	SUITE_FILE="$1"
	SUITE_NAME="$(suite_name "$SUITE_FILE")"
	REPORT_SUITE="$SUITE_FILE"

	TOTAL_PASSED=0
	TOTAL_FAILED=0
	TOTAL_SKIPPED=0
	TOTAL_IGNORED=0

	show_suite_name "$SUITE_NAME"

	# File descriptor table:
	#   FD6: intermediate for writing to STDOUT
	#   FD5: intermediate for writing to STDERR
	#   FD4: best command output
	#   FD3: best-runner command response
	# `run_suite` sends commands to a runner instance through FD4, and outputs messages through FD1.
	# The complex FD redirections below enable this to happen.
	exec 6>&1 5>&2
	parse_suite_report < <(runner < <({
		exec 3>&1 1>&6
		runner:load "$1"
		runner:test_setup

		# Call `run_test_maybe` for each test in the suite.
		{
			suite_tests load "$suite"
			while suite_tests next; do
				TEST_ID="${SUITE_NAME}:$(test_name "${TEST_NAME}")"
				run_test_maybe
			done
		}

		runner:test_teardown
	}))

	TOTAL_ALL="$((TOTAL_PASSED + TOTAL_FAILED + TOTAL_SKIPPED))"
	show_suite_totals
}

parse_suite_report() {
	while runner_report; do
		# Create decorations.
		REPORT_DECORATIONS=()
		REPORT_DECORATION_STRING=''
		if [[ "$REPORT_TIMESTAMP_STARTED" -ne 0 ]]; then REPORT_DECORATIONS+=("${REPORT_DURATION} ms"); fi
		if [[ "${#REPORT_DECORATIONS[@]}" -gt 0 ]]; then
			REPORT_DECORATION_STRING=" ::$(printf " %s" "${REPORT_DECORATIONS[@]}")"
		fi

		# Show the test report result.
		case "$REPORT_RESULT" in
			PASS)
				RESULT_COLOR="%{RESULT_PASS}"
				((TOTAL_PASSED++)) || true
				show_passed_test
				;;
			SKIP)
				RESULT_COLOR="%{RESULT_SKIP}"
				((TOTAL_SKIPPED++)) || true
				show_skipped_test
				;;
			FAIL | *)
				COMMAND_EXIT=2
				RESULT_COLOR="%{RESULT_FAIL}"
				((TOTAL_FAILED++)) || true
				show_failed_test
				;;
		esac

		# Delete the test output files.
		if [[ -f "$REPORT_OUTPUT_STDOUT" ]]; then rm "$REPORT_OUTPUT_STDOUT"; fi
		if [[ -f "$REPORT_OUTPUT_STDERR" ]]; then rm "$REPORT_OUTPUT_STDERR"; fi
	done
}

__best_runner_report:parse:IGNORE() {
	((TOTAL_IGNORED++)) || true
}

# ----------------------------------------------------------------------------------------------------------------------
# Functions: Reporting
# ----------------------------------------------------------------------------------------------------------------------

show_suite_name() {
	print_header "Test Suite: $1"
}

show_passed_test() {
	printc "[${RESULT_COLOR}PASS%{CLEAR}] %-20s%s\n" "$(test_name "$REPORT_TEST")" "$REPORT_DECORATION_STRING"

	if [[ "$VERBOSE_EVERYTHING" == true ]]; then
		show_test_output "STDOUT" "$REPORT_OUTPUT_STDOUT"
		show_test_output "STDERR" "$REPORT_OUTPUT_STDERR"
	fi
}

show_failed_test() {
	printc "[${RESULT_COLOR}FAIL%{CLEAR}] %-20s" "$(test_name "$REPORT_TEST")"
	show_report_messages

	if [[ "$SNAPSHOT_SHOW" == true && -n "$REPORT_SNAPSHOT_DIFF" ]]; then
		show_snapshot_diff "" "$REPORT_SNAPSHOT_DIFF"
	fi

	if [[ "$VERBOSE" == true ]]; then
		show_test_output "STDOUT" "$REPORT_OUTPUT_STDOUT"
		show_test_output "STDERR" "$REPORT_OUTPUT_STDERR"
	fi
}

show_skipped_test() {
	printc "[${RESULT_COLOR}SKIP%{CLEAR}] %-20s" "$(test_name "$REPORT_TEST")"
	show_report_messages
}

show_report_messages() {
	if [[ "${#REPORT_RESULT_MESSAGES[@]}" -eq 0 ]]; then
		printf "\n"
	elif [[ "${#REPORT_RESULT_MESSAGES[@]}" -eq 1 ]]; then
		printc "${RESULT_COLOR} :: %s%{CLEAR}\n" "${REPORT_RESULT_MESSAGES[0]}"
	else
		printc "${RESULT_COLOR} :: %s%{CLEAR}\n" "${REPORT_RESULT_MESSAGES[0]}"
		printc "${RESULT_COLOR} ....                       :: %s%{CLEAR}\n" "${REPORT_RESULT_MESSAGES[@]:1}"
	fi
}

show_test_output() {
	if [[ "$(stat_size "$2")" -gt 0 ]]; then
		printc "${RESULT_COLOR} .... %{CLEAR}%{HEADER}%s:%{CLEAR}\n" "$1"
		"${OUTPUT_PRINTER[@]}" "$2" | sed "s/^/$(printc "${RESULT_COLOR} .... %{SEPARATOR}|%{CLEAR}") /"
	fi
}

show_snapshot_diff() {
	printc "${RESULT_COLOR} .... %{CLEAR}%{HEADER}Snapshot Difference: %s%{CLEAR}\n" "$1"

	# shellcheck disable=SC2001
	sed "s/^/$(printc "${RESULT_COLOR} .... %{SEPARATOR}|%{CLEAR}") /" <<< "$2"
}

show_suite_totals() {
	if [[ "$TOTAL_ALL" -eq 0 ]]; then
		printc "${nl}%{WARNING}NO TESTS WERE RUN.%{CLEAR}\n"
		return
	fi

	printc "\nTotals:\n"
	printc "    PASS: %{RESULT_PASS}%d%{CLEAR} / %d\n" "$TOTAL_PASSED" "$TOTAL_ALL"
	printc "    PASS: %{RESULT_FAIL}%d%{CLEAR} / %d\n" "$TOTAL_FAILED" "$TOTAL_ALL"

	if [[ "$TOTAL_SKIPPED" -gt 0 ]]; then
		printc "    PASS: %{RESULT_SKIP}%d%{CLEAR} / %d\n" "$TOTAL_SKIPPED" "$TOTAL_ALL"
	fi

	# Print summaries.
	local nl='\n'
	if [[ "$TOTAL_IGNORED" -gt 0 ]]; then
		printc "${nl}THERE WERE %{WARNING}%d%{CLEAR} TESTS FILTERED OUT.\n" "$TOTAL_IGNORED"
		nl=''
	fi

	if [[ "$TOTAL_ALL" -eq "$TOTAL_PASSED" ]]; then
		printc "${nl}ALL TESTS PASSED.\n"
		nl=''
	fi
}

# ----------------------------------------------------------------------------------------------------------------------
# Overrides: Porcelain
# ----------------------------------------------------------------------------------------------------------------------
if [[ "$PORCELAIN" == true ]]; then
	:
	# TODO: Porcelain for test results.
fi

# ----------------------------------------------------------------------------------------------------------------------
# Init:
# ----------------------------------------------------------------------------------------------------------------------
OUTPUT_PRINTER=(cat)
if command -v bat &> /dev/null; then
	OUTPUT_PRINTER=(bat --paging=never --decorations=always --color=always --style=numbers --terminal-width="$(($(tput cols) - 8))")
fi

# ----------------------------------------------------------------------------------------------------------------------
# Main:
# ----------------------------------------------------------------------------------------------------------------------
RUN_TESTS=("${OPT_ARGV[@]}")
RUN_TESTPREFIX=''
if [[ "${#SUITE_FILES[@]}" -eq 1 ]]; then
	RUN_TESTPREFIX="$(suite_name "${SUITE_FILES[0]}"):"
fi

COMMAND_EXIT=0
for suite in "${SUITE_FILES[@]}"; do
	run_suite "$suite"
done

exit $COMMAND_EXIT
