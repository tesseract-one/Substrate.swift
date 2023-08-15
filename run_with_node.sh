#!/bin/bash
# input params
NODE_BINARY="$1"
COMMAND="$2"
NODE_LOG="$3"
#creating file to store pid
pidfile=$(mktemp)
# statring node
echo "[INFO] WRAPPER: starting node"
$NODE_BINARY --dev &> "$NODE_LOG" &
echo $! > "$pidfile"
# running command
echo "[INFO] WRAPPER: executing command"
eval $COMMAND
status=$?
# stopping node & cleanup
echo "[INFO] WRAPPER: stopping node"
kill -2 $(cat "$pidfile")
rm -f "$pidfile"
# returning exit code
echo "[INFO] WRAPPER: finished with status: $status"
exit $status