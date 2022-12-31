#!/usr/bin/env bash

if [[ $# -lt 1 ]]
then
	echo "Usage: $0 [pane identifier (session:0.left or %2)]"
	echo "Returns full command executing from that pane, similar to:"
	echo "tmux display -pt [pane identifier] '#{pane_current_command}'"
	echo "But this script will return the full command."
	echo
	echo "If no pane is found, it will exit with code 2."
	echo "If no command is running, it will print an empty line."
	exit 1
fi

if ! command -v tmux &> /dev/null
then
	>&2 echo "tmux command not found."
    exit 2
fi

tmux list-panes -t "$1" &> /dev/null
if [[ $? -ne 0 ]]
then
	>&2 echo "No pane detected"
	exit 3
fi

# `tmux display` doesn't match strictly and it will give you any pane if not found.
pane_pid=$(tmux display -pt "$1" '#{pane_pid}')
if [[ -z $pane_pid ]]
then
	>&2 echo "No pane detected"
	exit 3
fi

# ps -el has different output on different systems, so we define our own format by -o
# instead of cmd=, use command= for macOS compatibility.

full_command=$(ps -e -o ppid= -o command= | awk "\$1==$pane_pid" | awk '{for(i=2;i<=NF;++i)printf $i" "}')
echo "$full_command"
