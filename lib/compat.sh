# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

incompatible() {
	local command="$1"
	local using="$2"
	local supported="$3"

	fatal_error "Your current environment is incompatible.\nThe '%s' tool was identified as '%s', but '%s' is required." \
		"$command" "$using" "$supported"

	exit 5
}

# ----------------------------------------------------------------------------------------------------------------------
# Check that awk is not mawk.
if command awk -W version 2>&1 <&- | grep 'mawk' &> /dev/null; then
	incompatible 'awk' 'mawk' 'GNU or BSD awk'
fi
