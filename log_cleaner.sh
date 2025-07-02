#!/bin/bash
DIR=$1

if [ -z "$DIR" ]; then
   echo "Usage: $0 <./log_cleaner.sh>"
   exit 1
fi

find "$DIR" -name "*.log" -type f -mtime +7 -print -delete
