#!/bin/bash

THREAD=5             #number of simultaneously running servers
ROUNDS=20            #number of games for each server
GAME_LOGGING="true"  #record RCG logs
TEXT_LOGGING="false" #record RCL logs
RANDOM_SEED="-1"     #random seed, -1 means random seeding
SYNCH_MODE="1"       #synch mode
FULLSTATE_L="0"      #full state mode for left
FULLSTATE_R="0"      #full state mode for right
LEFT_TEAM=
RIGHT_TEAM=
DEFAULT_PORT= #default port connecting to server
TEST_NAME="last"
BUSY_PORT=0
COPY_BINARY=0
SHOW_RESULT=0
BINARY_ADDRESS=""

printHelp() {
  echo "Without Session Name: the script saves in ./out/last"
  echo "./test -l LEFT_TEAM -r RIGHT_TEAM -p DEFAULT_PORT [-t THREAD] [-ro ROUNDS]"
  echo ""
  echo "By using Test Name: the script saves in ./out/TEST_NAME/"
  echo "TEST name can not contain _ last all"
  echo ./test -l LEFT_TEAM -r RIGHT_TEAM -p DEFAULT_PORT [-t THREAD] [-ro ROUNDS] [-n TEST_NAME]
  echo ""
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -t | --thread)
    THREAD="$2"
    shift 2
    ;;
  -ro | --round)
    ROUNDS="$2"
    shift 2
    ;;
  -p | --port)
    DEFAULT_PORT="$2"
    shift 2
    ;;
  -l | --left)
    LEFT_TEAM="$2"
    shift 2
    ;;
  -r | --right)
    RIGHT_TEAM="$2"
    shift 2
    ;;
  -n | --name)
    TEST_NAME="$2"
    shift 2
    ;;
  -cb)
    COPY_BINARY=1
    BINARY_ADDRESS="$2"
    if [ "$2" = "" ]; then
      printHelp
      exit 1
    fi
    shift 2
    ;;
  -h)
    printHelp
    exit 0
    ;;
  -R | --result)
    SHOW_RESULT=1
    shift 1
    ;;
  *) # unknown option
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
if ((!success)); then
  printHelp
  exit 1
fi
if [[ $TEST_NAME == "all" ]]; then
  printHelp
  exit 1
fi
if [[ $TEST_NAME == "last" ]]; then
  printHelp
  exit 1
fi
if [[ $TEST_NAME == *"_"* ]]; then
  printHelp
  exit 1
fi

echo "\$THREAD = $THREAD"
echo "\$ROUNDS = $ROUNDS"
echo "\$RANDOM_SEED = $RANDOM_SEED"
echo "\$DEFAULT_PORT = $DEFAULT_PORT"
echo "\$LEFT_TEAM = $LEFT_TEAM"
echo "\$RIGHT_TEAM = $RIGHT_TEAM"
echo "\$TEST_NAME = $TEST_NAME"

BASE_DIR="out/${TEST_NAME}"
RESULT_DIR="${BASE_DIR}/result.d"
LOG_DIR="${BASE_DIR}/log.d"
NEW_BIN_DIR="${BASE_DIR}/bin"
TOTAL_ROUNDS_FILE="$RESULT_DIR/total_rounds"
TIME_STAMP_FILE="$RESULT_DIR/time_stamp"
HTML="$RESULT_DIR/index.html"
HTML_GENERATING_LOCK="/tmp/autotest_html_generating_${TEST_NAME}"

run_server() {
  ulimit -t 300
  echo rcssserver "$@"
  rcssserver "$@"
}

server_count() {
  ps -o pid= -C rcssserver | wc -l
}

prepare_binary() {
  if [ ! -f $BINARY_ADDRESS/auto.sh ]; then
    echo "There is not auto.sh file in $BINARY_ADDRESS"
    exit 1
  fi
  mkdir $NEW_BIN_DIR
  cp -r $BINARY_ADDRESS/* $NEW_BIN_DIR
  echo "Binary has been copied from $BINARY_ADDRESS to $NEW_BIN_DIR"
}

match() {
  local PORT=$1
  local TH_ID=$2
  local HOST="127.0.0.1"
  local OPTIONS=""
  local COACH_PORT=$((PORT + 1))
  local OLCOACH_PORT=$((PORT + 2))
  echo "$PORT" >>${BASE_DIR}/PORT_${TH_ID}
  echo "$COACH_PORT" >>${BASE_DIR}/PORT_${TH_ID}
  echo "$OLCOACH_PORT" >>${BASE_DIR}/PORT_${TH_ID}
  OPTIONS="$OPTIONS -server::port=$PORT"
  OPTIONS="$OPTIONS -server::coach_port=$COACH_PORT"
  OPTIONS="$OPTIONS -server::olcoach_port=$OLCOACH_PORT"
  OPTIONS="$OPTIONS -player::random_seed=$RANDOM_SEED"
  OPTIONS="$OPTIONS -server::nr_normal_halfs=2 -server::nr_extra_halfs=0 -server::half_time = 300"
  OPTIONS="$OPTIONS -server::penalty_shoot_outs=false -server::auto_mode=on"
  OPTIONS="$OPTIONS -server::game_logging=$GAME_LOGGING -server::text_logging=$TEXT_LOGGING"
  OPTIONS="$OPTIONS -server::game_log_compression=0 -server::text_log_compression=0"
  OPTIONS="$OPTIONS -server::game_log_fixed=1 -server::text_log_fixed=1"
  OPTIONS="$OPTIONS -server::synch_mode=$SYNCH_MODE"
  OPTIONS="$OPTIONS -server::fullstate_l=$FULLSTATE_L -server::fullstate_r=$FULLSTATE_R"

  rm -f $HTML_GENERATING_LOCK
  generate_html

  for i in $(seq 1 "$ROUNDS"); do
    local TIME
    local PWD
    TIME="$(date +%Y%m%d%H%M)_$RANDOM"
    local RESULT="$RESULT_DIR/$TIME"
    PWD="$(pwd)"
    local LEFT_RESULT="${PWD}/${RESULT_DIR}/${TIME}_L"
    local RIGHT_RESULT="${PWD}/${RESULT_DIR}/${TIME}_R"
    if [ ! -f "$RESULT" ]; then
      local FULL_OPTIONS=""
      FULL_OPTIONS="$OPTIONS -server::team_l_start=\"./start_team $HOST $PORT $OLCOACH_PORT $LEFT_TEAM $LEFT_RESULT\""
      if [ $COPY_BINARY = 1 ]; then
        FULL_OPTIONS="$OPTIONS -server::team_l_start=\"./start_team $HOST $PORT $OLCOACH_PORT $LEFT_TEAM $LEFT_RESULT $NEW_BIN_DIR\""
      fi
      FULL_OPTIONS="$FULL_OPTIONS -server::team_r_start=\"./start_team $HOST $PORT $OLCOACH_PORT $RIGHT_TEAM $RIGHT_RESULT\""
      FULL_OPTIONS="$FULL_OPTIONS -server::game_log_dir=\"./$LOG_DIR/\" -server::text_log_dir=\"./$LOG_DIR/\""
      FULL_OPTIONS="$FULL_OPTIONS -server::game_log_fixed_name=\"$TIME\" -server::text_log_fixed_name=\"$TIME\""
      run_server $FULL_OPTIONS &>$RESULT
    fi
    sleep 1
    generate_html
  done

  rm "${BASE_DIR}/PORT_${TH_ID}"
  rm "${BASE_DIR}/PID_${TH_ID}"
}

generate_html() {
  if [ ! -f $HTML_GENERATING_LOCK ]; then
    touch $HTML $HTML_GENERATING_LOCK
    chmod 777 $HTML $HTML_GENERATING_LOCK 2>/dev/null #allow others to delete or overwrite
    ./result.sh -n "$TEST_NAME" --html >$HTML
    ./analyze.sh -n "$TEST_NAME" 2>/dev/null
    echo -e "<hr>" >>$HTML
    echo -e "<p><small>""$(whoami)"" @ ""$(date)""</small></p>" >>$HTML
    rm -f $HTML_GENERATING_LOCK
  fi
}

check_port() {
  local i=0
  while [ $i -lt "$THREAD" ]; do
    local PORT
    ADDPort=$((i * 10))
    PORT=$((DEFAULT_PORT + ADDPort))
    local COACH_PORT=$((PORT + 1))
    local OLCOACH_PORT=$((PORT + 2))
    PORT_USED=$(lsof -i:$PORT)
    COACH_PORT_USED=$(lsof -i:$COACH_PORT)
    OLCOACH_PORT_USED=$(lsof -i:$OLCOACH_PORT)
    if [[ "${#PORT_USED}" -gt 0 ]]; then
      BUSY_PORT=$PORT
      echo "$PORT_USED"
    fi
    if [[ "${#COACH_PORT_USED}" -gt 0 ]]; then
      BUSY_PORT=$COACH_PORT
      echo "$COACH_PORT_USED"
    fi
    if [[ "${#OLCOACH_PORT_USED}" -gt 0 ]]; then
      BUSY_PORT=$OLCOACH_PORT
      echo "$OLCOACH_PORT_USED"
    fi
    for file in out*/PORT*; do
      [[ -e "$file" ]] || break
      if grep -q $PORT "$file"; then
        BUSY_PORT=$PORT
        echo "***PORT $PORT is being used in $file"
      fi
      if grep -q $COACH_PORT "$file"; then
        BUSY_PORT=$COACH_PORT
        echo "***PORT $PORT is being used in $file"
      fi
      if grep -q $OLCOACH_PORT "$file"; then
        BUSY_PORT=$OLCOACH_PORT
        echo "***PORT $PORT is being used in $file"
      fi
    done
    i=$((i + 1))
    sleep 1
  done
}

autotest() {
  export LANG="POSIX"
  check_port
  if [ $BUSY_PORT -ne 0 ]; then
    echo "Some ports are busy"
    exit
  fi
  if [ "$(server_count)" -gt 0 ]; then
    echo "Warning: other server running"
    #exit
  fi
  if [ -d "out/$TEST_NAME" ]; then
    echo "Warning: previous test result left, backuped"
    mv "out/${TEST_NAME}" "out/${TEST_NAME}_$(date +"%F_%H%M")"
  fi
  mkdir -p $RESULT_DIR || exit
  mkdir -p $LOG_DIR || exit
  TOTAL_ROUNDS=$((THREAD * ROUNDS))$
  echo "$TOTAL_ROUNDS" >$TOTAL_ROUNDS_FILE
  date >$TIME_STAMP_FILE
  if [ $COPY_BINARY = 1 ]; then
    prepare_binary
  fi
  local i=0
  while [ $i -lt "$THREAD" ]; do
    local PORT
    ADDPort=$((i * 10))
    PORT=$((DEFAULT_PORT + ADDPort))
    match $PORT $i &
    echo $! >>${BASE_DIR}/PID_$i
    i=$((i + 1))
    sleep 1
  done
  if [ $SHOW_RESULT -ne 0 ]; then
    while true
    do
	    running=$(pgrep rcssserver)
	    if [ -z $running ]; then
		    echo "finished"
		    bash "result.sh TEST_NAME"
		    break
	    else
		    echo "still running"
		    sleep 10
	    fi

    done
  fi
  return 0
}

autotest
