#!/bin/bash

# network -> (json)
function get_incoming () {
  # right now this just prints from a log file full of payments
  cat 'in.log'
}

# (json) -> (id, condition, expiry, ILP, amount)
function extract_ilp () {
  # use jq to extract individual fields from the transfer. we print each line
  # with these fields joined by spaces. This allows us to multiplex all these
  # data on one pipeline. luckily none of them can include spaces. we'll call
  # each space-separated field a channel. The little notes above these functions
  # show the incoming and outgoing channels.
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
    # we parse the address by:
    # 1. getting the packet (in channel 4 of the input)
    # 2. decode the base64 into raw data. this is hard to work with so:
    # 3. turn the raw data into hex. now we can use string operations easily.
    #    hex formatting is done with a format string in hexdump.
    # 4. send this into bash, creating 2 output channels. channel 1 is the
    #    20th character to the 22nd character. this contains the length byte
    #    of the ILP address. Channel 2 is everything past character 22.
    # 5. xargs takes these two channels and makes them bash args to a subshell.
    #    we use bash arithmetic to get the number hex characters the length
    #    prefix bytes specifies. we take this amount of charactes off the front
    #    of channel 2.
    # 6. now decode from hex with 'xdd'
    echo "$packet" \
      | cut -f 4 -d' ' \
      | base64 -D \
      | hexdump -v -e '/1 "%02x"' \
      | xargs -n 1 bash -c 'echo "${0:20:2} ${0:22}"' \
      | xargs -n 2 bash -c 'echo ${1:0:$((2 * 16#$0))}' \
      | xxd -r -p

    # write the amount from channel 5 to channel 6
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
      # the prefix we're searching for has to start with one of the entries in our
      # routing table. once we get the first entry matching this criteria, we stop
      # reading from the routing table. the expectation is that the routing table
      # is sorted with the best routes at the top.
      if [[ "$prefix" == "$(echo $route | cut -f 1 -d' ')"* ]]; then
        echo $route
        break
      fi
    done < routing.txt
  }
  
  while read info; do
    # write channels 1, 2, 3, 4, and 6 unaltered
    echo -n "$(echo $info | cut -f 1,2,3,4,6 -d' ') "

    # turn channel 5 into (nextHop, RPC). channels 2 and 3 of the routing
    # table include the nextHop and the RPC
    echo "$info" \
      | cut -f 5 -d' ' \
      | prefix_match \
      | cut -f 2,3 -d' '
  done
}

# (id, condition, expiry, ILP, amount, nextHop, RPC) -> network
function post_destination_transfer () {
  while read info; do
    # use a regex and channel stuff to get the prefix from the peer ILP address.
    # then we use curl to create the RPC request by xarging the channels into a
    # new bash subshell.
    echo "$info $(echo $info | cut -d' ' -f 6 | sed -e 's/\(.*\)\..*/\1./')" \
      | xargs -n 8 bash -c 'curl -X POST "$6?prefix=$7&method=send_transfer" -H "Content-Type: application/json" -d "{\"id\":\"$0\",\"executionCondition\":\"$1\",\"expiresAt\":\"$2\",\"ilp\":\"$3\",\"amount\":\"$4\",\"to\":\"$5\"}"'
  done
}

# can be inserted anywhere to view that part of the pipe
# for deugging purposes
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
