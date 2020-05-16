#!/usr/bin/env bash

set -eu -o pipefail

: "${SOPHOS_UPDATE_INTERVAL_SEC:=3600}"
: "${PROCESS_CHECK_INTERVAL_SEC:=5}"
: "${WATCH_LOG_INTERVAL_SEC:=5}"

log() {
  now="$(date "+%Y-%m-%d %H:%M:%S")"
  echo "$now" "$@"
}

with_prefix() {
  prefix="${1?}"
  while IFS= read -r line; do printf '%s%s\n' "$prefix" "$line"; done
}
export -f with_prefix


# Start savdid
PIDFILE=/var/run/savdid.pid
/usr/local/bin/savdid -d -s -f "$PIDFILE"


# Start log watcher process
(
  while true; do
    # write logs to stdout and delete logs
    find /var/tmp/savdi/log/ -type f | sort | xargs --no-run-if-empty cat
    find /var/tmp/savdi/log/ -type f | sort | xargs --no-run-if-empty -n 1 truncate -s 0
    sleep "$WATCH_LOG_INTERVAL_SEC"
  done 2>&1 | with_prefix "log_watcher: "
) &
log_watcher_pid=$!


# Start updater process
(
  while true; do
    log "start update"
    start_time=$(date "+%s")
    /opt/sophos-av/bin/savupdate || true

    log "check update log"
    logfile=/tmp/sophos_update.log
    /opt/sophos-av/bin/savlog --after="$start_time" --noHeader | tee "$logfile"
    if grep -q -i "update completed" "$logfile"; then
      log "spawn new daemon"
      /bin/kill -s HUP "$(cat "$PIDFILE")"
    fi

    # delete log
    truncate -s 0 /opt/sophos-av/log/savd.log
    truncate -s 0 /opt/sophos-av/log/savupdate-debug.log

    log "end update"
    sleep "$SOPHOS_UPDATE_INTERVAL_SEC"
  done 2>&1 | with_prefix "updater: "
) &
updater_pid=$!


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
  if ! ps -p "$log_watcher_pid" &> /dev/null; then
    log "log watcher exited."
    exit 1
  fi
  sleep "$PROCESS_CHECK_INTERVAL_SEC"
done
