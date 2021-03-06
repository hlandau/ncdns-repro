#!/usr/bin/env bash

echo "Interrupting build container..."

# Make sure tor-browser-build knows why the build stopped.
touch tmp/interrupted

# Send SIGINT to all processes inside the container.
kill -s SIGINT $(./tools/container-pids.sh)

echo "Interrupted!"
