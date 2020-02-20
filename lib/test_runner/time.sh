# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Prints the current time in milliseconds.
#
# This will attempt to use the GNU date command to get the time, but will fallback to the slower Python implementation.
# If you're on a non-GNU system (or using Busybox), tests can run a fair bit faster if you install GNU coreutils.
#
if command -v gdate &>/dev/null && ! [[ "$(gdate +'%s%3N' 2>/dev/null)" =~ N$ ]]; then
	__best_time() {
		gdate +'%s%3N'
	}
elif ! [[ "$(date +'%s%3N' 2>/dev/null)" =~ N$ ]]; then
	__best_time() {
		date +'%s%3N'
	}
elif command -v python &>/dev/null; then
	__best_time() {
		# This is the slowest thing in test execution overhead.
		python -c 'import time; import math; print int(math.floor(time.time() * 1000))'
	}
else
	__best_time() {
		printf "0\n"
	}
fi
