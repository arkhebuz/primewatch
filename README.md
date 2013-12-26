# PRIMEWATCH
#### *A bash script designed to look after Xolokram Primeminer launched against beeeeer.org pool.* 

## Why? For what?

When I have started mining primecoins on my PC, occasionally two thing were happening: miner hangs during nighttime hours and (much much rarer) miner crashes. Well, there are better things to do at night than watching miner output, so I have searched the net and surprisingly didn't found any useful solution. So here it is, not a cutting edge programming but address three things:
* Is Internet connection working at all? Script periodically pings Google DNS and if errors are returned pings four more servers and check's connection carrier, then writes info to logfile if less than half of packets are received.
* Is miner running at all? If not, launch again.
* Did miner hang somewhere at connection? I had hangs lasting an hour or two with lots of `force reconnect if possible!` or `system:111` communicates (on my box usually one of them was clearly dominating, not both at the same time), without any `\[MASTER\]` line printed to output. Script simply compares line numbers of last `force reconnect if possible!` and `system:111` communicates with line number of last `\[MASTER\]` communicate. If `\[MASTER\]` is not the last one, primeminer is killed, launched on another server and info is written to logs.

## How to
* I'm assuming you have primeminer binary. If not, google it, check peercointalk.org forum, etc.
* Get primewatch script, either copy-paste from this site or use `git clone https://github.com/arkhebuz/primewatch` command. Use `chmod +x primewatch.sh` when necessary.
* **Edit** primewatch.sh file, all this is commented in code. You need to:
  1. Change catalog where logs will be stored;
  2. Set your network interface virtual filesystem catalog (like `/sys/class/net/eth0`);
  3. Set interval in seconds between checks. Should be large enough to let the miner recover under it's own steam if possible. Also, too frequent will make script steal cpu cycles from miner.
  4. Tell the script where primeminer binary is located.
  5. Edit primeminer launch parameters. This script is written with beeeeer.org pool in mind, refer to [http://www.peercointalk.org/index.php?topic=485.msg3304#msg3304](http://www.peercointalk.org/index.php?topic=485.msg3304#msg3304) and my comments in code.
* Launch script, pass to it which beeeeer.org server and port it should use, like `./primewatch.sh us 8080`. You can just leave the terminal on, or use `screen`, or put it in autostart, or do something else. I prefer the second option.
