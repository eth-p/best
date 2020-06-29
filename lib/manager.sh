# -----------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# -----------------------------------------------------------------------------

# Prints a newline-delimited list of tests in a test suite.
#
# Arguments:
#     $1  [string] -- The test suite file.
#
suite_test_names() {
	env -i "${BEST_BASH}" -c "source $(printf '%q' "$1"); declare -F" \
		| grep '^declare -f test[A-Z:_].*$' \
		| sed 's/^declare -f //'
}

# Parses a test file and prints back the test information:
#
# Arguments:
#     $1  [string] -- The test suite file.
#
# Output:
#
#     TESTS_NAME[i]=[string]
#     TESTS_DESCRIPTION[i]=["string"]
#     TESTS_SNAPSHOT[i]=["stdout"|"stderr"]
#     ...
#     TESTS=1
#
suite_tests_parse() {
	env -i "${BEST_BASH}" -c "source $(printf '%q' "$1"); declare -f" \
		| awk '
			BEGIN {
				n=-1
				p=0
				print "TESTS_NAME=()"
				print "TESTS_DESCRIPTION=()"
				print "TESTS_SNAPSHOT=()"
			};
			END { print "TESTS="(n+1) };
			$2 == "()" { p=0 };
			$2 == "()" && /^test([A-Z:_])/ { p=1; n++; print "TESTS_NAME["n"]=\""$1"\"" };
			/^(    |\t)('"${TEST_LIB_PREFIX}"')(description|snapshot).*/ {
				if (p) {
					var=substr(toupper($1), 1+'"${#TEST_LIB_PREFIX}"');
					$1="";
					val=$0;

					while(match(val, "^[[:space:]]")) { val=substr(val, 2) }
					while(match(val, ";$")) { val=substr(val, 1, length(val)-1) }
					if (match(val, "^[\"'\'']")) { val=substr(val, 2) }
					if (match(val, "[\"'\'']$")) { val=substr(val, 1, length(val)-1) }

					# Bash escape.
					gsub(/\\/, "\\\\", val)
					gsub(/\$/, "\\$", val)
					gsub(/"/, "\\\"", val)
					print "TESTS_"var"["n"]=\""val"\""
				}
			};
		'
}

# Allows for while-loop reading of a test file.
#
# Example:
#
#     suite_tests load "tests.sh"
#     while suite_tests next; do
#         echo "$TEST_NAME"
#     done
#
# shellcheck disable=SC2153
# shellcheck disable=SC2034
suite_tests() {
	case "$1" in
		load) TESTI=0; eval "$(suite_tests_parse "$2")";;
		next) {
			if [[ "$TESTI" -ge "$TESTS" ]]; then return 1; fi
			TEST_NAME="${TESTS_NAME[$TESTI]}"
			TEST_DESCRIPTION="${TESTS_DESCRIPTION[$TESTI]}"
			TEST_SNAPSHOT="${TESTS_SNAPSHOT[$TESTI]}"
			((TESTI++)) || true
			return 0
		};
	esac
}

# Prints the friendly name of a test suite.
#
# Arguments:
#     $0  [string] -- The test suite file.
#
suite_name() {
	basename "$1" .sh
}

# Searches for suite files in a specified path.
#
# This will find the test suite files corresponding to the names given.
# If no test suite names are given, it will find all test suites inside the test suite directory.
#
# Arguments:
#     $1  [string] -- The test suite directory.
#     ... [string] -- The test suites to search for.
#
# Output:
#     Appends to $SUITE_NAMES and $SUITE_FILES arrays.
#
# shellcheck disable=SC2120
suite_files() {
	shopt -s nullglob

	local dir="$1"
	local file
	local error=false

	# Search for the suites.
	if [[ "$#" -eq 1 ]]; then
		for file in "${dir}"/*.sh; do
			printvd "%{DEBUG}Using suite: %s%{CLEAR}\n" "$file"
			SUITE_NAMES+=("$(suite_name "$file")")
			SUITE_FILES+=("${file}")
		done
	else
		for name in "${@:2}"; do
			# Search order:
			# - $name
			# - $dir/$name.sh
			# - $dir/$name
			if [[ -f "${name}" ]]; then
				file="${name}"
			elif [[ -f "${dir}/${name}.sh" ]]; then
				file="${dir}/${name}.sh"
			elif [[ -f "${dir}/${name}" ]]; then
				file="${dir}/${name}"
			else
				printc "%{ERROR}%s: cannot find test suite '%s'%{CLEAR}\n" "$PROGRAM" "$name"
				error=true
				continue
			fi

			printvd "%{DEBUG}Using suite: %s%{CLEAR}\n" "$file"
			SUITE_NAMES+=("$(suite_name "$file")")
			SUITE_FILES+=("${file}")
		done
	fi

	# Return.
	shopt -u nullglob
	[[ "$error" = false ]]
	return $?
}

# Prints the friendly name of a test function.
#
# Arguments:
#     $1  [string] -- The test function.
#
test_name() {
	local test="$1"
	case "$1" in
		"test::"*)         printf "%s\n" "${test:6}"; return ;;
		"test_"*|"test:"*) printf "%s\n" "${test:5}"; return ;;
		"test"*)           printf "%s\n" "${test:4}"; return ;;
		*)                 printf "%s\n" "$1"; return ;;
	esac
}
