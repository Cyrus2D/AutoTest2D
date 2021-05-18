#!/bin/bash

CURVE="true"
MAP="true"

TEST_NAME="last"
printHelp() {
  echo "./analyze.sh [-n test_name]"
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
    echo "$1" is not valid
    printHelp
    exit 1
    ;;
  esac
done

DIR="out/last"
RESULT_DIR="${DIR}/result.d"
CURVE_DATA="$RESULT_DIR/curve"
MAP_DATA="$RESULT_DIR/map"
GNUPLOT_CURVE="./scripts/curve.gp"
GNUPLOT_MAP="./scripts/map.gp"

[ -d $RESULT_DIR ] || exit

if [ $CURVE = "true" ]; then
  ./result.sh -n "$TEST_NAME" --curve >"$CURVE_DATA"
  $GNUPLOT_CURVE
else
  echo "$0 -c to output winrate curve"
fi

if [ $MAP = "true" ]; then
  ./result.sh -n "$TEST_NAME" --map >"$MAP_DATA"
  $GNUPLOT_MAP
else
  echo "$0 -m to output score map"
fi
