#!/bin/bash
# This script convert all numbers to binary of 8 bit and count 1s in this binary
# Example:
#   IP: 255.0.0.0
#   Where 255 = 11111111 = 8 1s
#   And 0 = 00000000 = 0 1s
#   So type of network of 255.0.0.0 is /8

declare ip="$1"
declare -i total="0"
charOne="1"

function toBinary(){
    local n bit
    for (( n=$1 ; n>0 ; n >>= 1 )); do  bit="$(( n&1 ))$bit"; done
    printf "%s" "$bit"
}

IFS='.' read -ra ADDR <<< "$ip"
for ip_part in "${ADDR[@]}"; do
   data="$(toBinary ${ip_part})"
   count="$(awk -F"${charOne}" '{print NF-1}' <<< "${data}")"
   if [ $count -ge 0 ]; then
        ((total=total+count))
    fi
done
echo "Type of network: /$total"
