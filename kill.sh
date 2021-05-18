#!/bin/bash

KILL_SCREEN=0
SCREEN_NAME=
printHelp(){
  echo "./kill.sh [-s|-n screen_name]"
}
if [ $# -eq 1 ]; then
  echo yes
  SCREEN_NAME=$1
  KILL_SCREEN=1
else
  while [[ $# -gt 0 ]]
  do
  key="$1"
  case $key in
      -n|--name|-s|--screen)
      SCREEN_NAME="$2"
      KILL_SCREEN=1
      shift 2
      ;;
      -h)
      printHelp
      exit 0
      ;;
      *)    # unknown option
      echo "$1" is not valid
      printHelp
      ;;
  esac
  done
fi

if [ $KILL_SCREEN = 1 ]; then
  screen -XS "$SCREEN_NAME" quit
else
  exec 2>/dev/null
  killall -9 test.sh
  killall -9 rcssserver
  killall -9 rcssserver.bin
  rm -f "/tmp/autotest::temp"
fi
