# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Executes a new instance of the test runner.
# The test runner is specified by the `BEST_RUNNER` environment variable.
#
# Environment:
#
#     BEST_BASH [string]            -- The bash executable.
#     BEST_RUNNER [string]          -- The test runner script.
#
#     TEST_ENV_* [string]           -- An environment variable to pass to the test.
#     TEST_PWD [string]             -- The working direcory to run tests in.
#     TEST_LIB_DIR                  -- The test library directory. All scripts in this directory are loaded by the runner.
#     TEST_SHIM_PATH                -- The test shim path. Scripts in these directories can be included with `use_shim`.
#     SNAPSHOT_DIR                  -- The snapshot directory.
#
runner() {
	local env_passthrough=()
	local env_var
	while read -r env_var; do
		env_passthrough+=("${env_var}")
	done < <(env | grep '^TEST_ENV_' | sed 's/^TEST_ENV_//')

	({
		cd "${TEST_PWD}" && env -i \
			"${env_passthrough[@]}" \
			TEST_LIB_DIR="$TEST_LIB_DIR" \
			TEST_LIB_PREFIX="$TEST_LIB_PREFIX" \
			TEST_SHIM_PATH="$TEST_SHIM_PATH" \
			BEST_VERSION="$BEST_VERSION" \
			BEST_RUNNER_QUIET="${BEST_RUNNER_QUIET:-false}" \
			"${BEST_BASH}" "${BEST_RUNNER}" "$@"
	})
}

runner:load() {
	printf "LOAD %s\n" "$1" 1>&3
}

runner:run() {
	printf "TEST " 1>&3
	printf "%q " "$@" 1>&3
	printf "\n" 1>&3
}

runner:async_run() {
	printf "ASYNC_TEST " 1>&3
	printf "%q " "$@" 1>&3
	printf "\n" 1>&3
}

runner:async_wait_next() {
	printf "ASYNC_WAIT_NEXT\n" 1>&3
}

runner:async_wait_all() {
	printf "ASYNC_WAIT_ALL\n" 1>&3
}

runner:skip() {
	printf "ECHO IGNORE %s\n" "$1" 1>&3
}

runner:eval() {
	printf "EVAL %s\n" "$1" 1>&3
}

runner:test_setup() {
	printf "EVAL if type -t setup &>/dev/null; then setup; fi\n" 1>&3
}

runner:test_teardown() {
	printf "EVAL if type -t teardown &>/dev/null; then teardown; fi\n" 1>&3
}
