#!/bin/bash
SESSION_NAME=$1
THREAD=5              #number of simultaneously running servers
ROUNDS=20           #number of games for each server
LEFT_TEAM=
RIGHT_TEAM=
DEFAULT_PORT=      #default port connecting to server

printHelp(){
  echo ./test -l LEFT_TEAM -r RIGHT_TEAM -p DEFAULT_PORT [-t THREAD] [-ro ROUNDS]
}

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -t|--thread)
    THREAD="$2"
    shift 2
    ;;
    -ro|--round)
    ROUNDS="$2"
    shift 2
    ;;
    -p|--port)
    DEFAULT_PORT="$2"
    shift 2
    ;;
    -l|--left)
    LEFT_TEAM="$2"
    shift 2
    ;;
    -r|--right)
    RIGHT_TEAM="$2"
    shift 2
    ;;
    -s|--screen)
    USE_SCREEN=1
    shift 1
    ;;
    -h)
    printHelp
    exit 0
    ;;
    *)    # unknown option
    echo "$1" is not valid
    printHelp
    exit 1
    ;;
esac
done

success=1
[ -n "$DEFAULT_PORT" ] || success=0
[ -n "$LEFT_TEAM" ] || success=0
[ -n "$RIGHT_TEAM" ] || success=0
[ -n "$SESSION_NAME" ] || success=0
if ((!success)); then
  printHelp
  exit 1
fi


screen -S "$SESSION_NAME" -d -m ./test.sh "$*"