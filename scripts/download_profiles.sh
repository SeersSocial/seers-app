#!/bin/bash

# Make sure a file is provided
if [ $# -ne 1 ]; then
   echo "Usage: $0 file.txt"
   exit 1
fi

# Execute the command in a loop
while read -r line; do
  # Execute the command and capture the output
  
  echo "$line"

  handle=($line)

  result=$(dfx canister --network ic  call markets getUserWithPosts $handle)

  # Print the output to the file
  
  echo $result >> "$handle.txt"

done
