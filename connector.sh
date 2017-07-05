#!/bin/bash

# file
  # \_> {"ilp":"alice"}
  # \_> alice
  # \_> alice example.alice
  # \_> {"to":"example.alice","ilp":"alice"}

cat 'in.log' \
  | jq '.ilp' \
  | xargs -I {} -n 1 grep {} routing.txt \
  | cut -d' ' -f 1,2,3 \
  | xargs -n 3 bash -c 'curl -X POST "$2" -d "to=$1&ilp=$0" -H "Content-Type=application/json"'
  # | xargs -n 3 echo
