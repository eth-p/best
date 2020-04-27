# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

runner_report() {
	__best_runner_report "$@" || return $?
}

__best_runner_report() {
	RUNNER_CRASH=false
	RUNNER_CRASH_MESSAGES=()
	REPORT_RESULT=''
	REPORT_RESULT_MESSAGES=()
	REPORT_OUTPUT_STDOUT=''
	REPORT_OUTPUT_STDERR=''
	REPORT_SNAPSHOT_DIFF=''
	REPORT_EXIT_EXPECTED=0
	__REPORT_ABORT=false
	__REPORT_CHECK_SNAPSHOT_STDOUT=false
	__REPORT_CHECK_SNAPSHOT_STDERR=false
	__REPORT_RESULT_MSG=''
	__REPORT_RESULT_MSG_DATA=()

	# shellcheck disable=SC2181
	while read -r message data || return $?; do
		__best_runner_report:parse "$message" "$data"
		if [[ "$__REPORT_ABORT" = true || "$message" = "TEST_COMPLETE" ]]; then
			if [[ "$__REPORT_ABORT" = true ]]; then return 1; fi
			break
		fi
	done

	# Calculate the duration.
	REPORT_DURATION="$((REPORT_TIMESTAMP_FINISHED - REPORT_TIMESTAMP_STARTED))"

	# Calculate the result if not specified.
	if [[ -z "$REPORT_RESULT" ]]; then
		if [[ "$REPORT_EXIT" -eq "$REPORT_EXIT_EXPECTED" ]]; then
			REPORT_RESULT="PASS"
		else
			REPORT_RESULT='FAIL'
		fi
	fi

	# Validate the snapshots.
	if type __best_snapshot_validate &>/dev/null; then
		__best_snapshot_validate
	fi

	# Collect the messages.
	if [[ -n "$__REPORT_RESULT_MSG" ]]; then
		# shellcheck disable=SC2059
		REPORT_RESULT_MESSAGES+=("$(printf "$__REPORT_RESULT_MSG" "${__REPORT_RESULT_MSG_DATA[@]}")")
	fi

	# If it failed and there's no message, we can use the exit code.
	if [[ "$REPORT_RESULT" = "FAIL" && "${#REPORT_RESULT_MESSAGES[@]}" -eq 0 ]]; then
		if [[ "$REPORT_EXIT" = "127" && -f "$REPORT_OUTPUT_STDERR" ]]; then
			REPORT_RESULT_MESSAGES+=("$(tail -n1 "$REPORT_OUTPUT_STDERR")")
		else
			if [[ "$REPORT_EXIT_EXPECTED" -eq 0 ]]; then
				REPORT_RESULT_MESSAGES+=("Exited with code $REPORT_EXIT.")
			else
				REPORT_RESULT_MESSAGES+=("Exited with code $REPORT_EXIT, but expected code $REPORT_EXIT_EXPECTED.")
			fi
		fi
	fi

	return 0
}

__best_runner_report:parse() {
	__best_runner_report:do_parse "$@"
	return $?
}

__best_runner_report:do_parse() {
	if ! type -t "__best_runner_report:parse:$1" &>/dev/null; then
		return 1
	fi

	"__best_runner_report:parse:$1" "$2"
	return $?
}

__best_runner_report:parse:TEST() {
	REPORT_TEST="$1"
}

__best_runner_report:parse:TEST_COMPLETE() {
	REPORT_EXIT="$1"
}

__best_runner_report:parse:TEST_SHOULD_COMPLETE_WITH() {
	REPORT_EXIT_EXPECTED="$1"
}


__best_runner_report:parse:TEST_OUTPUT() {
	local type
	local file
	read -r type file <<< "$1"

	case "$type" in
		STDOUT) REPORT_OUTPUT_STDOUT="$file" ;;
		STDERR) REPORT_OUTPUT_STDERR="$file" ;;
	esac
}

__best_runner_report:parse:TEST_TIMESTAMP() {
	local type
	local timestamp
	read -r type timestamp <<< "$1"

	case "$type" in
		START) REPORT_TIMESTAMP_STARTED="$timestamp" ;;
		FINISH) REPORT_TIMESTAMP_FINISHED="$timestamp" ;;
	esac
}

__best_runner_report:parse:RESULT() {
	REPORT_RESULT="$1"
}

__best_runner_report:parse:RESULT_MSG() {
	if [[ -n "$__REPORT_RESULT_MSG" ]]; then
		# shellcheck disable=SC2059
		REPORT_RESULT_MESSAGES+=("$(printf "$__REPORT_RESULT_MSG" "${__REPORT_RESULT_MSG_DATA[@]}")")
	fi

	__REPORT_RESULT_MSG="$1"
	__REPORT_RESULT_MSG_DATA=()
}

__best_runner_report:parse:RESULT_MSG_DATA() {
	__REPORT_RESULT_MSG_DATA+=("$1")
}

__best_runner_report:parse:RUNNER_CRASH() {
	__REPORT_ABORT=true
	RUNNER_CRASH_MESSAGES+=("$1")
	RUNNER_CRASH=true
}
