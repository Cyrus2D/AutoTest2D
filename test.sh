#!/bin/bash

THREAD=5              #number of simultaneously running servers
ROUNDS=20           #number of games for each server
GAME_LOGGING="true"   #record RCG logs
TEXT_LOGGING="false"   #record RCL logs
RANDOM_SEED="-1"       #random seed, -1 means random seeding
SYNCH_MODE="1"         #synch mode
FULLSTATE_L="0"        #full state mode for left
FULLSTATE_R="0"        #full state mode for right
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
    echo HHHHHHHHHH
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
if ((!success)); then
  printHelp
  exit 1
fi

echo "\$THREAD = $THREAD"
echo "\$ROUNDS = $ROUNDS"
echo "\$RANDOM_SEED = $RANDOM_SEED"
echo "\$DEFAULT_PORT = $DEFAULT_PORT"
echo "\$LEFT_TEAM = $LEFT_TEAM"
echo "\$RIGHT_TEAM = $RIGHT_TEAM"

RESULT_DIR="result.d"
LOG_DIR="log.d"
TOTAL_ROUNDS_FILE="$RESULT_DIR/total_rounds"
TIME_STAMP_FILE="$RESULT_DIR/time_stamp"
HTML="$RESULT_DIR/index.html"
HTML_GENERATING_LOCK="/tmp/autotest_html_generating"

run_server() {
    ulimit -t 300
    echo rcssserver "$@"
    rcssserver "$@"
}

server_count() {
    ps -o pid= -C rcssserver | wc -l
}

match() {
	  local PORT=$1
	  local HOST="127.0.0.1"
	  local OPTIONS=""
    local COACH_PORT=$((PORT+1))
    local OLCOACH_PORT=$((PORT+2))

    OPTIONS="$OPTIONS -server::port=$PORT"
    OPTIONS="$OPTIONS -server::coach_port=$COACH_PORT"
    OPTIONS="$OPTIONS -server::olcoach_port=$OLCOACH_PORT"
    OPTIONS="$OPTIONS -player::random_seed=$RANDOM_SEED"
    OPTIONS="$OPTIONS -server::nr_normal_halfs=2 -server::nr_extra_halfs=0"
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
        FULL_OPTIONS="$OPTIONS -server::team_r_start=\"./start_team $HOST $PORT $OLCOACH_PORT $RIGHT_TEAM $RIGHT_RESULT\""
        FULL_OPTIONS="$FULL_OPTIONS -server::team_l_start=\"./start_team $HOST $PORT $OLCOACH_PORT $LEFT_TEAM $LEFT_RESULT\""
        FULL_OPTIONS="$FULL_OPTIONS -server::game_log_dir=\"./$LOG_DIR/\" -server::text_log_dir=\"./$LOG_DIR/\""
        FULL_OPTIONS="$FULL_OPTIONS -server::game_log_fixed_name=\"$TIME\" -server::text_log_fixed_name=\"$TIME\""
        run_server $FULL_OPTIONS  &>$RESULT
  		fi
      sleep 1
      generate_html
  	done
}

generate_html() {
    if [ ! -f $HTML_GENERATING_LOCK ]; then
        touch $HTML $HTML_GENERATING_LOCK
        chmod 777 $HTML $HTML_GENERATING_LOCK 2>/dev/null #allow others to delete or overwrite

        ./result.sh --html >$HTML
        ./analyze.sh 2>/dev/null
        echo -e "<hr>" >>$HTML
        echo -e "<p><small>""$(whoami)"" @ ""$(date)""</small></p>" >>$HTML
        rm -f $HTML_GENERATING_LOCK
    fi
}

autotest() {
    export LANG="POSIX"

    if [ "$(server_count)" -gt 0 ]; then
        echo "Warning: other server running"
        #exit
    fi

    if [ -d $RESULT_DIR ]; then
      echo "Warning: previous test result left, backuped"
      mv $RESULT_DIR ${RESULT_DIR}_"$(date +"%F_%H%M")"
      mv $LOG_DIR ${LOG_DIR}_"$(date +"%F_%H%M")"
    fi
    mkdir $RESULT_DIR || exit
    mkdir $LOG_DIR || exit
    TOTAL_ROUNDS=$((THREAD * $ROUNDS))$
    echo "$TOTAL_ROUNDS" >$TOTAL_ROUNDS_FILE
    date >$TIME_STAMP_FILE

    local i=0
    while [ $i -lt "$THREAD" ]; do
        local PORT
        ADDPort=$((i * 10))
        PORT=$((DEFAULT_PORT + ADDPort))
        match $PORT &
        i=$((i + 1))
        sleep 1
    done
    return 0
}
autotest
