#!/bin/bash

DIR=$1
LATEST_FILE=$(ls -t "$DIR" | head -n1)
cp "$DIR/$LATEST_FILE" latest_copy.txt
tr -s '[:space:]' '\n' < latest_copy.txt | sort | uniq -c | sort -nr | head -n1
