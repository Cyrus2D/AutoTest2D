#!/bin/bash

PARSE="../../../scripts/parse.awk"
PROCESS="../../../scripts/process.py"
TEST_NAME="last"

printHelp() {
  echo "./result.sh [-n TEST_NAME] [process options]"
  echo "./result.sh TEST_NAME"
}
PROCESS_ARGS=""
RESULT_ONLY=0
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -n | --name)
    TEST_NAME="$2"
    shift 2
    ;;
  -C | --console)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -N | --no-color)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -R | --result)
    RESULT_ONLY=1
    shift 1
    ;;
  -D | --discuz)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -H | --html)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -S | --simplify)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -A | --curve)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -M | --map)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -T | --temp)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
  -h)
    printHelp
    exit 0
    ;;
  *) # unknown option
    if [ $# = 1 ]; then
      TEST_NAME="$1"
      shift 1
    else
      echo "$1" is not valid
      printHelp
      exit 1
    fi
    ;;
  esac
done

DIR="out/${TEST_NAME}"
if [ -d "$DIR" ]; then
    echo "Directory exists: $DIR"
    # You can add commands here to execute if the directory exists
else
    echo "Directory does not exist: $DIR"
    matching_dirs=$(find "out" -maxdepth 1 -type d -name "${TEST_NAME}*")
    if [ -z "$matching_dirs" ]; then
        echo "No directories found starting with '$TEST_NAME' in out/."
        exit 1
    fi
    dir_count=$(echo "$matching_dirs" | grep -c /)
    if [ $dir_count -gt 1 ]; then
        echo "Error: Multiple directories found starting with '$TEST_NAME':"
        echo "$matching_dirs"
        exit 1
    fi
    matching_dirs=$(find "out" -maxdepth 1 -type d -name "${TEST_NAME}*" -exec basename {} \;)
    TEST_NAME=$(echo "$matching_dirs" | head -n 1)
    echo "Using directory: $TEST_NAME"
    DIR="out/${TEST_NAME}"
fi


RESULT_DIR="${DIR}/result.d"

cd $RESULT_DIR 2>/dev/null || exit
if [ $RESULT_ONLY -eq 0 ]; then
  echo $(pwd)
fi
spinner() {
  local DELAY=0.05

  while [ 1 ]; do
    echo -n '/'
    sleep $DELAY
    echo -n '-'
    sleep $DELAY
    echo -n '\'
    sleep $DELAY
    echo -n '|'
    sleep $DELAY
  done
}

SPINNER_PID=-1
if [ $# -le 0 ] && [ $RESULT_ONLY -eq 0 ]; then
  spinner &
  SPINNER_PID=$!
fi

RESULT=$(mktemp)
RESULT_LIST=$(ls -1 | grep '[0-9]\+' | sort -n)
echo >>"$RESULT"

parseall() {
  local TITLE="N/A"
  local CACHE_DIR="cache.d"
  local CACHE_FILE="$CACHE_DIR/cache"

  mkdir $CACHE_DIR 2>/dev/null
  touch $CACHE_FILE
  chmod 777 $CACHE_DIR $CACHE_FILE 2>/dev/null

  for i in $RESULT_LIST; do
    if [ "$TITLE" = "N/A" ]; then
      TITLE=$(cat $i | grep '\<vs\>' | sed -e 's/\t//g')
      if [ -z "$TITLE" ]; then
        TITLE="N/A"
      fi
    fi
    if [ ! -f $CACHE_DIR/"$i" ]; then
      local OUTPUT
      OUTPUT=$(awk -f $PARSE "$i")
      if [ -n "$OUTPUT" ]; then
        echo "$OUTPUT" >>$CACHE_FILE
        touch $CACHE_DIR/"$i"
      fi
    fi
  done

  echo $TITLE
  cat $CACHE_FILE
}
parseall | python2.7 $PROCESS $PROCESS_ARGS >>"$RESULT"

if [ $SPINNER_PID -gt 0 ]; then
  exec 2>/dev/null
  kill $SPINNER_PID
fi

cat "$RESULT"
rm -f "$RESULT"
