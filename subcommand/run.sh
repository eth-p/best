# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
source "${LIB}/runner.sh"
source "${LIB}/runner_report.sh"
source "${LIB}/stat.sh"
# ----------------------------------------------------------------------------------------------------------------------
if [[ "$SNAPSHOT_SKIP" != "true" ]]; then
	source "${LIB}/runner_snapshot.sh"
fi
# ----------------------------------------------------------------------------------------------------------------------
if [[ "${#SUITE_FILES[@]}" -eq 0 ]]; then
	fatal_error "No test suites found."
fi
# ----------------------------------------------------------------------------------------------------------------------
# Functions:
# ----------------------------------------------------------------------------------------------------------------------

run_test() {
	printvd "running: %s\n" "$TEST_NAME"

	# If we are running in serial, use the direct runner:run command.
	if [[ "$PARALLEL" -eq 1 ]]; then
		runner:run "$TEST_NAME"
		return $?
	fi

	# If we already have the maximum number of jobs, tell the runner to wait for one to complete.
	if [[ "$JOBS_INITIALIZED" -ge "$PARALLEL" ]]; then
		runner:async_wait_next
		((JOBS_INITIALIZED--)) || true
	fi

	# Tell the runenr to start a new async job.
	runner:async_run "$TEST_NAME"
	((JOBS_INITIALIZED++)) || true
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
		if [[ "$TEST_ID" = "${RUN_TESTPREFIX}${test}" || "$TEST_ID" = "${test}" ]]; then
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
	REPORT_PRINT_STARTED=false
	JOBS_INITIALIZED=0

	TOTAL_PASSED=0
	TOTAL_FAILED=0
	TOTAL_SKIPPED=0
	TOTAL_IGNORED=0

	if [[ "$PORCELAIN" = true ]]; then
		REPORT_PRINT_STARTED=true
		show_suite_name "$SUITE_NAME"
	fi

	# File descriptor table:
	#   FD6: intermediate for writing to STDOUT
	#   FD5: intermediate for writing to STDERR
	#   FD4: best command output
	#   FD3: best-runner command response
	# `run_suite` sends commands to a runner instance through FD4, and outputs messages through FD1.
	# The complex FD redirections below enable this to happen.
	exec 6>&1 5>&2
	if ! parse_suite_report < <({
		if runner < <({
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

				# Tell the runner to wait for the remaining jobs.
				if [[ "$PARALLEL" -ne 1 ]]; then
					runner:async_wait_all
				fi
			}

			runner:test_teardown
		}); then :; else
			# We have to use if-then-else because '!' will eat the exit code.
			printf "RUNNER_CRASH The runner crashed with exit code %d\n" "$?"
			return 1
		fi
	}); then
		# The runner crashed.
		# We shouldn't show any summaries.
		return 1
	fi

	TOTAL_ALL="$((TOTAL_PASSED + TOTAL_FAILED + TOTAL_SKIPPED))"

	# Add test counts to aggregated totals.
	AGGREGATED_TOTAL_PASSED="$((AGGREGATED_TOTAL_PASSED + TOTAL_PASSED))"
	AGGREGATED_TOTAL_FAILED="$((AGGREGATED_TOTAL_FAILED + TOTAL_FAILED))"
	AGGREGATED_TOTAL_SKIPPED="$((AGGREGATED_TOTAL_SKIPPED + TOTAL_SKIPPED))"
	AGGREGATED_TOTAL_IGNORED="$((AGGREGATED_TOTAL_IGNORED + TOTAL_IGNORED))"
	AGGREGATED_TOTAL_ALL="$((AGGREGATED_TOTAL_ALL + TOTAL_ALL))"

	# Show the suite totals.
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
				if "$STRICT"; then
					COMMAND_EXIT=2
					RESULT_COLOR="%{RESULT_FAIL}"
				fi
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

	if [[ "$RUNNER_CRASH" = true ]]; then
		printc "%{ERROR}FATAL ERROR: The test runner has crashed.%{CLEAR}\n"
		printc "%s\n" "${RUNNER_CRASH_MESSAGES[@]}"
		return 1
	fi
}

__best_runner_report:parse:IGNORE() {
	((TOTAL_IGNORED++)) || true
}

# ----------------------------------------------------------------------------------------------------------------------
# Functions: Reporting
# ----------------------------------------------------------------------------------------------------------------------

ensure_show_suite_name() {
	if ! "$REPORT_PRINT_STARTED"; then
		REPORT_PRINT_STARTED=true
		show_suite_name "$SUITE_NAME"
	fi
}

show_suite_name() {
	print_header "Test Suite: $1"
}

show_passed_test() {
	ensure_show_suite_name
	printc "[${RESULT_COLOR}PASS%{CLEAR}] %-20s%s\n" "$(test_name "$REPORT_TEST")" "$REPORT_DECORATION_STRING"
	show_test_outputs
}

show_failed_test() {
	ensure_show_suite_name
	printc "[${RESULT_COLOR}FAIL%{CLEAR}] %-20s" "$(test_name "$REPORT_TEST")"
	show_report_messages
	show_test_outputs
}

show_skipped_test() {
	ensure_show_suite_name
	printc "[${RESULT_COLOR}SKIP%{CLEAR}] %-20s" "$(test_name "$REPORT_TEST")"
	show_report_messages
	show_test_outputs
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

show_test_outputs() {
	if [[ "$REPORT_RESULT" = "FAIL" ]]; then
		if [[ "$SNAPSHOT_SHOW" = true || "$VERBOSE" = true ]] && [[ -n "$REPORT_SNAPSHOT_DIFF" ]]; then
			show_snapshot_diff "" "$REPORT_SNAPSHOT_DIFF"
		fi
	fi

	if [[ "$REPORT_RESULT" = "PASS" && "$VERBOSE_EVERYTHING" = true ]] \
		|| [[ "$REPORT_RESULT" != "PASS" && "$VERBOSE" = true ]]; then
		show_test_output "STDOUT" "$REPORT_OUTPUT_STDOUT"
		show_test_output "STDERR" "$REPORT_OUTPUT_STDERR"
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
	"${DIFF_PRINTER[@]}" <<< "$2" | sed "s/^/$(printc "${RESULT_COLOR} .... %{SEPARATOR}|%{CLEAR}") /"
}

show_suite_totals() {
	# If no tests were failed, and we're using --compact, don't print anything at all.
	if [[ "$TOTAL_FAILED" -eq 0 && "$COMPACT" = "true" ]]; then
		return
	fi

	# Print the suite name if it hasn't been printed already.
	if ! "$IS_FILTERED"; then
		ensure_show_suite_name
	fi

	# Print a warning if no tests were run.
	if [[ "$TOTAL_ALL" -eq 0 ]]; then
		SKIPPED_SUITES+=("$SUITE_NAME")
		if ! "$IS_FILTERED"; then
			printc "${nl}%{WARNING}NO TESTS WERE RUN.%{CLEAR}\n"
		fi
		return
	fi

	# Print the suite summary.
	printc "\nTotals:\n"
	printc "    PASS: %{RESULT_PASS}%d%{CLEAR} / %d\n" "$TOTAL_PASSED" "$TOTAL_ALL"
	printc "    FAIL: %{RESULT_FAIL}%d%{CLEAR} / %d\n" "$TOTAL_FAILED" "$TOTAL_ALL"

	if [[ "$TOTAL_SKIPPED" -gt 0 ]]; then
		local summary_color="%{RESULT_SKIP}"
		if "$STRICT"; then
			summary_color="%{RESULT_FAIL}"
		fi

		printc "    SKIP: ${summary_color}%d%{CLEAR} / %d\n" "$TOTAL_SKIPPED" "$TOTAL_ALL"
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

if [[ "$DEBUG" = true ]]; then
	__best_runner_report:parse() {
		printvd "ipc message: %s %s\n" "$1" "$2"
		__best_runner_report:do_parse "$@"
		return $?
	}
fi

show_aggregated_totals() {
	if ! "$IS_FILTERED"; then
		return
	fi
	
	if [[ $((AGGREGATED_TOTAL_PASSED + AGGREGATED_TOTAL_FAILED + AGGREGATED_TOTAL_SKIPPED)) -gt 0 ]]; then
		print_separator
	fi
	
	# If no tests were run, show a warning.
	if [[ "$AGGREGATED_TOTAL_ALL" -eq 0 ]]; then
		printc "%{WARNING}WARNING: NO TESTS WERE RUN.%{CLEAR}\n"
	fi
	
	# If any suites were filtered, show a count of all skipped test suites.
	if [[ "${#SKIPPED_SUITES[@]}" -gt 0 ]]; then
		printc "NOTE: THERE WERE %{WARNING}%d%{CLEAR} TEST SUITES FILTERED OUT." "${#SKIPPED_SUITES[@]}"
	fi
	
}

# ----------------------------------------------------------------------------------------------------------------------
# Overrides: Compact
# ----------------------------------------------------------------------------------------------------------------------
if "$COMPACT"; then
	show_passed_test() {
		:
	}

	if ! "$STRICT"; then
		show_skipped_test() {
			:
		}
	fi
	
	show_aggregated_totals() {
		if [[ "$AGGREGATED_TOTAL_IGNORED" -gt 0 ]]; then
			printc "THERE WERE %{WARNING}%d%{CLEAR} TESTS FILTERED OUT.\n" "$AGGREGATED_TOTAL_IGNORED"
		fi
		
		if [[ "$AGGREGATED_TOTAL_ALL" -eq 0 ]]; then
			printc "%{WARNING}NO TESTS WERE RUN.%{CLEAR}\n"
			return
		fi
	
		if [[ "$AGGREGATED_TOTAL_ALL" -eq "$AGGREGATED_TOTAL_PASSED" ]]; then
			printc "ALL %{RESULT_PASS}%d%{CLEAR} TESTS PASSED.\n" "$AGGREGATED_TOTAL_PASSED"
		fi
	}
fi

# ----------------------------------------------------------------------------------------------------------------------
# Overrides: Porcelain
# ----------------------------------------------------------------------------------------------------------------------
if [[ "$PORCELAIN" = true ]]; then
	_show_test() {
		printf "result %s %s" "${SUITE_NAME}:$(test_name "$REPORT_TEST")" "$1"
		printf " %s" "duration=${REPORT_DURATION}" "messages=${#REPORT_RESULT_MESSAGES[@]}"
		printf "\n"
	}

	show_suite_name() {
		printf "suite %s\n" "$1"
	}

	show_passed_test() {
		_show_test "pass"
		show_report_messages
		show_test_outputs
	}

	show_failed_test() {
		_show_test "fail"
		show_report_messages
		show_test_outputs
	}

	show_skipped_test() {
		_show_test "skip"
		show_report_messages
		show_test_outputs
	}

	show_report_messages() {
		local counter=-1
		local message
		for message in "${REPORT_RESULT_MESSAGES[@]}"; do
			((counter++)) || true
			printf "message %s %s\n" "$counter" "$message"
		done
	}

	show_test_output() {
		printf "output %s\n" "$1"
		sed $'s/^/\t/' < "$2"
	}

	show_snapshot_diff() {
		printf "output SNAPSHOT_DIFFERENCE\n"
		sed $'s/^/\t/' <<< "$2"
	}

	show_suite_totals() {
		:
	}
	
	show_aggregated_totals() {
		:
	}

fi

# ----------------------------------------------------------------------------------------------------------------------
# Init:
# ----------------------------------------------------------------------------------------------------------------------
AGGREGATED_TOTAL_PASSED=0
AGGREGATED_TOTAL_FAILED=0
AGGREGATED_TOTAL_IGNORED=0
AGGREGATED_TOTAL_ALL=0
SKIPPED_SUITES=()
IS_FILTERED=false

# Determine which commands to use for printing files.
#   If `bat` is installed, this will prefer using bat.
#   Otherwise, this will just use cat.
OUTPUT_PRINTER=(cat)
DIFF_PRINTER=("${OUTPUT_PRINTER[@]}")
if command -v bat &> /dev/null; then
	OUTPUT_PRINTER=(bat "--paging=never" "--decorations=always" "--style=numbers"
		"--color=$(if [[ "$COLOR" = true ]]; then echo "always"; else echo "never"; fi)"
		"--terminal-width=$(($(term_width) - 8))"
	)

	DIFF_PRINTER=("${OUTPUT_PRINTER[@]}" "--language=diff")
fi

# If -j is unspecified, determine the number of cores to use.
if [[ "$PARALLEL" = "auto" ]]; then
	PARALLEL="$(getconf _NPROCESSORS_ONLN 2>/dev/null || { echo "1"; exit 1; })" || printvd "unable to detect system core count"
	printvd "detected system core count as '%s'\n" "$PARALLEL"
	if ! [[ "$PARALLEL" -gt 0 ]] 2> /dev/null; then
		printvd "detected system core count is invalid. falling back to 1\n"
		PARALLEL=1 # If it can't be parsed as a number, fall back to one parallel test.
	fi
fi

# ----------------------------------------------------------------------------------------------------------------------
# Main:
# ----------------------------------------------------------------------------------------------------------------------
RUN_TESTS=("${OPT_ARGV[@]}")
RUN_TESTPREFIX=''
if [[ "${#SUITE_FILES[@]}" -eq 1 ]]; then
	RUN_TESTPREFIX="$(suite_name "${SUITE_FILES[0]}"):"
fi

if [[ "${#RUN_TESTS[@]}" -gt 0 ]]; then
	IS_FILTERED=true	
fi

COMMAND_EXIT=0
for suite in "${SUITE_FILES[@]}"; do
	run_suite "$suite"
done

show_aggregated_totals
exit $COMMAND_EXIT
