#!/bin/bash

THREAD=5             #number of simultaneously running servers
ROUNDS=20            #number of games for each server
GAME_LOGGING="false"  #record RCG logs
TEXT_LOGGING="false" #record RCL logs
RANDOM_SEED="-1"     #random seed, -1 means random seeding
SYNCH_MODE="1"       #synch mode
FULLSTATE_L="0"      #full state mode for left
FULLSTATE_R="0"      #full state mode for right
LEFT_TEAM=
RIGHT_TEAM=
START_PORT= #default port connecting to server
TEST_NAME="last"
BUSY_PORT=0
SHOW_RESULT=0
LEFT_BINARY_ADDRESS=""
RIGHT_BINARY_ADDRESS=""
LEFT_RPC_PORT=0
LEFT_RPC_TYPE="grpc"
RIGHT_RPC_PORT=0
RIGHT_RPC_TYPE="grpc"

printHelp() {
  echo "Without Session Name: the script saves in ./out/last"
  echo "./test -l LEFT_TEAM -r RIGHT_TEAMS -p START_PORT [-t THREAD] [-ro ROUNDS] [-n TEST_NAME]"
  echo ""
  echo "By using Test Name: the script saves in ./out/TEST_NAME/"
  echo "TEST name can not contain _ last all"
  echo "RIGHT_TEAMS includes some , seperated teams: yushan,helios,agent"
  echo "THREAD number must be divisible by the number of right teams"
  echo ./test -l LEFT_TEAM -r RIGHT_TEAMS -p START_PORT [-t THREAD] [-ro ROUNDS] [-n TEST_NAME]
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
    START_PORT="$2"
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
  -lcb)
    LEFT_BINARY_ADDRESS="$2"
    if [ "$2" = "" ]; then
      printHelp
      exit 1
    fi
    shift 2
    ;;
  -rcb)
    RIGHT_BINARY_ADDRESS="$2"
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
  --l-rpc-port)
    LEFT_RPC_PORT="$2"
    shift 2
    ;;
  --l-rpc-type)
    LEFT_RPC_TYPE="$2"
    shift 2
    ;;
  --r-rpc-port)
    RIGHT_RPC_PORT="$2"
    shift 2
    ;;
  --r-rpc-type)
    RIGHT_RPC_TYPE="$2"
    shift 2
    ;;
  *) # unknown option
    echo "$1" is not valid
    printHelp
    exit 1
    ;;
  esac
done

success=1
[ -n "$START_PORT" ] || success=0
[ -n "$LEFT_TEAM" ] || success=0
[ -n "$RIGHT_TEAM" ] || success=0
if ((!success)); then
  echo "Missing required arguments"
  printHelp
  exit 1
fi
if [[ $TEST_NAME == "all" ]]; then
  echo "TEST_NAME can not be all"
  printHelp
  exit 1
fi
if [[ $TEST_NAME == "last" ]]; then
  echo "TEST_NAME can not be last"
  printHelp
  exit 1
fi
if [[ $TEST_NAME == *"_"* ]]; then
  echo "TEST_NAME can not contain _"
  printHelp
  exit 1
fi
RIGHT_TEAM_LIST=()
RIGHT_TEAM_NUMBER=0
for i in $(echo $RIGHT_TEAM | sed "s/,/ /g")
do
    RIGHT_TEAM_LIST+=("$i")
    RIGHT_TEAM_NUMBER=$((RIGHT_TEAM_NUMBER+1))
done
if [[ $(($THREAD%$RIGHT_TEAM_NUMBER)) != 0 ]]; then
  printHelp
  exit 1
fi
if [ $SHOW_RESULT -eq 0 ]; then
  echo "\$THREAD = $THREAD"
  echo "\$ROUNDS = $ROUNDS"
  echo "\$RANDOM_SEED = $RANDOM_SEED"
  echo "\$START_PORT = $START_PORT"
  echo "\$LEFT_TEAM = $LEFT_TEAM"
  echo "\$RIGHT_TEAM = $RIGHT_TEAM"
  echo "\$TEST_NAME = $TEST_NAME"
fi
BASE_DIR="out/${TEST_NAME}"
RESULT_DIR="${BASE_DIR}/result.d"
LOG_DIR="${BASE_DIR}/log.d"
LEFT_NEW_BIN_DIR=""
RIGHT_NEW_BIN_DIR=""
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
  local BINARY_ADDRESS="$1"
  local NEW_BIN_DIR="$2"

  echo "Copying binary from $BINARY_ADDRESS to $NEW_BIN_DIR"
  
  if [ ! -f "$BINARY_ADDRESS/auto.sh" ]; then
    echo "There is no auto.sh file in $BINARY_ADDRESS"
    exit 1
  fi
  
  mkdir -p "$NEW_BIN_DIR"
  cp -r "$BINARY_ADDRESS"/* "$NEW_BIN_DIR"
  echo "Binary has been copied from $BINARY_ADDRESS to $NEW_BIN_DIR"
}

match() {
  local PORT=$1
  local TH_ID=$2
  local HOST="127.0.0.1"
  local OPTIONS=""
  local COACH_PORT=$((PORT + 1))
  local OLCOACH_PORT=$((PORT + 2))
  local RIGHT_TEAM=$3
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
      LEFT_TEAM_OPTION="-server::team_l_start=\"./start_team -h $HOST -p $PORT -P $OLCOACH_PORT -t $LEFT_TEAM -r $LEFT_RESULT"
      if [ "$LEFT_NEW_BIN_DIR" != "" ]; then
        LEFT_TEAM_OPTION="$LEFT_TEAM_OPTION -b $LEFT_NEW_BIN_DIR"
      fi
      if [ "$LEFT_RPC_PORT" != "0" ]; then
        LEFT_TEAM_OPTION="$LEFT_TEAM_OPTION -R $LEFT_RPC_PORT -T $LEFT_RPC_TYPE"
      fi
      LEFT_TEAM_OPTION="$LEFT_TEAM_OPTION\""

      RIGHT_TEAM_OPTION="-server::team_r_start=\"./start_team -h $HOST -p $PORT -P $OLCOACH_PORT -t $RIGHT_TEAM -r $RIGHT_RESULT"
      if [ "$RIGHT_NEW_BIN_DIR" != "" ]; then
        RIGHT_TEAM_OPTION="$RIGHT_TEAM_OPTION -b $RIGHT_NEW_BIN_DIR"
      fi
      if [ "$RIGHT_RPC_PORT" != "0" ]; then
        RIGHT_TEAM_OPTION="$RIGHT_TEAM_OPTION -R $RIGHT_RPC_PORT -T $RIGHT_RPC_TYPE"
      fi
      RIGHT_TEAM_OPTION="$RIGHT_TEAM_OPTION\""

      FULL_OPTIONS="$OPTIONS $LEFT_TEAM_OPTION $RIGHT_TEAM_OPTION"
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
  port_list=""
  while [ $i -lt "$THREAD" ]; do
    local PORT
    ADDPort=$((i * 10))
    PORT=$((START_PORT + ADDPort))
    local COACH_PORT=$((PORT + 1))
    local OLCOACH_PORT=$((PORT + 2))
    port_list="${port_list}${PORT},${COACH_PORT},${OLCOACH_PORT},"
    i=$((i + 1))
  done
  PORT_USED=$(lsof -i:${port_list})
  if [[ "${#PORT_USED}" -gt 0 ]]; then
    BUSY_PORT=$START_PORT
    echo "$PORT_USED"
  fi

  i=0
  while [ $i -lt "$THREAD" ]; do
    local PORT
    ADDPort=$((i * 10))
    PORT=$((START_PORT + ADDPort))
    local COACH_PORT=$((PORT + 1))
    local OLCOACH_PORT=$((PORT + 2))
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
  done
}

autotest() {
  export LANG="POSIX"
  check_port
  if [ $BUSY_PORT -ne 0 ] && [ $SHOW_RESULT -eq 0 ] ; then
    echo "Some ports are busy"
    echo $PORT_USED
    exit
  fi
  if [ "$(server_count)" -gt 0 ] && [ $SHOW_RESULT -eq 0 ] ; then
    echo "Warning: other server running"
    #exit
  fi
  if [ -d "out/$TEST_NAME" ] && [ $SHOW_RESULT -eq 0 ] ; then
    echo "Warning: previous test result left, backuped"
    mv "out/${TEST_NAME}" "out/${TEST_NAME}_$(date +"%F_%H%M")"
  fi
  mkdir -p $RESULT_DIR || exit
  mkdir -p $LOG_DIR || exit
  TOTAL_ROUNDS=$((THREAD * ROUNDS))$
  echo "$TOTAL_ROUNDS" >$TOTAL_ROUNDS_FILE
  date >$TIME_STAMP_FILE
  if [ "$LEFT_BINARY_ADDRESS" != "" ]; then
    echo "Copying left team binary"
    LEFT_NEW_BIN_DIR="${BASE_DIR}/bin/${LEFT_TEAM}"
    prepare_binary "$LEFT_BINARY_ADDRESS" "$LEFT_NEW_BIN_DIR"
  fi
  if [ "$RIGHT_BINARY_ADDRESS" != "" ]; then
    echo "Copying right team binary"
    RIGHT_NEW_BIN_DIR="${BASE_DIR}/bin/${RIGHT_TEAM}"
    prepare_binary "$RIGHT_BINARY_ADDRESS" "$RIGHT_NEW_BIN_DIR"
  fi
  local i=0
  local p=0
  while [ $i -lt $(($THREAD/$RIGHT_TEAM_NUMBER)) ]; do
    for RIGHT_TEAM_ in ${RIGHT_TEAM_LIST[@]}; do
      local PORT
      ADDPort=$((p * 10))
      PORT=$((START_PORT + ADDPort))
      match $PORT $p $RIGHT_TEAM_ &
      echo $! >>${BASE_DIR}/PID_$p
      p=$((p + 1))
      sleep 1
    done
    i=$((i + 1))
  done
  if [ $SHOW_RESULT -ne 0 ]; then
    while true
    do
	    running=$(pgrep rcssserver)
	    if [ -z "$running" ]; then
		    ./result.sh -n "$TEST_NAME" -R
		    break
	    else
		    sleep 10
	    fi
    done
  fi
  return 0
}

autotest
