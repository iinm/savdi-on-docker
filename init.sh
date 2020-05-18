#!/usr/bin/env bash

set -eu -o pipefail

if test "${DEBUG:-no}" = "yes"; then
  exec 2> >(while IFS= read -r line; do printf '%s%s%s\n' "$(tput setaf 1)" "$line" "$(tput sgr0)"; done >&2)
fi

: "${SOPHOS_UPDATE_INTERVAL_SEC:=3600}"
: "${PROCESS_CHECK_INTERVAL_SEC:=5}"
: "${LOGCAT_INTERVAL_SEC:=10}"
: "${SAVDI_LOGDIR:=/var/tmp/savdi/log}"


with_prefix() {
  prefix="${1?}"
  while IFS= read -r line; do printf '%s%s\n' "$prefix" "$line"; done
}

with_time() {
  while IFS= read -r line; do printf '%s %s\n' "$(date "+%Y-%m-%d %H:%M:%S")" "$line"; done
}


# Start savdid
PIDFILE=/var/run/savdid.pid
/usr/local/bin/savdid -d -s -f "$PIDFILE"


# Start logcat process
(
  while true; do
    # write logs to stdout and delete logs
    find "$SAVDI_LOGDIR" -type f -size +0c -name '*.log' \
      | sort \
      | xargs --no-run-if-empty -n 1 -I {} bash -c 'cat {} && truncate -s 0 {}' \
      | sed -E 's,([0-9]{2})([0-9]{2})([0-9]{2}):([0-9]{2})([0-9]{2})([0-9]{2}),20\1-\2-\3 \4:\5:\6,'
    sleep "$LOGCAT_INTERVAL_SEC"
  done
) 2> >(with_prefix "logcat: " >&2) | with_prefix "logcat: " &
logcat_pid=$!


# Start updater process
(
  while true; do
    echo "start update"
    start_time=$(date "+%s")
    /opt/sophos-av/bin/savupdate || true

    if /opt/sophos-av/bin/savlog --after="$start_time" --noHeader | grep -q -i "update completed"; then
      echo "spawn new daemon"
      /bin/kill -s HUP "$(cat "$PIDFILE")"
    fi

    # delete log
    truncate -s 0 /opt/sophos-av/log/savd.log
    truncate -s 0 /opt/sophos-av/log/savupdate-debug.log

    echo "end update"
    sleep "$SOPHOS_UPDATE_INTERVAL_SEC"
  done
) 2> >(with_time | with_prefix "updater: " >&2) | with_time | with_prefix "updater: " >&2 &
updater_pid=$!


# Output log on exit
on_exit() {
  exit_status=$?
  find "$SAVDI_LOGDIR" -type f -size +0c -name '*.log' \
    | sort \
    | xargs --no-run-if-empty cat \
    | with_prefix "logcat: "
  return "$exit_status"
}
trap on_exit EXIT


# Ensure all processes are alive
while true; do
  if ! ps -p "$(cat "$PIDFILE")" &> /dev/null; then
    log "savdid exited."
    exit 1
  fi
  if ! ps -p "$updater_pid" &> /dev/null; then
    log "updater exited."
    exit 1
  fi
  if ! ps -p "$logcat_pid" &> /dev/null; then
    log "log watcher exited."
    exit 1
  fi
  sleep "$PROCESS_CHECK_INTERVAL_SEC"
done
