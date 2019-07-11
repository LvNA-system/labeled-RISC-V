#!/usr/bin/env bash

if ! which python
then
	echo python not found, please input password to allow apt-get to go forward
	sudo apt-get install -y python
else
	echo python installed
fi

if ! which pip
then
	echo python-pip not found, please input password to allow apt-get to go forward
        sudo apt-get install -y python-pip
else
	echo python-pip installed
fi

if ! python -c 'import pyfdt' 2> /dev/null
then
        sudo -H pip install pyfdt
else
	echo python module pyfdt installed
fi
