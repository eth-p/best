# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Preprocesses a test library.
# This will replace function prefixes.
#
# Input:
#     The library script.
#
# Output:
#     The processed library script.
#
# Replacements:
#     :PREFIX:    ->  {{$TEST_LIB_PREFIX}}
__best_lib_preprocess() {
	sed 's/:PREFIX:/'"${TEST_LIB_PREFIX}"'/'
}
