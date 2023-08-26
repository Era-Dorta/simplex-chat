#!/bin/bash

# Run the first bot in the background.
# Without the redicted of stdin the bots crash trying to read from it.
# Create logs, see link below for how to do it
# https://superuser.com/a/993040
/usr/bin/simplex-bot-advanced < "/dev/stdin" &

# Same for the second bot
/usr/bin/simplex-anonymous-broadcast-bot < "/dev/stdin" &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
