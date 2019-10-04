#!/bin/bash
set -o errexit -o nounset -o pipefail
function -h {
cat <<\USAGE
 USAGE: haproxy_cfg.sh <backend>:<port>

haproxy_cfg.sh generates a config file to run HAProxy on localhost and proxy to a number of backend hosts.

To gracefully reload haproxy:

:; haproxy -f /path/to/config -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)

USAGE
}; function --help { -h ;}

function header {
  cat <<EOF
global
        log stdout  local0  info
        #log /dev/log    local0
        #log /dev/log    local1 notice
        chroot /tmp
        #user haproxy
        #group haproxy
        daemon

defaults
        log     global
        hash-type consistent
        #option tcplog
        maxconn 0
        #option  httplog
        option  dontlognull
        timeout connect 1000
#        timeout client  3h
#        timeout server  3h
        timeout client  300s
        timeout server  300s
        default-server init-addr none


frontend fe_relay
EOF
}

function middle {
  cat <<EOF
    mode tcp
    option socket-stats

    default_backend be_def

backend be_def
    mode tcp
EOF
}

function tail {
  cat <<EOF

resolvers docker
    nameserver local 127.0.0.11:53
    resolve_retries 3
    timeout retry 1s
    hold other 30s
    hold refused 30s
    hold nx 30s
    hold timeout 30s
    hold valid 10s

EOF
}

## bind :<port>
function comma_split {
  IFS=','
  count=0
  for port in $2
  do
    count=$((1+$count))
    prefix=`echo $1 | sed "s/_x/_$count/"`
    cat <<EOF
  $prefix$port$3
EOF
  done
}

function config {
  header
  comma_split "bind :" $PORTS ""
  middle
  comma_split "server server_x " $BACKENDS " $BACKEND_OPTS"
  tail
}

function msg { out "$*" >&2 ;}
function err { local x=$? ; msg "$*" ; return $(( $x == 0 ? 1 : $x )) ;}
function out { printf '%s\n' "$*" ;}

if [[ ${1:-} ]] && declare -F | cut -d' ' -f3 | fgrep -qx -- "${1:-}"
then "$@"
else config "$@"
fi
