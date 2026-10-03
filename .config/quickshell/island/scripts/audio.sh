#!/bin/sh
# 8 lines: sink vol, sink mute, source vol, source mute, sink name, source name, sink description, source description
pactl get-sink-volume @DEFAULT_SINK@ | head -1
pactl get-sink-mute @DEFAULT_SINK@
pactl get-source-volume @DEFAULT_SOURCE@ | head -1
pactl get-source-mute @DEFAULT_SOURCE@
s=$(pactl get-default-sink); m=$(pactl get-default-source)
echo "$s"; echo "$m"
desc() { pactl list "$1" | awk -v n="$2" '$1=="Name:"{f=($2==n)} f&&/Description:/{sub(/^[ \t]*Description: /,""); print; exit}'; }
desc sinks "$s"; desc sources "$m"
