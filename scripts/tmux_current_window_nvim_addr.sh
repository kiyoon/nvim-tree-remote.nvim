#!/usr/bin/env bash

# Prints the current window's nvim address

if ! command -v tmux &> /dev/null
then
	# >&2 echo "tmux command not found."
	exit 2
fi

NVIM_ADDRS=$(\ls ${XDG_RUNTIME_DIR}/nvim.* 2>/dev/null)
if [[ -z "$NVIM_ADDRS" ]]
then
	# >&2 echo "No nvim running."
	exit 3
fi

for pane_pid in $(tmux list-panes -F '#{pane_pid}'); do
	child_nvim_pid=$(pgrep -P $pane_pid nvim)
	if [[ -z "$child_nvim_pid" ]]
	then
		continue
	fi
	for addr in $NVIM_ADDRS; do
		if [[ "$addr" == *"$child_nvim_pid"* ]]; then
			echo "$addr"
			exit 0
		fi
	done
done

# # `tmux display` doesn't match strictly and it will give you any pane if not found.
# pane_pid=$(tmux display -pt "$1" '#{pane_pid}')
# if [[ -z $pane_pid ]]
# then
# 	>&2 echo "No pane detected"
# 	exit 3
# fi
#
# # ps -el has different output on different systems, so we define our own format by -o
# # instead of cmd=, use command= for macOS compatibility.
#
# full_command=$(ps -e -o ppid= -o command= | awk "\$1==$pane_pid" | awk '{for(i=2;i<=NF;++i)printf $i" "}')
# echo "$full_command"
