#!/bin/sh

readonly ARGC=$#
readonly WRITEFILE=$1
readonly WRITESTR=$2

if [[ $ARGC -eq 0 ]]; then
    echo "Missing writefile and writestr arguments!" >&2
    exit 1
elif [[ $ARGC -eq 1 ]]; then
    echo "Missing writestr argument!" >&2
    exit 1
fi

readonly WRITEDIR=$(dirname $WRITEFILE)

mkdir -p $WRITEDIR
if [ $? -ne 0 ] ; then
    echo "Failed to create directory '$WRITEDIR'!" >&2
    exit 1
fi

echo $WRITESTR > $WRITEFILE
if [ $? -ne 0 ] ; then
    echo "Failed to create file '$WRITEFILE'!" >&2
    exit 1
fi
