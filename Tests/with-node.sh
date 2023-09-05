#!/bin/bash
# input params
NODE_BINARY="$1"
COMMAND="$2"
NODE_LOG="$3"
# statring node
echo "[INFO] WRAPPER: starting node"
$NODE_BINARY --dev &> "$NODE_LOG" &
node_pid=$!
echo "[INFO] WRAPPER: started node process $node_pid"
sleep 5
kill -0 $node_pid && echo "[INFO] WRAPPER: node is running $node_pid" || exit 1
# running command
echo "[INFO] WRAPPER: executing command"
eval $COMMAND
status=$?
# stopping node & cleanup
echo "[INFO] WRAPPER: stopping node"
kill -2 $node_pid
# returning exit code
echo "[INFO] WRAPPER: finished with status: $status"
exit $status