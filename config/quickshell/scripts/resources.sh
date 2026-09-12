#!/bin/bash
# hyprdesk resources monitor script

cpu_model=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -n1 | cut -d':' -f2 | xargs)
[ -z "$cpu_model" ] && cpu_model="Generic CPU"

arch=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2)
[ -z "$arch" ] && arch="Linux"
kernel=$(uname -r)
ip=$(ip addr show 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}')
[ -z "$ip" ] && ip="127.0.0.1"

# Usage
cpu=$(LC_ALL=C top -bn1 2>/dev/null | grep "Cpu(s)" | sed 's/[:,]/ /g' | awk '{print int($2 + $4)}')
[ -z "$cpu" ] && cpu=0
mem=$(free 2>/dev/null | awk '/Mem:/ {printf "%d", $3/$2 * 100}')
[ -z "$mem" ] && mem=0
load=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0.0")
cores=$(nproc 2>/dev/null || echo "1")
load_perc=$(awk -v cores="$cores" '{printf "%d", ($1/cores)*100}' /proc/loadavg 2>/dev/null || echo "0")

# Per Core Usage
core_usages=$(LC_ALL=C top -bn1 -1 2>/dev/null | grep "^%Cpu[0-9]" | sed 's/[:,]/ /g' | awk '{print int($2 + $4)}' | jq -s . 2>/dev/null)
[ -z "$core_usages" ] && core_usages="[]"

# Temperature
temp=$(sensors 2>/dev/null | awk '/Package id 0:/ {print int($4)}' | head -n1 | tr -d '+°C')
[ -z "$temp" ] && temp=$(sensors 2>/dev/null | awk '/Tdie/ {print int($2)}' | head -n1 | tr -d '+°C')
[ -z "$temp" ] && temp=$(sensors 2>/dev/null | awk '/temp1/ {print int($2)}' | head -n1 | tr -d '+°C')
[ -z "$temp" ] && temp=45

# Filesystem
fs=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
[ -z "$fs" ] && fs=0

jq -n \
  --arg cpu "$cpu" \
  --arg mem "$mem" \
  --arg temp "$temp" \
  --arg load "$load" \
  --arg load_perc "$load_perc" \
  --arg fs "$fs" \
  --arg cpu_model "$cpu_model" \
  --arg arch "$arch" \
  --arg kernel "$kernel" \
  --arg ip "$ip" \
  --argjson core_usages "$core_usages" \
  '{
    cpu: ($cpu|tonumber),
    mem: ($mem|tonumber),
    temp: ($temp|tonumber),
    load: ($load|tonumber),
    load_perc: ($load_perc|tonumber),
    fs: ($fs|tonumber),
    cpu_model: $cpu_model,
    arch: $arch,
    kernel: $kernel,
    ip: $ip,
    core_usages: $core_usages
  }'
