#!/bin/bash

FILE_PATH=$(find / -name conf.d 2>/dev/null | head -n 1)
echo "$FILE_PATH" | sed 's/\//./g'
