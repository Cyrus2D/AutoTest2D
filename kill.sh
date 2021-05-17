#!/bin/bash

if [ $# = 1 ]; then
  screen -XS $1 quit
else
  exec 2>/dev/null
  killall -9 test.sh
  killall -9 rcssserver
  killall -9 rcssserver.bin
  rm -f "/tmp/autotest::temp"
fi
