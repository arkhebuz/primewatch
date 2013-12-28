#!/bin/bash

# Git repositury: https://github.com/arkhebuz/primewatch/
# Readme: https://github.com/arkhebuz/primewatch/README.md
# Donate:  XPM: AV3w57CVmRdEA22qNiY5JFDx1J5wVUciBY
#          DTC: DMy7cMjzWycNUB4FWz2YJEmh8EET2XDvqz

if [ "$#" -ne "2" ] ; then          # Script needs two parameters.
    echo "USAGE:                    ./primewatch.sh SERVER PORT"
    echo "beeeeer.org servers:      us, eu"
    echo "beeeeer.org ports:        1337, 21, 443, 1337, 8080, 13337"
    echo "Example:                  ./primewatch.sh eu 1337"
    echo "WARNING: you have to edit script if you haven't do so."
    exit
fi

# Catalog where logs will be stored.
logkat="/home/arkhebuz/primecoin"

# Catalog corresponding to network interface you are using, containing carrier file (like /sys/class/net/eth0/carrier) having value of either 1 if network is up or 0 if it's down.
netinterface="/sys/class/net/eth0"

# Interval in seconds bettwen checks, too small will make the script steal cpu cycles and usually won't let the miner recover under its own steam when possible. Ten minutes is good enough in my expirence.
sleeptime=600

function minerlaunch {
    if [ "$1" = "eu" ] ; then
        ip="176.34.128.129" #server europa ip
    elif [ "$1" = "us" ] ; then
        ip="54.200.248.75"  #server usa ip
    fi
    filename=$(date +%F_%H.%M.%S)
    
    # Miner settings. Adjust to yourself. Quick overview:
    # ./primeminer                                                          <-- Xolokram primeminer binary location. Default is in the same catalog as this script when launched as ./primewatch.sh SERVER PORT
    # -pooluser=AV3w57CVmRdEA22qNiY5JFDx1J5wVUciBY                          <-- XPM address.
    # -genproclimit="8"                                                     <-- Number of threads to use.
    # -poolfee="3"                                                          <-- Adjust beeeeer.org fee, from 1 to 100, default 3%
    # -sievesize="1000000" -sieveextensions="10" -sievepercentage="9"       <-- These parameters affect mining. Nobody wants to say what this three are exactly doing. Mayby nobody knows?
    #                                                                           For me it works little better with these values. Either play with them or cut this three out.
    # Note: don't change -poolip=$ip and -poolport=$2 unless you know how this script is working.
    ./primeminer -poolip=$ip -poolport=$2 -pooluser=AV3w57CVmRdEA22qNiY5JFDx1J5wVUciBY -genproclimit="8" -poolfee="3" -sievesize="1000000" -sieveextensions="10" -sievepercentage="9" 2>&1 | tee -a $logkat/$filename &
}

# 5 DNS servers for a very "finesse" connection checking... No need to change them.
google1=8.8.8.8         # <-- this one is checked first - if it's ok, the rest is omnitted.
google2=8.8.4.4
opendns1=208.67.222.222
level3=209.244.0.3
comodo=8.26.56.26

hammer=$1 # you can't touch this

while true ; do
    # Checking for primeminer process, launching if not found.
    islive=$(pgrep primeminer)
    if [ -z "$islive" ] ; then
        echo -n "primeminer not found, launching... "
        minerlaunch $hammer $2
        echo "PID: $(pgrep primeminer)"
    fi
    
    ping=$(ping -q -w2 -c2 $google1 | grep -o -P ".{0,2}received" | head -c 1)
    if [ "1" -ge "$ping" ] ; then             # Ping Google to check internet, if problems proceed. 
        n=0
        carrier=$(cat $netinterface/carrier)
        
        for ip in $google2 $opendns1 $level3 $comodo ; do           # Checking rest of ip's, each two times, eight pings total.
            i=$(ping -q -w2 -c2 $ip | grep -o -P ".{0,2}received" | head -c 1)
            n=$[n+i]
        done
        
        if [ "$n" -le "5" -a "$n" -gt "0" ] ; then          # [1-4] out of 8 ping receieved, write to logs.
            echo "$(date) : conection problems, only $n packets received, carrier = $carrier" 2>&1 | tee -a $logkat/$filename
            echo "$(date) : conection problems, only $n packets received, carrier = $carrier" >> $logkat/netlog
        elif [ "$n" -eq "0" ] ; then            # Zero pings received, write to logs.
            echo "$(date) : fatal conection problems - connection lost, carrier = $carrier" 2>&1 | tee -a $logkat/$filename
            echo "$(date) : fatal conection problems - connection lost, carrier = $carrier" >> $logkat/netlog
        fi
    fi
    
    # I had long lasting hangs with "force reconnect if possible!" communicate on my box.
    connection_lost=$(grep -in "force reconnect if possible" "$logkat/$filename" | sed 's/[^0-9.]*\([0-9.]*\).*/\1/; $!d')        # Get line number of last "force reconnect if possible" comm.
    
    # I had hangs with "system:111" communicate too. Works like above.
    system111_comm_hang=$(grep -in "system:111" "$logkat/$filename" | sed 's/[^0-9.]*\([0-9.]*\).*/\1/; $!d')
    
    # In case when miner can't connect even at beggining, I guess. Thats when I see 'system:110'.
    system110_cant_connect=$(grep -in "system:110" "$logkat/$filename" | sed 's/[^0-9.]*\([0-9.]*\).*/\1/; $!d')
    
    # Get last [MASTER] communicate line number.
    masterline=$(grep -in "master" "$logkat/$filename" | sed 's/[^0-9.]*\([0-9.]*\).*/\1/; $!d')
    if [ -z "$masterline" ] ; then masterline=1; fi
    
    for hangs in connection_lost system111_comm_hang system110_cant_connect; do
        if [ -z "${!hangs}" ] ; then eval $hangs=0; fi
        if [ "${!hangs}" -gt "$masterline" ] ; then
            # If theres no "[MASTER]" somewhere after error communicate then kill primeminer, write to logs and start on another server. Works good with long enough sleeptime.
            echo "$(date) : primeminer $hangs, line: ${!hangs} (last master: $masterline)" 2>&1 | tee -a $logkat/$filename
            echo "$(date) : primeminer $hangs, line: ${!hangs} (last master: $masterline)" >> $logkat/netlog
            if [ "$hammer" = "eu" ] ; then  # If you wondered what hammer is for...
                hammer="us"
            else
                hammer="eu"
            fi
            pkill primeminer
            minerlaunch $hammer $2
            break
        fi
    done
    
    sleep $sleeptime
done
