# Autotest2d

WrightEagle AutoTest (Has been updated by Cyrus team members)

This repository helps you to test your team against other teams in 2D soccer simulation league.
You can run many games in parallel and get the result of each game.

Thanks go to WrightEagle Members.

## Steps

### 0- Clone the repository

```bash
git clone --recurse-submodules git@github.com:Cyrus2D/AutoTest2D.git
```

### 1- prepare start_team file

In this script rcssserver automatically runs two teams. start_team file should contain all teams that you would like to test your team with them.

Note: if you clone the repository with ```--recurse-submodules```, some sample binaries of teams will be cloned too such as `helios2024`, `cyrus2024`, `yushan2024`, `helios_base` and many others in the future.

The script sends some parameters to this file to run each team:

```bash
while getopts "h:p:P:t:r:b:R:T:" opt; do
  case $opt in
  h) HOST=$OPTARG ;;
  p) PORT=$OPTARG ;;
  P) OLCOACH_PORT=$OPTARG ;;
  t) TEAM=$OPTARG ;;
  r) RESULT=$OPTARG ;;
  b) BIN=$OPTARG ;;
  R) RPC_PORT=$OPTARG ;;
  T) RPC_TYPE=$OPTARG ;;
  \?) echo "Invalid option -$OPTARG" ;;
  esac
done
```

You have to send at least ```$PORT```(Player port) and ```$OLCOACH_PORT```(Coach Port) to the start file of each team.
So the start file of teams should have ability to receive these two ports.

There are some example in the start_team file

```bash
if [[ $TEAM = "cr19" ]]; then
  cd /home/.../CYRUS && ./auto.sh $PORT $OLCOACH_PORT &> "$RESULT"
elif [[ $TEAM = "razi19" ]]; then
  cd /home/.../razi && ./auto.sh $PORT $OLCOACH_PORT &> "$RESULT"
fi
```

### 2- run tests

You can test two team against together by using the bellowing command:

```bash
./test -l LEFT_TEAM -r RIGHT_TEAM -p DEFAULT_PORT [-t THREAD] [-ro ROUNDS] [-n TEST_NAME]
```

For example:

```bash
./test -l helios2024 -r cyrus2024 -p 6000 -t 10 -ro 10 -n test1
```

We suggest to use -n to set a name for your test.
If you don't select name, the script will select "last" as your test name.
All result will be saved in ```out/TestName```.

### 3- get result

To get result you can run ```result.sh```. This script receives name of test by using -n.

```bash
./result.sh -n testname
```

### 4- kill a test

To kill a test contains all process and servers you can use ```kill.sh```.

```bash
./kill.sh -n testname
// or
./kill.sh all // to kill all tests
```

If you pass "all" as testname, it will kill all tests.
