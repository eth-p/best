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
source "${LIB}/print.sh"
source "${LIB}/print_util.sh"
source "${LIB}/opt.sh"

set -e -o pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Environment:
# ----------------------------------------------------------------------------------------------------------------------
# Fixed:
export BEST_VERSION="1.0.0"
export BEST_RUNNER="${ROOT}/libexec/best-runner.sh"

# Configurable:
export BEST_BASH="${BEST_BASH:-${BASH}}"

export TEST_PWD="${TEST_PWD:-${PWD}}"
export TEST_ENV_PATH="${TEST_ENV_PATH:-${PATH}}"
export TEST_ENV_TMPDIR="${TEST_ENV_TMPDIR:-${TMPDIR}}"
export TEST_ENV_HOME="${TEST_ENV_HOME:-${HOME}}"

export TEST_LIB_DIR="${TEST_LIB_DIR:-${LIB}/test}"
export TEST_SHIM_DIR="${TEST_SHIM_DIR:-${LIB}/shim}"
export TEST_DIR="${PWD}/test"
# ----------------------------------------------------------------------------------------------------------------------
# Options:
# ----------------------------------------------------------------------------------------------------------------------
VERBOSE="${VERBOSE:-false}"
VERBOSE_EVERYTHING=false
PORCELAIN=false
DEBUG=false

SUBCOMMAND='run'

OPT_SUITES=()
OPT_ARGV=()
while shiftopt; do
	case "$OPT" in
		'--suite')             shiftval; OPT_SUITES+=("$OPT_VAL") ;;
		'--verbose')           VERBOSE=true ;;
		'--VERBOSE')           VERBOSE=true; VERBOSE_EVERYTHING=true ;;
		'--debug')             VERBOSE=true; DEBUG=true ;;
		'--porcelain')         PORCELAIN="${OPT_VAL:-true}" ;;
		'--list')              SUBCOMMAND='list' ;;
		'--color')             printc_init true ;;
		'--no-color')          printc_init false ;;
		'--snapshot:generate') SNAPSHOT_GENERATE=true ;;
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
source "${ROOT}/subcommand/${SUBCOMMAND}.sh"
