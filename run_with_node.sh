#!/bin/bash
# input params
NODE_BINARY="$1"
COMMAND="$2"
NODE_LOG="$3"
#creating file to store pid
pidfile=$(mktemp)
# staring node
$NODE_BINARY --dev &> "$NODE_LOG" &
echo $! > "$pidfile"
# waiting for start
until nc -z localhost 9933; do sleep 1; done
# running command
eval $COMMAND
status=$?
# stopping node & cleanup
kill $(cat "$pidfile")
rm -f "$pidfile"
# returning exit code
exit $status