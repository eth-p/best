# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Determines the path for a snapshot file.
#
# Arguments:
#
#     $1  [string] -- The snapshot type.
#
# Environment:
#
#     REPORT_TEST [string]  -- The test function.
#     REPORT_SUITE [string] -- The test suite.
#
snapshot_file() {
	__best_snapshot_file "$@"
	return $?
}

__best_snapshot_file() {
	local id="${REPORT_TEST//[^A-Za-z_\.\-]/_}"
	if [[ "$REPORT_SUITE" ]]; then
		local suite="$(basename "$REPORT_SUITE" .sh)"
		id="${suite//[^A-Za-z_\-]/_}/${id}";
	fi

	printf "%s/%s.%s.snapshot\n" "$SNAPSHOT_DIR" "$id" "$(tr '[:upper:]' '[:lower:]' <<< "$1")"
}

if ! type __best_snapshot_validate &>/dev/null; then
	__best_snapshot_validate() {
		if [[ "$REPORT_RESULT" != "PASS" ]]; then return; fi

		if [[ "$__REPORT_CHECK_SNAPSHOT_STDOUT" = true ]]; then
			__best_snapshot_validate_file "STDOUT" "$REPORT_OUTPUT_STDOUT" || return
		fi

		if [[ "$__REPORT_CHECK_SNAPSHOT_STDERR" = true ]]; then
			__best_snapshot_validate_file "STDERR" "$REPORT_OUTPUT_STDERR" || return
		fi
	}

	__best_snapshot_validate_file() {
		local file="$(__best_snapshot_file "$1")"

		# Check that the output was captured.
		if ! [[ -f "$2" ]]; then
			REPORT_RESULT="FAIL"
			REPORT_RESULT_MESSAGES+=("No $1 captured.")
			return 1
		fi

		if [[ "$SNAPSHOT_GENERATE" ]]; then
			mkdir -p "$(dirname "$file")"
			cp "$2" "$file"
		fi

		# Check that a snapshot exists.
		if ! [[ -f "$file" ]]; then
			REPORT_RESULT="FAIL"
			REPORT_RESULT_MESSAGES+=("No $1 snapshot.")
			return 1
		fi

		# Check the snapshot.
		if ! REPORT_SNAPSHOT_DIFF="$(diff "$file" "$2")"; then
			REPORT_RESULT="FAIL"
			REPORT_RESULT_MESSAGES+=("Mismatched $1 snapshot.")
			return 1
		fi
	}
fi

__best_runner_report:parse:SNAPSHOT() {
	case "$1" in
		STDOUT) __REPORT_CHECK_SNAPSHOT_STDOUT="true" ;;
		STDERR) __REPORT_CHECK_SNAPSHOT_STDERR="true" ;;
	esac
}
