#!/bin/sh

FILE_OPT=""

if [ ! -z "$1" ]; then
    FILE_OPT="-f $1 "
fi

psql -d rulzurdb -U rulzurdb -h rulzurdb $FILE_OPT

