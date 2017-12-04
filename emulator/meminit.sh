#!/bin/bash
# usage: this-script <verilog-file> <mem-size> <bin-file>

append="initial \$readmemh(\"$3\", mem, 0);"

sed -i -e "/reg \[63:0\] mem \[0:`expr $2 / 8 - 1`\];/a $append" $1
