#!/usr/bin/env bash

set -eu -o pipefail

echo 'hello' | scandata.sh | grep -qE "^DONE OK 0000"
