# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

# Enables snapshot testing.
# This will compare the STDOUT/STDERR of the test with a stored snapshot.
#
# Arguments:
#     $1  ["stdout"]    -- The standard output snapshot will be compared.
#     $1  ["stderr"]    -- The standard error snapshot will be compared.
#
# Example:
#
#     snapshot stdout
#
:PREFIX:snapshot() {
	__best_ipc_send "SNAPSHOT" "$(tr '[:lower:]' '[:upper:]' <<< "$1")"
}
