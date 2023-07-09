#!/bin/bash

# Call this script passing the hostname after;
# set-hostname.sh THE-HOSTNAME-HERE

HOSTNAME=$1

hostnamectl set-hostname ${HOSTNAME}

echo 127.0.0.1  ${HOSTNAME} >> /etc/hosts
echo ::1  ${HOSTNAME} >> /etc/hosts