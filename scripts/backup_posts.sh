#!/bin/bash

max_post_id_str=$(dfx canister --network ic call markets readNextPostId | sed 's/.*(\([0-9]\+\) : nat32)/\1/g' | sed 's/.*(//;s/ :.*//;s/ //g' | tr -d '_' | tr -d '[:space:]' | grep -o '[0-9]\+')

echo "Max post id str |$max_post_id_str|"

max_post_id=$((max_post_id_str+0))

echo "Max post id $max_post_id"

start_id=0
chunk_size=100
end_id=$((start_id + chunk_size - 1))

backup_folder="posts_backup/$(date +'%Y-%m-%d_%H-%M-%S')"
mkdir -p "$backup_folder"

while [ $start_id -le $max_post_id ]; do
  echo "Backing up posts from $start_id to $end_id"
  dfx canister --network ic call markets backupPostsRange '('$start_id', '$end_id')' > "$backup_folder/posts_$start_id-$end_id.txt"
  start_id=$((end_id + 1))
  end_id=$((start_id + chunk_size - 1))
done
