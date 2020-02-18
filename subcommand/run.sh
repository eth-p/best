# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
source "${LIB}/runner.sh"
# ----------------------------------------------------------------------------------------------------------------------
if [[ "${#SUITE_FILES[@]}" -eq 0 ]]; then
	fatal_error "No test suites found."
fi
# ----------------------------------------------------------------------------------------------------------------------
# Functions:
# ----------------------------------------------------------------------------------------------------------------------
show_suite_name() {
	print_header "Test Suite: $1"
}

run_test() {
	printvd "running: %s\n" "$TEST_NAME"
	runner:run "$TEST_NAME"
}

run_test_maybe() {
	local skip=true

	if [[ "${#RUN_TESTS[@]}" -eq 0 ]]; then
		# If all tests are being run, we don't have to filter it.
		skip=false
	else
		# If a subset of tests are run, we have to check if the test ID is within this subset.
		local key
		for key in "${!RUN_TESTS[@]}"; do
			local test="${RUN_TESTS[$key]}"
			if [[ "$TEST_ID" = "${RUN_TESTPREFIX}${test}" || "$TEST_ID" = "${test}" ]]; then
				skip=false
				RUN_TESTS=("${RUN_TESTS[@]/$key}")
				break
			fi
		done
	fi

	# Run the test?
	if [[ "$skip" != true ]]; then
		run_test
	else
		runner:skip "$TEST_NAME"
	fi
}

run_suite() {
	# Set suite variables.
	SUITE_FILE="$1"
	SUITE_NAME="$(suite_name "$SUITE_FILE")"

	show_suite_name "$SUITE_NAME"

	# Run each test.
	suite_tests load "$suite"
	while suite_tests next; do
		TEST_ID="${SUITE_NAME}:$(test_name "${TEST_NAME}")"
		run_test_maybe
	done
}

runner_for_suite() {
	# File descriptor table:
	#   FD6: intermediate for writing to STDOUT
	#   FD5: intermediate for writing to STDERR
	#   FD4: best command output
	#   FD3: best-runner command response
	# `run_suite` sends commands to a runner instance through FD4, and outputs messages through FD1.
	# The complex FD redirections below enable this to happen.
	exec 6>&1 5>&2
	report < <(runner < <(exec 3>&1 1>&6; runner:load "$1" runner:test_setup; run_suite "$1"; runner:test_teardown))
}


# ----------------------------------------------------------------------------------------------------------------------
# Functions: Report
# ----------------------------------------------------------------------------------------------------------------------
__report_interpreter_reset() {
	RESULT_TEST=''
	RESULT_FD1=''
	RESULT_FD2=''
	RESULT_EXIT=''
	RESULT_STATUS=''
	RESULT_TIMER_BEGIN=''
	RESULT_TIMER_END=''
	RESULT_MESSAGE=''
	RESULT_MESSAGE_DATA=()
}

report() {
	# Set the totals.
	TOTAL_PASS=0
	TOTAL_FAIL=0
	TOTAL_SKIP=0

	# Parse the runner's response text.
	local command
	local data
	while read -r command data; do
		printvd "runner response: %s %s\n" "$command" "$data"
		case "$command" in
			EXEC) {
				report_test
				__report_interpreter_reset
				RESULT_TEST="$data"
			} ;;

			FD1)           RESULT_FD1="$data" ;;
			FD2)           RESULT_FD2="$data" ;;
			EXIT)          RESULT_EXIT="$data" ;;
			FAIL)          RESULT_STATUS="FAIL" ;;
			SKIP)          RESULT_STATUS="SKIP" ;;
			TIMER_BEGIN)   RESULT_TIMER_BEGIN="$data" ;;
			TIMER_END)     RESULT_TIMER_END="$data" ;;
			FAIL_MSG)      RESULT_MESSAGE="$data" ;;
			FAIL_MSG_DATA) RESULT_MESSAGE_DATA+=("$data") ;;
		esac
	done

	report_test

	# Print the results.
	TOTAL_ALL="$((TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP))"
	if [[ "$TOTAL_ALL" -ge 0 ]]; then
		printc "\nTotal Passed:  %{RESULT_SUCCESS}%d%{CLEAR} / %d\n" "${TOTAL_PASS}" "${TOTAL_ALL}"
		printc "Total Skipped: %{RESULT_SKIPPED}%d%{CLEAR} / %d\n" "${TOTAL_SKIP}" "${TOTAL_ALL}"
		printc "Total Failed:  %{RESULT_FAILURE}%d%{CLEAR} / %d\n" "${TOTAL_FAIL}" "${TOTAL_ALL}"
	fi

	if [[ "$TOTAL_FAIL" ]]; then
		COMMAND_EXIT=1
	fi
}

verify_test() {
	if [[ -z "$RESULT_STATUS" ]]; then
		if [[ "$RESULT_EXIT" -eq 0 ]]; then
			RESULT_STATUS='SUCCESS'
		else
			RESULT_STATUS='FAIL'
		fi
	fi

	if [[ "$RESULT_TIMER_BEGIN" -ne 0 ]]; then
		RESULT_TIME_DURATION="$((RESULT_TIMER_END - RESULT_TIMER_BEGIN)) ms"
	else
		RESULT_TIME_DURATION=""
	fi
}

report_test() {
	if [[ -n "$RESULT_TEST" ]]; then
		verify_test

		case "$RESULT_STATUS" in
			SUCCESS) ((TOTAL_PASS++)) || true; report_test_success ;;
			SKIP)    ((TOTAL_SKIP++)) || true; report_test_skipped ;;
			FAIL|*)  ((TOTAL_FAIL++)) || true; report_test_failure ;;
		esac

		if [[ -n "$RESULT_FD1" ]]; then
			rm "$RESULT_FD1"
		fi

		if [[ -n "$RESULT_FD2" ]]; then
			rm "$RESULT_FD2"
		fi
	fi
}

report_test_success() {
	printc "[%{RESULT_SUCCESS}PASS%{CLEAR}] %-16s :: %s%{CLEAR}\n" "$(test_name "$RESULT_TEST")" "$RESULT_TIME_DURATION"
}

report_test_skipped() {
	printc "[%{RESULT_SKIPPED}SKIP%{CLEAR}] %s%{CLEAR}\n" "$(test_name "$RESULT_TEST")"
}

report_test_failure() {
	# Print the report line.
	printc "[%{RESULT_FAILURE}FAIL%{CLEAR}] %-16s ::%{ERROR} " "$(test_name "$RESULT_TEST")"
	if [[ -n "$RESULT_MESSAGE" ]]; then
		# shellcheck disable=SC2059
		printf "$RESULT_MESSAGE" "${RESULT_MESSAGE_DATA[@]}"
	else
		printf "Exited with code %d." "$RESULT_EXIT"
	fi
	printc "%{CLEAR}\n"

	# Print the STDOUT/STDERR if VERBOSE is enabled.
	if [[ "$VERBOSE" = true ]]; then
		cat "$RESULT_FD1"
		cat "$RESULT_FD2"
	fi
}

# ----------------------------------------------------------------------------------------------------------------------
# Overrides: Porcelain
# ----------------------------------------------------------------------------------------------------------------------
if [[ "$PORCELAIN" = true ]]; then
	:
	# TODO: Porcelain for test results.
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
	runner_for_suite "$suite"
done

exit $COMMAND_EXIT
