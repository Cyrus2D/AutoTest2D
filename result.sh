#!/bin/bash

PARSE="../../../scripts/parse.awk"
PROCESS="../../../scripts/process.py"
TEST_NAME="last"

printHelp(){
  echo "./result.sh [-n TEST_NAME] [process options]"
}
PROCESS_ARGS=""
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -n|--name)
    TEST_NAME="$2"
    shift 2
    ;;
    -C|--console)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
    -N|--no-color)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
    -D|--discuz)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
    -H|--html)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
    -S|--simplify)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
    -A|--curve)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
    -M|--map)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
    shift 1
    ;;
    -T|--temp)
    PROCESS_ARGS="${PROCESS_ARGS}$1 "
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
DIR="out/${TEST_NAME}"
RESULT_DIR="${DIR}/result.d"

cd $RESULT_DIR 2>/dev/null || exit
echo `pwd`
spinner() {
    local DELAY=0.05

    while [ 1 ]; do
        echo -n '/' ; sleep $DELAY
        echo -n '-' ; sleep $DELAY
        echo -n '\' ; sleep $DELAY
        echo -n '|' ; sleep $DELAY
    done
}

SPINNER_PID=-1
if [ $# -le 0 ]; then
    spinner &
    SPINNER_PID=$!
fi

RESULT=$(mktemp)
RESULT_LIST=`ls -1 | grep '[0-9]\+' | sort -n`
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
            TITLE=`cat $i | grep '\<vs\>' | sed -e 's/\t//g'`
            if [ -z "$TITLE" ]; then
                TITLE="N/A"
            fi
        fi
        if [ ! -f $CACHE_DIR/$i ]; then
            local OUTPUT=`awk -f $PARSE $i`
            if [ ! -z "$OUTPUT" ]; then
                echo "$OUTPUT" >>$CACHE_FILE
                touch $CACHE_DIR/$i
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

