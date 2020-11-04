#!/usr/bin/env bash

if ! which python3
then
	echo python3 not found, please input password to allow apt-get to go forward
	sudo apt-get install -y python3
else
	echo python3 installed
fi

if ! which pip3
then
	echo python3-pip not found, please input password to allow apt-get to go forward
        sudo apt-get install -y python3-pip
else
	echo python-pip installed
fi

if ! python3 -c 'import pyfdt' 2> /dev/null
then
	echo pyfdt package not found, please input password to allow pip3 to go forward
        sudo -H pip3 install pyfdt
else
	echo python module pyfdt installed
fi
