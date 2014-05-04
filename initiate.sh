#!/bin/bash

# example: sh initiate.sh 54.193.39.196 192.168.51.0/24 192.168.16.0/24 2

# the remote server user
# ip and path to setup script
TARGET_USER="root"
TARGET=$1

# what is the local network we want the remote host to route to us
LOCAL_NETWORK=$2

# the remote network we are going to route to us
TARGET_NETWORK=$3

# which tunnel number to use
TUN=$4
DEVICE="tun$TUN"

# the IPs to use for the tunnel
LOCAL_TUN_IP="10.0.$TUN.1"
TARGET_TUN_IP="10.0.$TUN.2"

TARGET_COMMAND="bash -c 'ifconfig $DEVICE $TARGET_TUN_IP/24 && ifconfig $DEVICE up && ifconfig $DEVICE pointopoint $LOCAL_TUN_IP && ifconfig $DEVICE multicast && ip route add $LOCAL_NETWORK via $TARGET_TUN_IP dev $DEVICE'"

function check_pid() {
    kill -0 $1 > /dev/null 2>&1
    if [[ "$?" -eq 0 ]]
    then
        return 0 # it's reversed in bash
    else
        return 1
    fi
}

function check_arg {
    if [ -z "$1" ]
    then
        echo $2
        echo "Tunnel FAILED!"
        exit 1
    fi
}

function check_ping {
    ping -c 1 $1 > /dev/null 2>&1
    return $?
}

check_arg $TARGET "must specify a target"
check_arg $LOCAL_NETWORK "must specify a local network"
check_arg $TARGET_NETWORK "must specify a target network"
check_arg $TUN "must specify a tunnel device number"

ip link show $DEVICE > /dev/null 2>&1
if [[ "$?" -eq 0 ]]
then
    echo "$DEVICE already in use"
    echo "Tunnel FAILED!"
    exit 1
fi

ssh -n -TC -w$TUN:$TUN $TARGET_USER@$TARGET $TARGET_COMMAND &
SSH_PID=$!
trap "kill $SSH_PID; exit" SIGHUP SIGINT SIGTERM

count=0
while check_pid $SSH_PID
do
    if [[ "$count" -gt 30 ]]
    then
        echo "Tunnel FAILED!"
        kill $SSH_PID
        exit 1
    fi

    ip link show $DEVICE > /dev/null 2>&1
    if [[ "$?" -eq 0 ]]
    then
        echo "Tunnel OK"
        ifconfig $DEVICE $LOCAL_TUN_IP/24
        ifconfig $DEVICE up
        ifconfig $DEVICE pointopoint $TARGET_TUN_IP
        ifconfig $DEVICE multicast
        route add -net $TARGET_NETWORK gw $LOCAL_TUN_IP dev $DEVICE
        check_ping $TARGET_TUN_IP
        if [[ "$?" -ne 0 ]]
        then
            echo "Could not ping remote tunnel IP $TARGET_TUN_IP"
            echo "Tunnel FAILED!"
            kill $SSH_PID
            exit 1
        fi
        echo "Network/routing to $TARGET_NETWORK is UP"
        wait $SSH_PID
        exit
    else
        sleep 1
        (( count++ ))
    fi
done

echo "Tunnel FAILED!"
kill $SSH_PID > /dev/null 2>&1
exit 1
