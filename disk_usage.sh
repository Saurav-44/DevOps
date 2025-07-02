#!/bin/bash
USAGE=$(df / | grep / | awk '{print $5}' | sed 's/%//')

if [ "$USAGE" -gt 80 ]; then
   echo "ALERT: Disk usage of / is above 80% (Currently ${USAGE}%)"
else
   echo "Disk usage is under control: ${USAGE}%"
fi
