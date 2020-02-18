# -----------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# -----------------------------------------------------------------------------

# Executes a new instance of the test runner.
# The test runner is specified by the `BEST_RUNNER` environment variable.
#
#
#
runner() {
	({
		cd "${TEST_PWD}" && env -i \
			HOME="$TEST_HOME" \
			PATH="$TEST_PATH" \
			TMPDIR="$TEST_TEMP" \
			BEST_TEST_LIB="$BEST_TEST_LIB" \
			BEST_SHIM_DIR="$TEST_SHIM_DIR" \
			BEST_VERSION="$BEST_VERSION" \
			"${BEST_BASH}" "${BEST_RUNNER}"
	})
}

runner:load() {
	printf "LOAD %s\n" "$1" 1>&3
}

runner:run() {
	printf "EXEC_TEST " 1>&3
	printf "%q " "$@" 1>&3
	printf "\n" 1>&3
}

runner:skip() {
	printf "SKIP %s\n" "$1" 1>&3
}

runner:test_setup() {
	printf "EXEC setup\n" 1>&3
}

runner:test_teardown() {
	printf "EXEC teardown\n" 1>&3
}
