#!/bin/bash

TEST_NAME="last"
printHelp() {
  echo "./kill.sh [-n TEST_NAME]"
  echo "./kill.sh TEST_NAME"
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -n | --name)
    TEST_NAME="$2"
    shift 2
    ;;
  -h)
    printHelp
    exit 0
    ;;
  *) # unknown option
    if [ $# = 1 ]; then
      TEST_NAME="$1"
    else
      echo "$1" is not valid
      printHelp
      exit 1
    fi
    shift 1
    ;;
  esac
done

# Function to safely kill a process by PID
safe_kill() {
  local pid=$1
  kill $pid
  sleep 0.5
  if kill -0 $pid 2>/dev/null; then
    kill -9 $pid
  fi
}

# Function to safely kill all processes by name
safe_killall() {
  local name=$1
  killall $name
  sleep 0.5
  if pgrep $name > /dev/null; then
    killall -9 $name
  fi
}

if [[ $TEST_NAME == "all" ]]; then
  exec 2>/dev/null
  safe_killall test.sh
  safe_killall rcssserver
  safe_killall rcssserver.bin
  rm -f "/tmp/autotest::temp"
  rm out/*/PORT*
  rm out/*/PID*
else
  for pid in $(cat out/${TEST_NAME}/PID*); do
    safe_kill $pid
  done
  for port in $(cat out/${TEST_NAME}/PORT*); do
    safe_kill $(lsof -t -i:${port})
  done
  rm out/"${TEST_NAME}"/PORT*
  rm out/"${TEST_NAME}"/PID*
fi