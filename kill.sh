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

if [[ $TEST_NAME == "all" ]]; then
  exec 2>/dev/null
  killall -9 test.sh
  killall -9 rcssserver
  killall -9 rcssserver.bin
  rm -f "/tmp/autotest::temp"
  rm out/*/PORT*
  rm out/*/PID*
else
  for pid in $(cat out/${TEST_NAME}/PID*); do
    kill -9 $pid
  done
  for port in $(cat out/${TEST_NAME}/PORT*); do
    kill -9 $(lsof -t -i:${port})
  done
  rm out/"${TEST_NAME}"/PORT*
  rm out/"${TEST_NAME}"/PID*
fi
