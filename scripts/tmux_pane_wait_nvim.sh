#!/usr/bin/env bash

if [[ $# -lt 1 ]]
then
	echo "Usage: $0 [pane identifier (session:0.left or %2)] [timeout (default 10)]"
	echo "Wait until neovim opens in the pane"
	exit 1
fi

if [[ $# -lt 2 ]]
then
	timeout=10
else
	timeout=$2
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

for i in $(seq 1 $(( timeout * 10 ))); do
	if [[ -z "$XDG_RUNTIME_DIR" ]]
	then
		# macOS
		NVIM_ADDRS=$(\ls ${TMPDIR}nvim.${USER}/**/nvim.* 2>/dev/null)
	else
		# Linux
		NVIM_ADDRS=$(\ls ${XDG_RUNTIME_DIR}/nvim.* 2>/dev/null)
	fi

	child_nvim_pid=$(pgrep -P $pane_pid nvim)

	# Sometimes, nvim can be a child of a child when using with some plugins?
	# the first child is nvim --embed and the next is the actual nvim process.
	while [[ -n "$child_nvim_pid" ]]
	do	
		for addr in $NVIM_ADDRS; do
			if [[ "$addr" == *"$child_nvim_pid"* ]]; then
				echo "$addr"
				exit 0
			fi
		done
		child_nvim_pid=$(pgrep -P $child_nvim_pid nvim)
	done
	sleep 0.1
done
