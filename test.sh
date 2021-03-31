#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${HERE}/lib/opt.sh"

# ----------------------------------------------------------------------------------------------------------------------
# Test Files:
# ----------------------------------------------------------------------------------------------------------------------
export TEST_DIR="${HERE}/tests/${TEST_DIR:-test}"
export TEST_PWD="${HERE}/tests/${TEST_PWD:-data}"
export TEST_SHIM_PATH="${HERE}/tests/${TEST_SHIM_PATH:-shim}"
export SNAPSHOT_DIR="${HERE}/tests/${SNAPSHOT_DIR:-test-snapshots}"

# ----------------------------------------------------------------------------------------------------------------------
# Test Environment:
# ----------------------------------------------------------------------------------------------------------------------
export TEST_ENV_LIB="${HERE}/lib"
export TEST_ENV_TEST_HELPERS="${HERE}/tests/helpers"
export TEST_ENV_PATH="${PATH}"
export TEST_ENV_HOME="${HERE}/tests/data"
export TEST_ENV_BEST_EXECUTABLE="${HERE}/bin/best.sh"
export TEST_ENV_TEST_DIR="${TEST_PWD}/meta-tests"

# ----------------------------------------------------------------------------------------------------------------------
# Options:
# ----------------------------------------------------------------------------------------------------------------------
OPT_ARGV=()
SHIFTOPT_SHORT_OPTIONS="PASS"
while shiftopt; do
	case "$OPT" in
	-S|--system-path-only) export PATH="/bin:/sbin:/usr/bin:/usr/sbin"; TEST_ENV_PATH="/bin:/sbin:/usr/bin:/usr/sbin" ;;
	*)
		if [[ "$OPT_VAL" ]]; then OPT_ARGV+=("${OPT}=${OPT_VAL}")
		                     else OPT_ARGV+=("$OPT")
		fi ;;
	esac
done

# ----------------------------------------------------------------------------------------------------------------------
# Initialize:
# ----------------------------------------------------------------------------------------------------------------------
if ! [[ -d "${HERE}/tests/test" ]]; then
	git submodule init 'tests'
	git submodule update
fi

# ----------------------------------------------------------------------------------------------------------------------
# Main:
# ----------------------------------------------------------------------------------------------------------------------
cd "$HERE" || exit $?
"${BEST:-bin/best.sh}" --verbose --strict --snapshot:show "${OPT_ARGV[@]}"
exit $?
