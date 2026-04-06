#!/bin/bash

read -r used total <<< "$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | head -1 | tr ',' ' ')"

if [[ -z "$used" || -z "$total" ]]; then
    echo '{"text":"󰢮 N/A","tooltip":"GPU not available","percentage":0}'
    exit 0
fi

pct=$((used * 100 / total))

used_gb=$(awk "BEGIN {printf \"%.1f\", $used / 1024}")
total_gb=$(awk "BEGIN {printf \"%.1f\", $total / 1024}")

top_procs=$(nvidia-smi --query-compute-apps=pid,used_memory,process_name --format=csv,noheader,nounits 2>/dev/null | sort -t',' -k2 -nr | head -5 | awk -F', ' '{printf "%6s MB  %s\\n", $2, $3}' | tr -d '\n' | sed 's/\\n$//')

tooltip="VRAM: ${used}/${total} MiB (${pct}%)"
if [[ -n "$top_procs" ]]; then
    tooltip="${tooltip}\\n─────────────────\\n${top_procs}"
fi

echo "{\"text\":\"󰢮 ${used_gb}G\",\"tooltip\":\"${tooltip}\",\"percentage\":${pct}}"
