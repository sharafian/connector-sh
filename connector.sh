#!/bin/bash

# network -> (json)
function get_incoming () {
  cat 'in.log'
}

# (json) -> (id, condition, expiry, ILP, amount)
function extract_ilp () {
  while read json; do
    echo -n "$(echo "$json" | jq -r '.id') "
    echo -n "$(echo "$json" | jq -r '.executionCondition') "
    echo -n "$(echo "$json" | jq -r '.expiresAt') "
    echo -n "$(echo "$json" | jq -r '.ilp') "
    echo "$(echo "$json" | jq -r '.amount')"
  done
}

# (id, condition, expiry, ILP, amount) -> (id, condition, expiry, ILP, address, amount)
function parse_ilp () {
  while read packet; do
    # write channels 1, 2, 3, and 4 unaltered
    echo -n "$(echo $packet | cut -f 1,2,3,4 -d' ') "

    # write channel 4 as the parsed address
    echo "$packet" \
      | cut -f 4 -d' ' \
      | base64 -D \
      | hexdump -v -e '/1 "%02x"' \
      | xargs -n 1 -I {} echo "{}" \
      | xargs -n 1 bash -c 'echo "${0:20:2} ${0:22}"' \
      | xargs -n 2 bash -c 'echo ${1:0:$((2 * 16#$0))}' \
      | xxd -r -p

    # write channel 6 as the amount
    echo -n ' '
    echo "$packet" \
      | cut -f 5 -d' '
  done
}

# (id, condition, expiry, ILP, address, amount) -> (id, condition, expiry, ILP, amount, nextHop, RPC)
function get_routing_info () {
  # use a bash while loop to get a matching prefix
  function prefix_match () {
    read prefix
    while read route; do
      [[ "$prefix" == "$(echo $route | cut -f 1 -d' ')"* ]] && echo $route
    done < routing.txt
  }
  
  while read info; do
    # write channels 1, 2, 3, 4, and 6 unaltered
    echo -n "$(echo $info | cut -f 1,2,3,4,6 -d' ') "

    # turn channel 5 into (nextHop, RPC)
    echo "$info" \
      | cut -f 5 -d' ' \
      | prefix_match \
      | cut -f 2,3 -d' '
  done
}

# (id, condition, expiry, ILP, amount, nextHop, RPC) -> network
function post_destination_transfer () {
  while read info; do
    echo "$info $(echo $info | cut -d' ' -f 6 | sed -e 's/\(.*\)\..*/\1./')" \
      | xargs -n 8 bash -c 'curl -X POST "$6?prefix=$7&method=send_transfer" -H "Content-Type: application/json" -d "{\"id\":\"$0\",\"executionCondition\":\"$1\",\"expiresAt\":\"$2\",\"ilp\":\"$3\",\"amount\":\"$4\",\"to\":\"$5\"}"'
  done
}

# can be inserted anywhere to view that part of the pipe
function inspector () {
  while read info; do
    echo $info 1>&2
  done
}

get_incoming \
  | extract_ilp \
  | parse_ilp \
  | get_routing_info \
  | post_destination_transfer
