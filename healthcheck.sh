#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck disable=SC2016
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' \
  | scandata.sh \
  | grep -qE '^DONE OK 0203 Virus found during virus scan'
