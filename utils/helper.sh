#!/bin/sh

FILE_OPT=""

if [ ! -z "$1" ]; then
    FILE_OPT="-a -f $1 "
fi

psql -d rulzurdb -U rulzurdb -h db $FILE_OPT

