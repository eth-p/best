# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
source "${LIB}/test_runner/stat.sh"

# Prints the size of a file in bytes.
#
# Arguments:
#
#     $1  [string]  -- The file.
#
stat_size() {
	__best_stat_size "$@"
	return $?
}
