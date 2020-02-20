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
# Main:
# ----------------------------------------------------------------------------------------------------------------------
exec 4<&0
{
	# Load the test suites.
	for suite in "${SUITE_FILES[@]}"; do
		runner:load "$suite"
	done

	# Load the user-friendly function overrides.
	runner:eval "printf 'Warning: Snapshot testing is disabled in the REPL.\n'"
	runner:load "${LIB}/print.sh"
	runner:load "${LIB}/runner_report.sh"
	runner:load "${LIB}/runner_repl.sh"
} 3>&1 | BEST_RUNNER_QUIET=true runner
