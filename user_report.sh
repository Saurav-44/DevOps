#!/bin/bash




USER=$(last -w | head -n 1 | awk '{print $1}')

echo "Last logged-in user: $USER"




find /home -user "$USER" 2>/dev/null




last -F "$USER" | awk '/-/ { split($NF, t, "-"); split(t[1], start, ":"); split(t[2], end, ":"); login = (end[1]*60 + end[2]) - (start[1]*60 + start[2]); if (login > 0) total += login } END { print "Total login time (minutes):", total ? total : "Not available" }'
