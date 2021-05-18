#!/bin/bash

CURVE="true"
MAP="true"
DIR="out"
USE_SCREEN=0
printHelp(){
  echo "./analyze.sh [-s SESSION_NAME]"
}

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -s|--screen)
    DIR="out_$2"
    USE_SCREEN=1
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

RESULT_DIR="${DIR}/result.d"
CURVE_DATA="$RESULT_DIR/curve"
MAP_DATA="$RESULT_DIR/map"
GNUPLOT_CURVE="./scripts/curve.gp"
GNUPLOT_MAP="./scripts/map.gp"

[ -d $RESULT_DIR ] || exit

if [ $CURVE = "true" ]; then
  if [ $USE_SCREEN ]; then
    ./result.sh -s "$SESSION_NAME" --curve > "$CURVE_DATA"
  else
    ./result.sh --curve > "$CURVE_DATA"
  fi
  $GNUPLOT_CURVE
else
    echo "$0 -c to output winrate curve"
fi

if [ $MAP = "true" ]; then
  if [ $USE_SCREEN ]; then
    ./result.sh -s "$SESSION_NAME" --map > "$MAP_DATA"
  else
    ./result.sh --map > "$MAP_DATA"
  fi
  $GNUPLOT_MAP
else
    echo "$0 -m to output score map"
fi