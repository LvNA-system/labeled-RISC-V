# $1 - bin file
# $2 - bin text file
/bin/echo -e "\033[1;31mremember to create a link from the target bin file to 'emu.bin' under build/ before calling this script\033[0m"
hexdump -ve '2/ "%08x " "\n"' $1 | awk '{print $2$1}' > $2
