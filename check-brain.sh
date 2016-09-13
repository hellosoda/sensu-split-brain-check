#!/bin/bash
#
# sensu check for split brain syndrome in akka cluster
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

function nodes() {
  local services=("discovery-api-service" "discovery-plugins-service")

  for service in "${services[@]}"
  do
    local task=$(aws ecs list-tasks --cluster discovery --service-name $service | jq -r '.taskArns[0]')
    if [[ -z "$task" ]]; then
        continue
    fi
    local taskdesc=$(aws ecs describe-tasks --cluster discovery --tasks $task)
    local cont=$(echo $taskdesc | jq -r '.tasks[0].containerInstanceArn')
    local jmx_port=$(echo $taskdesc | jq -r '.tasks[0].containers[0].networkBindings | map ( .hostPort | select( . > 9000) )[0] ')
    local inst=$(aws ecs describe-container-instances --cluster discovery --container-instances $cont | jq -r '.containerInstances[0].ec2InstanceId')
    local ip=$(aws ec2 describe-instances --instance-ids $inst | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')
    echo $ip:$jmx_port
  done
}

NODES=$(nodes)

# list of nodes visible from node
# e.g
# members "172.17.0.8:9999" returns "akka.tcp://application@172.17.0.10:2551 akka.tcp://application@172.17.0.8:2551"
function members() {
  local ip=$(echo $1 | cut -f1 -d:)
  local jmx_port=$(echo $1 | cut -f2 -d:)
  local cluster_status=$($AKKA_HOME/bin/akka-cluster $ip $jmx_port cluster-status | tail -n +2)
  echo $cluster_status | jq -r '.members[] | .address' -  | sort | uniq
}


declare -A cluster
all_equals="yes"

for address in $(echo $NODES| tr " " "\n"); do
  current=$(members $address)
  cluster[$address]=$current
  if [ -n "$last_checked" -a "$last_checked" != "$current" ]; then
    all_equals="nope"
  fi
  last_checked=$current
done

if [ -n "$last_checked" -a "$all_equals" = "yes" ]; then
  echo "Cluster OK"
  exit 0;
else
  #print cluster state, who sees who
  for ip in "${!cluster[@]}"; do echo $ip "-->" ${cluster[$ip]:-"nobody"}; done
  exit 2; #critical
fi


