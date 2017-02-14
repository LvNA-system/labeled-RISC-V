hexdump -ve '/8 "%016x " "\n"' $1 > bin.txt
ls -l $1 | awk '{print $5}' | xargs printf '%x\n' > bin.size
