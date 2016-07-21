#!/bin/bash
echo "---- Starting Up Service ---- "


if [ "$LK_RANCHER_SERVICE_DISCOVERY" ]; then
  sleep 1

  function get_service {
    curl -sS --header "accept: application/json" http://rancher-metadata.rancher.internal/latest/$1
  }

  env=$( get_service "self/stack" )
  rabbit=$( get_service "services/rabbit" )

  IFS='-' read -ra NAMES <<< $( echo $env | jq -r '.environment_name' )
  env_vnet=$( echo ${NAMES[0]} )
  env_instance=$( echo ${NAMES[1]} )
  env_name=$( echo $env | jq -r '.name')

  # setup all of the environment variable
  if [ -z "$LK_ENVIRONMENT" ]; then
    export LK_ENVIRONMENT=$( echo $env_instance )
  fi

  if [ -z "$RABBITMQ_HOST" ]; then
    export RABBITMQ_HOST=rabbit.rabbit.rancher.internal
  fi
  if [ -z "$RABBITMQ_PORT" ]; then
    export RABBITMQ_PORT=$( echo $rabbit | jq -r '.labels["io.leankit.service.port.amqp"]' | sed -e 's/\/\(tcp\|udp\)//' )
  fi
  if [ -z "$RABBITMQ_USER" ]; then
    export RABBITMQ_USER=$( echo $rabbit | jq -r '.labels["io.leankit.service.username"]' )
  fi
  if [ -z "$RABBITMQ_PASS" ]; then
    export RABBITMQ_PASS=$( echo $rabbit | jq -r '.labels["io.leankit.service.password"]' )
  fi
  if [ -z "$RABBITMQ_VHOST" ]; then
    export RABBITMQ_VHOST=$( echo $rabbit | jq -r '.labels["io.leankit.service.vhost"]' )
  fi

fi

# print out all of the environment variables
echo "#### entry.sh - Start Dump Variables ####"
env
echo "#### entry.sh - End Dump Variables ####"

# Execute the commands passed to this script
exec "$@"
