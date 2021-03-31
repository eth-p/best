# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
if [[ "${#SUITE_FILES[@]}" -eq 0 ]]; then
	fatal_error "No test suites found."
fi

# ----------------------------------------------------------------------------------------------------------------------
# Functions:
# ----------------------------------------------------------------------------------------------------------------------
show_test() {
	printc "%{SUITE_NAME}%s:%{TEST_NAME}%s" "$SUITE_NAME" "$(test_name "$TEST_NAME")"
	if [[ -n "$TEST_DESCRIPTION" ]]; then printc "%{TEST_DESCRIPTION}  -- %s" "$TEST_DESCRIPTION"; fi
	printc "%{CLEAR}\n"
}

# shellcheck disable=SC2155
show_suite() {
	local suite="$1"
	local name="$(suite_name "$suite")"
	SUITE_NAME="${name}"

	# Print each test.
	suite_tests load "$suite"
	while suite_tests next; do
		show_test
	done

	# Print any warnings.
	if [[ "$TESTS" -eq 0 ]]; then
		print_warning "no tests in '%s'" "$name"
	fi
}

# ----------------------------------------------------------------------------------------------------------------------
# Overrides: Porcelain
# ----------------------------------------------------------------------------------------------------------------------
case "$PORCELAIN" in
	true) {
		show_test() {
			printf "test %s:%s\n" "$SUITE_NAME" "$(test_name "$TEST_NAME")"
			printf "test_suite %s\n" "$SUITE_NAME"
			printf "test_name %s\n" "$TEST_NAME"
			printf "test_description %s\n" "$TEST_DESCRIPTION"
		}
	} ;;

	false) : ;;
	*) fatal_error 'unknown porcelain format: %s' "$PORCELAIN" ;;
esac

# ----------------------------------------------------------------------------------------------------------------------
# Main:
# ----------------------------------------------------------------------------------------------------------------------
print_header "Tests:"
for suite in "${SUITE_FILES[@]}"; do
	show_suite "$suite"
done
