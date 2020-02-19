# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Prints the size of a file in bytes.
#
# Arguments:
#
#     $1  [string]  -- The file.
#
if gstat --printf="%s" "$0" &>/dev/null; then
	__best_stat_size() {
		gstat --printf="%s" "$1"
	}
elif stat --printf="%s" "$0" &>/dev/null; then
	__best_stat_size() {
		stat --printf="%s" "$1"
	}
elif stat -f%z "$0" &>/dev/null; then
	__best_stat_size() {
		stat -f%z "$1"
		printf "\n"
	}
else
	# TODO: Use python?
	__best_stat_size() {
		echo "1"
	}
fi
