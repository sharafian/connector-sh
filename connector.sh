#!/bin/bash

# network -> (json)
function get_incoming () {
  cat 'in.log'
}

# (json) -> (condition, expiry, ILP, amount)
function extract_ilp () {
  while read json; do
    echo -n "$(echo "$json" | jq -r '.executionCondition') "
    echo -n "$(echo "$json" | jq -r '.expiresAt') "
    echo -n "$(echo "$json" | jq -r '.ilp') "
    echo "$(echo "$json" | jq -r '.amount')"
  done
}

# (condition, expiry, ILP, amount) -> (condition, expiry, ILP, address, amount)
function parse_ilp () {
  while read packet; do
    # write channels 1, 2, and 3 unaltered
    echo -n "$(echo $packet | cut -f 1,2,3 -d' ') "

    # write channel 4 as the parsed address
    echo "$packet" \
      | cut -f 3 -d' ' \
      | base64 -D \
      | hexdump -v -e '/1 "%02x"' \
      | xargs -n 1 -I {} echo "{}" \
      | xargs -n 1 bash -c 'echo "${0:20:2} ${0:22}"' \
      | xargs -n 2 bash -c 'echo ${1:0:$((2 * 16#$0))}' \
      | xxd -r -p

    # write channel 5 as the amount
    echo -n ' '
    echo "$packet" \
      | cut -f 4 -d' '
  done
}

# (condition, expiry, ILP, address, amount) -> (condition, expiry, ILP, amount, nextHop, rpc)
function get_routing_info () {
  while read info; do
    echo $info
  done
}

# (condition, expiry, ILP, amount, nextHop, rpc) -> network
function post_destination_transfer () {
  while read info; do
    echo $info
  done
}

get_incoming \
  | extract_ilp \
  | parse_ilp \
  | get_routing_info \
  | post_destination_transfer
  # | xargs -I {} -n 1 grep {} routing.txt \
  # | cut -d' ' -f 1,2,3 \
  # | xargs -n 3 bash -c 'curl -X POST "$2" -d "to=$1&ilp=$0" -H "Content-Type=application/json"'
  # | xargs -n 3 echo
