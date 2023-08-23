#!/bin/bash

# Read the input string from a file
input_string=$(cat idsBackup.txt)

# Remove all characters except for the IDs and semicolons
clean_string=$(echo "$input_string" | sed 's/[^-;a-z0-9"]//g')

# Replace semicolons with newlines
id_string=$(echo "$clean_string" | tr ';' '\n')

# Extract the IDs from the string
ids=$(echo "$id_string" | sed 's/"//g')

# Create a backup folder with the current date and time
backup_folder="users_backup/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$backup_folder"

# Loop through each ID and execute a command
while read -r id; do
    # Wait for 1 second before executing the command
    echo "Backing up user $id"
    
    sleep 1

    # Execute the dfx canister command for the current ID and save the output to a file
    dfx canister --network ic call markets readUserByPrincipal '("'"$id"'")' > "$backup_folder/$id.txt"
done <<< "$ids"