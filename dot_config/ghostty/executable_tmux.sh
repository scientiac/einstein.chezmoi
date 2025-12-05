#!/bin/bash

# Initialize session number
SESSION_NAME=""

# Find the next available session name
i=1
while tmux has-session -t $i 2>/dev/null; do
  ((i++))
done

# Set the session name to the current number
SESSION_NAME=$i

# Start the new session
tmux new-session -s $SESSION_NAME -d
tmux attach-session -t $SESSION_NAME
