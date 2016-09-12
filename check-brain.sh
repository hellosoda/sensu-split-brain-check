#!/bin/bash

#
# sensu check for split brain syndrome in akka cluster
#
# usage:
# ./check_brain.sh 172.17.0.8 172.17.0.9 172.17.0.10 172.17.0.11
# or
# AKKA_CLUSTER_NODES="172.17.0.8 172.17.0.9 172.17.0.10 172.17.0.11" ./check_brain.sh
#
#
# Exit status code indicates state
#
#    0 indicates OK
#    1 indicates WARNING
#    2 indicates CRITICAL
#    exit status codes other than 0, 1, or 2 indicate an UNKNOWN or custom status
#
# (see https://sensuapp.org/docs/latest/reference/checks.html)
#
# brain is splitted when any of nodes sees different cluster state than others

AKKA_HOME=${AKKA_HOME:-/opt/akka-2.4.7/}
JMX_PORT=${JMX_PORT:-9999}

if [ -z "$1" -a -z "$AKKA_CLUSTER_NODES" ]
  then
    echo "Usage: $0 172.17.0.8 172.17.0.9 172.17.0.10 172.17.0.11"
    echo "or"
    echo "AKKA_CLUSTER_NODES=\"172.17.0.8 172.17.0.9 172.17.0.10 172.17.0.11\" $0"
    exit 13
fi

NODES="${AKKA_CLUSTER_NODES:-"$@"}"

# http://www.linuxjournal.com/content/validating-ip-address-bash-script
#
# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


for ip in $(echo $NODES| tr " " "\n"); do
  if ! valid_ip $ip; then
    echo "Incorrent ip:" $ip
    exit 14
  fi
done



# list of nodes visible from node
# e.g
# who_sees_node "172.17.0.8" returns "akka.tcp://application@172.17.0.10:2551 akka.tcp://application@172.17.0.8:2551"
function who_sees_node() {
  local ip=$1
  $AKKA_HOME/bin/akka-cluster $ip $JMX_PORT cluster-status | tail -n +2 | jq -r '.members[] | .address' -  | sort | uniq
}


declare -A cluster
all_equals=true

for ip in $(echo $NODES| tr " " "\n"); do
  current=$(who_sees_node $ip)
  cluster[$ip]=$current
  if [ -n "$last_checked" -a "$last_checked" != "$current" ]; then
    all_equals=false
  fi
  last_checked=$current
done

if $all_equals; then
  echo "Cluster OK"
  exit 0;
else
  #print cluster state, who sees who
  for ip in "${!cluster[@]}"; do echo $ip "-->" ${cluster[$ip]}; done
  exit 2; #critical
fi


