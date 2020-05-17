#!/usr/bin/env bash

set -eu -o pipefail

while test "$#" -gt 0; do
  case "$1" in
    --host ) host="$2"; shift 2 ;;
    --port ) port="$2"; shift 2;;
    --*    ) echo "error: unknown option $1" >&2; exit 1 ;;
    *      ) break ;;
  esac
done

# set default
: "${host:="localhost"}"
: "${port:="4010"}"

data=$(cat -)

exec {server}<>"/dev/tcp/$host/$port"

read -r -u "$server" response
echo "$response" | grep -qE '^OK'

printf "SSSP/1.0\n" >&${server}
read -r -u "$server" response
echo "$response" | grep -qE '^ACC'

printf "SCANDATA %d\n" "${#data}" >&${server}
read -r -u "$server" response
echo "$response" | grep -qE '^ACC'

echo -n "$data" >&${server}
while IFS= read -r -u "$server" line; do
  echo "$line"
  if echo "$line" | grep -qE '^DONE'; then
    break
  fi
done

printf "BYE\n" >&${server}
