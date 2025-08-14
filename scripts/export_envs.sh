#!/usr/bin/env bash

# Usage: source this_script.sh path_to_file

ENV_FILE="$1"

if [[ -z "$ENV_FILE" ]]; then
  echo "Usage: source $0 path_to_env_file"
  return 1  # Use 'return' so it works when sourced
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "File not found: $ENV_FILE"
  return 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
  # Ignore empty lines and comments
  [[ -z "$line" || "$line" == \#* ]] && continue

  export "$line"
done < "$ENV_FILE"
