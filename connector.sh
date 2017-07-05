#!/bin/bash

# file
  # \_> {"ilp":"alice"}
  # \_> alice
  # \_> alice example.alice
  # \_> {"to":"example.alice","ilp":"alice"}
function parse_ilp () {
  read packet
  echo "$packet" \
    | base64 -D \
    | hexdump -v -e '/1 "%02x"' \
    | xargs -n 1 -I {} echo "{}" \
    | xargs -n 1 bash -c 'echo "beep ${0}"'
    # | xxd -r -p
    # | sed -e 's/.\{8}\(.\{1}\)\(.+\)/\1 \2/' \
    # | cut -d' ' -f 1,2 \
    # | xargs -n 3 bash -c 'echo $1 | sed -e "s/^\(.\{$(printf "%d" "$0")}\)/\1/"' \
    # | echo
}

cat 'in.log' \
  | jq -r '.ilp' \
  | parse_ilp
  # | xargs -I {} -n 1 grep {} routing.txt \
  # | cut -d' ' -f 1,2,3 \
  # | xargs -n 3 bash -c 'curl -X POST "$2" -d "to=$1&ilp=$0" -H "Content-Type=application/json"'
  # | xargs -n 3 echo
