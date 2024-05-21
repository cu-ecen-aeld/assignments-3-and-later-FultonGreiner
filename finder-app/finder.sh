#!/bin/sh

readonly ARGC=$#
readonly FILESDIR=$1
readonly SEARCHSTR=$2

if [[ $ARGC -eq 0 ]]; then
    echo "Missing filesdir and searchstr arguments!" >&2
    exit 1
elif [[ $ARGC -eq 1 ]]; then
    echo "Missing searchstr argument!" >&2
    exit 1
fi

if [ ! -d $FILESDIR ]; then
    echo "Directory '$FILESDIR' does not exist!" >&2
    exit 1
fi

readonly NUM_FILES=$(find $FILESDIR -type f | wc -l)
readonly NUM_MATCHES=$(grep -roh $SEARCHSTR $FILESDIR | wc -w)

echo "The number of files are $NUM_FILES and the number of matching lines are $NUM_MATCHES."
