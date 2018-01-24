#!/bin/bash
# usage: this-script <verilog-file> <mem-size> <bin-file>

#append="initial \$readmemh(\"$3\", mem, 'h0);"
append="initial begin \$readmemh(\"$3\", mem, 'h0); \$readmemh(\"$3\", mem, 'h200000); end"

sed -i -e "/reg \[63:0\] mem \[0:`expr $2 / 8 - 1`\];/a $append" $1
