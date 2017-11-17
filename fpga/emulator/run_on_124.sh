#!/bin/bash
user="lzg"
host="10.30.6.124"

# first, check arguments
if [ $# -lt 2 ]
  then
	echo "Args: emulator file, mem_init_txt(eg: bin.txt) file and v(verbose or not, optional)."
	exit
fi

emu=$1
bin_txt=$2

# set password
ssh_pass="sshpass -f .passwd_124"

# copy this two files two your home directory on 124
# be careful, this will override file: emu and bin.txt
$ssh_pass scp $emu $user@$host:~/emu
$ssh_pass scp $bin_txt $user@$host:~/bin.txt

# run emu on 124
# this will override file: emu.log, serial1000 and serial2000
$ssh_pass scp $bin_txt $user@$host:~/bin.txt

# pass the v(verbose flag) to the remote shell script
$ssh_pass ssh -t $user@$host "bash run_emu.sh $3"
