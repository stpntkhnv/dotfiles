#!/bin/bash

total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

used_kb=$((total - available))
used_gb=$(awk "BEGIN {printf \"%.0f\", $used_kb / 1048576}")
total_gb=$(awk "BEGIN {printf \"%.0f\", $total / 1048576}")
pct=$((used_kb * 100 / total))

top_procs=$(ps axo rss,comm --no-headers --sort=-rss | head -8 | awk '{printf "%6.0f MB  %s\\n", $1/1024, $2}' | tr -d '\n' | sed 's/\\n$//')

tooltip="RAM: ${pct}% used\\n─────────────────\\n${top_procs}"

echo "{\"text\":\"󰍛 ${used_gb}G\",\"tooltip\":\"${tooltip}\",\"percentage\":${pct}}"
