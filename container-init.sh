#!/bin/bash
#
# Copyright (C) 2022 Rafael Zalamena
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

set -e

fatal() {
	echo "%% $1" >&2
	exit 1
}

# This script should be run every container initialization and it does
# basic Linux configuration for running and debugging FRR.
#
# It is expected that interface `eth0` is connected with docker bridge
# and all others are connected with other FRR instances.

# Mark source directory as safe for git
if [ ! -f /root/.gitconfig ]; then
  git config --global --add safe.directory /usr/src/frr
fi

# Compile and install FRR
if [ ! -f /usr/lib/frr/watchfrr.sh ]; then
  /usr/sbin/frr-build.sh --asan --doc --fpm --grpc --snmp >/dev/null || true
fi

# Configure core dumps
if [ ! -f /root/.limits_configured ]; then
  echo '* soft core 0' >> /etc/security/limits.conf
  echo '* hard core 0' >> /etc/security/limits.conf
  touch /root/.limits_configured
fi

# Always reconfigure sysctls
# Configure core dumps
sysctl kernel.core_pattern='/var/log/frr/%e-%P'
# Bump IGMP group membership count (needed for 3+ interfaces)
sysctl net.ipv4.igmp_max_memberships=1000
# Enable IPv6
sysctl net.ipv6.conf.all.disable_ipv6=0

# Bump tmux default history limit.
if [ ! -f /root/.tmux.conf ]; then
  echo 'set -g history-limit 10000' > /root/.tmux.conf
fi

# Remove all docker addresses from non Internet interface.
interfaces=$(ip link \
  | egrep "eth[1-9]+" \
  | cut -d ':' -f 2 \
  | cut -d '@' -f 1 \
  | sed -r 's/^ +//g')

for interface in $interfaces; do
  ip addr flush dev $interface
done

exit 0
