#!/bin/bash

set -e

run_command() {
  echo "Running $1"
  bash -c "$1" 2>&1 &
  HAPROXY_PID="$!"
}

reload_conf() {
  PREV_MD5=$(md5sum /etc/haproxy/haproxy.cfg | awk '{print $1}')
  CFG_SUCCESS=1
  haproxy.cfg.sh > /etc/haproxy/haproxy.cfg.next || CFG_SUCCESS=0
  haproxy -c -V -f /etc/haproxy/haproxy.cfg.next || CFG_SUCCESS=0
  if [ $CFG_SUCCESS -ne 1 ]; then
      echo "Error generating config"
      return
  fi


  CURR_MD5=$(md5sum /etc/haproxy/haproxy.cfg.next | awk '{print $1}')
  if [ "${PREV_MD5}" = "${CURR_MD5}" ]; then
      echo "Config is the same"
      return
  fi

  mv /etc/haproxy/haproxy.cfg.next /etc/haproxy/haproxy.cfg

  echo "Reloading conf"
  run_command "haproxy -f /etc/haproxy/haproxy.cfg -st $HAPROXY_PID"
}

onexit() {
  echo Sending SIGTERM to haproxy
  kill $HAPROXY_PID &>/dev/null
  sleep 1
}
trap onexit SIGINT SIGTERM EXIT

#if [ $RELOAD_TTL -gt 0 ] 
#then
#  echo "Reload config every $RELOAD_TTL seconds"
#else
#  RELOAD_TTL=30
#  echo "Reload config every $RELOAD_TTL seconds"
#fi

if [ -z "$BACKEND_OPTS" ]
then
  BACKEND_OPTS="resolvers docker send-proxy"
fi

reload_conf

run_command "haproxy -f /etc/haproxy/haproxy.cfg"
#while true; do ; sleep $RELOAD_TTL; done
