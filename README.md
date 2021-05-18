# Autotest2d
WrightEagle AutoTest (Has been updated by Cyrus team members)

Thanks go to WrightEagle Members.

### Steps
#### 1- prepare start_team file.
In this script rcssserver automatically runs two teams. start_team file should contain all teams that you would like to test your team with them.

The script sends some parameters to this file to run each team:

```$HOST $PORT $OLCOACH_PORT $RIGHT_TEAM $LEFT_RESULT```

You have to send at least ```$PORT```(Player port) and ```$OLCOACH_PORT```(Coach Port) to the start file of each team.
So the start file of teams should have ability to receive these two ports.

There are some example in the start_team file
```sh
if [[ $TEAM = "cr19" ]]; then
  cd /home/.../CYRUS && ./auto.sh $PORT $OLCOACH_PORT &> "$RESULT"
elif [[ $TEAM = "razi19" ]]; then
  cd /home/.../razi && ./auto.sh $PORT $OLCOACH_PORT &> "$RESULT"
fi
```

#### 2- run tests
You can test two team against together by using the bellowing command:

```commandline
./test -l LEFT_TEAM -r RIGHT_TEAM -p DEFAULT_PORT [-t THREAD] [-ro ROUNDS] [-n TEST_NAME]
```
We suggest to use -n to set a name for your test.
If you don't select name, the script will select "last" as your test name.
All result will be saved in ```out/TestName```.

#### 3- get result
To get result you can run ```result.sh```. This script receives name of test by using -n.
```commandline
./result.sh -n testname
```

#### 4- kill a test
To kill a test contains all process and servers you can use ```kill.sh```.
```commandline
./kill.sh -n testname
```
If you pass "all" as testname, it will kill all tests.
