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

  if [ -z "$LK_AUTH_USER_ENDPOINT_PROTOCOL" ]; then
    export LK_AUTH_USER_ENDPOINT_PROTOCOL=https
  fi

  if [ -z "$LK_RABBIT_HOST" ]; then
    export LK_RABBIT_HOST=rabbit.rabbit.rancher.internal
  fi
  if [ -z "$LK_RABBIT_PORT" ]; then
    export LK_RABBIT_PORT=$( echo $rabbit | jq -r '.labels["io.leankit.service.port.amqp"]' | sed -e 's/\/\(tcp\|udp\)//' )
  fi
  if [ -z "$LK_RABBIT_USER" ]; then
    export LK_RABBIT_USER=$( echo $rabbit | jq -r '.labels["io.leankit.service.username"]' )
  fi
  if [ -z "$LK_RABBIT_PASS" ]; then
    export LK_RABBIT_PASS=$( echo $rabbit | jq -r '.labels["io.leankit.service.password"]' )
  fi
  if [ -z "$LK_RABBIT_VHOST" ]; then
    export LK_RABBIT_VHOST=$( echo $rabbit | jq -r '.labels["io.leankit.service.vhost"]' )
  fi
fi

# print out all of the environment variables
echo "#### entry.sh - Start Dump Variables ####"
env
echo "#### entry.sh - End Dump Variables ####"

# Execute the commands passed to this script
exec "$@"
