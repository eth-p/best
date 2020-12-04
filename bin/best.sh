#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
ROOT="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")" && pwd)")"
LIB="${ROOT}/lib"

source "${LIB}/manager.sh"
source "${LIB}/term.sh"
source "${LIB}/print.sh"
source "${LIB}/print_util.sh"
source "${LIB}/opt.sh"
source "${LIB}/compat.sh"

set -e -o pipefail

# ----------------------------------------------------------------------------------------------------------------------
# Environment:
# ----------------------------------------------------------------------------------------------------------------------
# Fixed:
export BEST_VERSION="1.0.0"
export BEST_RUNNER="${ROOT}/libexec/best-runner.sh"

# Configurable:
export BEST_BASH="${BEST_BASH:-${BASH}}"
export TEST_ENV_PATH="${TEST_ENV_PATH:-${ROOT}/share/shim-bin:${PATH}}"
export TEST_ENV_TMPDIR="${TEST_ENV_TMPDIR:-${TMPDIR}}"
export TEST_ENV_HOME="${TEST_ENV_HOME:-${HOME}}"
export TEST_ENV_TERM="${TEST_ENV_TERM:-xterm-color}"

export TEST_LIB_PREFIX="${TEST_LIB_PREFIX}"
export TEST_LIB_DIR="${TEST_LIB_DIR:-${LIB}/test}"
export TEST_SHIM_PATH="${TEST_SHIM_PATH:+${TEST_SHIM_PATH}:}${ROOT}/share/shim"
export TEST_DIR="${TEST_DIR:-${PWD}/test}"

export SNAPSHOT_DIR="${SNAPSHOT_DIR:-${PWD}/test-snapshots}"

if [[ -z "$TEST_PWD" ]]; then
	if [[ -d "${PWD}/test-data" ]]; then
		export TEST_PWD="${PWD}/test-data"
	else
		export TEST_PWD="$PWD"
	fi
fi

COLOR=false
if [[ -t 1 ]]; then
	COLOR=true
fi

CLEANUP_FILES=()
CLEANUP_DIRS=()
if [[ -z "$TEST_ENV_TMPDIR" ]]; then
	TEST_ENV_TMPDIR="$(mktemp -d)"
	CLEANUP_DIRS+=("$TEST_ENV_TMPDIR")
fi

# If the test directory isn't absolute, make it absolute.
if [[ "${TEST_DIR:0:1}" != "/" ]]; then
	TEST_DIR="${PWD}/${TEST_DIR}"
fi

# ----------------------------------------------------------------------------------------------------------------------
# Options:
# ----------------------------------------------------------------------------------------------------------------------
VERBOSE="${VERBOSE:-false}"
VERBOSE_EVERYTHING=false
PORCELAIN=false
DEBUG=false
STRICT=false
COMPACT=false
PARALLEL="auto"

SUBCOMMAND='run'

OPT_SUITES=()
OPT_ARGV=()
while shiftopt; do
	case "$OPT" in
		'--suite')             shiftval; OPT_SUITES+=("$OPT_VAL") ;;
		'--jobs'|'-j')         shiftval; PARALLEL="$OPT_VAL" ;;
		'--verbose')           VERBOSE=true ;;
		'--VERBOSE')           VERBOSE=true; VERBOSE_EVERYTHING=true ;;
		'--debug')             VERBOSE=true; DEBUG=true ;;
		'--strict')            STRICT=true ;;
		'--failed')            COMPACT=true ;;
		'--porcelain')         PORCELAIN="${OPT_VAL:-true}" ;;
		'--list')              SUBCOMMAND='list' ;;
		'--list-suites')       SUBCOMMAND='list-suites' ;;
		'--repl')              SUBCOMMAND='repl' ;;
		'--color')             COLOR=false printc_init true ;;
		'--no-color')          COLOR=false printc_init false ;;
		'--snapshot:generate') SNAPSHOT_GENERATE=true ;;
		'--snapshot:show')     SNAPSHOT_SHOW=true ;;
		'--snapshot:skip')     SNAPSHOT_SKIP=true ;;
		'--version')           SUBCOMMAND='version' ;;
		--)                    OPT_ARGV+=("$@"); break ;;
		-*)                    fatal_error "unknown option '%s'" "$OPT" ;;
		*)                     OPT_ARGV+=("$OPT") ;;
	esac
done

if [[ "$PORCELAIN" != false ]]; then
	printc_init false
fi

# ----------------------------------------------------------------------------------------------------------------------
# Init:
# ----------------------------------------------------------------------------------------------------------------------
SUITE_NAMES=()
SUITE_FILES=()

suite_files "${TEST_DIR}" "${OPT_SUITES[@]}" || exit $?

# ----------------------------------------------------------------------------------------------------------------------
# Main:
# ----------------------------------------------------------------------------------------------------------------------
# Execute
( source "${ROOT}/subcommand/${SUBCOMMAND}.sh" )
exit=$?

# Cleanup
for dir in "${CLEANUP_DIRS[@]}"; do
	rmdir "${dir}"
done

# Exit
exit $exit
