#!/bin/sh
set -x -e

CMD="psql -U rulzurdb -h db"


case "$1" in
"create_db")
    eval "$CMD -d template1 -c 'CREATE DATABASE rulzurdb'"
    eval "$CMD -d template1 -c 'CREATE DATABASE rulzurdb_test'"

    eval "$CMD -d rulzurdb -a -f utils/create_tables.sql"
    eval "$CMD -d rulzurdb_test -a -f utils/create_tables.sql"

    eval "$CMD -d rulzurdb -a -f utils/init.sql"
    ;;
"reinitialize")
    eval "$CMD -d rulzurdb -a -f utils/clean_all.sql"
    eval "$CMD -d rulzurdb -a -f utils/init.sql"
    ;;
"full_reinitialize")
    eval "$CMD -d template1 -c 'DROP DATABASE IF EXISTS rulzurdb'"
    eval "$CMD -d template1 -c 'DROP DATABASE IF EXISTS rulzurdb_test'"
    exec $(readlink -f "$0") create_db
    ;;
*)
    FILE_OPT=""

    if [ ! -z "$1" ]; then
        FILE_OPT="-a -f $1"
    fi
    eval "$CMD -d rulzurdb $FILE_OPT"
    ;;
esac
