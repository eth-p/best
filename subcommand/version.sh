# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------

printf "best %s\n" "$(cat "${ROOT}/version.txt")"
printf "https://github.com/eth-p/best/\n"

if [[ -f "${ROOT}/LICENSE.md" ]]; then
	printf "\n"
	cat "${ROOT}/LICENSE.md"	
else
	printf "Copyright (C) %s-%s eth-p\n" 2019 2021
	printf "MIT License"
fi
