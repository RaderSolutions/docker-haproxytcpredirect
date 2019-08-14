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
        #log /dev/log    local0
        #log /dev/log    local1 notice
        chroot /tmp
        #user haproxy
        #group haproxy
        daemon

        # Default SSL material locations
        #ca-base /etc/ssl/certs
        #crt-base /etc/ssl/private

        # Default ciphers to use on SSL-enabled listening sockets.
        # For more information, see ciphers(1SSL).
        #ssl-default-bind-ciphers kEECDH+aRSA+AES:kRSA+AES:+AES256:RC4-SHA:!kEDH:!LOW:!EXP:!MD5:!aNULL:!eNULL
        #ssl-default-bind-options no-sslv3

defaults
        #log     global
        hash-type consistent
        option tcplog
        maxconn 1000
        #option  httplog
        option  dontlognull
        timeout connect 5000
#        timeout client  3h
#        timeout server  3h
        timeout client  900s
        timeout server  900s
        default-server init-addr none


frontend fe_relay
EOF
}

function middle {
  cat <<EOF
    mode tcp
    #option clitcpka
    option tcplog
    option socket-stats
    # option nolinger
    #maxconn  300

    default_backend be_def

backend be_def
    mode tcp
    hash-type consistent
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
