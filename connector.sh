#!/bin/bash

# file
  # \_> {"ilp":"alice"}
  # \_> alice
  # \_> alice example.alice
  # \_> {"to":"example.alice","ilp":"alice"}
function parse_ilp () {
  while read packet; do
    echo "$packet" \
      | base64 -D \
      | hexdump -v -e '/1 "%02x"' \
      | xargs -n 1 -I {} echo "{}" \
      | xargs -n 1 bash -c 'echo "${0:20:2} ${0:22}"' \
      | xargs -n 2 bash -c 'echo ${1:0:$((2 * 16#$0))}' \
      | xxd -r -p
    echo
  done
}

cat 'in.log' \
  | jq -r '.ilp' \
  | parse_ilp
  # | xargs -I {} -n 1 grep {} routing.txt \
  # | cut -d' ' -f 1,2,3 \
  # | xargs -n 3 bash -c 'curl -X POST "$2" -d "to=$1&ilp=$0" -H "Content-Type=application/json"'
  # | xargs -n 3 echo
