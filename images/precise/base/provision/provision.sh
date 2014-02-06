#!/bin/bash
## Copyright 2014 Ooyala, Inc. All rights reserved.
##
## This file is licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
## except in compliance with the License. You may obtain a copy of the License at
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software distributed under the License is
## distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and limitations under the License.


set -ex

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# make sure everything is owned by root
chown -R root:root ${SCRIPT_DIR}

cd ${SCRIPT_DIR}

# Add apt sources
echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ precise-updates main restricted" > /etc/apt/sources.list.d/precise-update.list
apt-get update

# Install runit (it will fail, that is why the || true is there)
apt-get install -y runit || true
# Fix runit
rm /var/lib/dpkg/info/runit.post*
apt-get -f install

# Install rebuild_authorized_keys
mv sbin/* /usr/local/sbin/
rm -rf sbin

mv etc/sv/* /etc/sv/
mv etc/atlantis /etc
# Make config directory
mkdir -p /etc/atlantis/config
chown -R root:root /etc/atlantis
chown -R root:root /etc/sv


# Add SSH under runit
apt-get install -y openssh-server
mkdir -p /root/.ssh
chmod 700 /root/.ssh
mv ssh/* /root/.ssh/
rm -rf ssh
chmod 600 /root/.ssh/authorized_keys
ln -s /etc/sv/sshd /etc/service/

# Add rsyslog under runit
apt-get install -y rsyslog
mv etc/rsyslog.conf /etc
mkdir /etc/sv/rsyslog
ln -s /etc/sv/rsyslog /etc/service
# make log directory
mkdir -p /var/log/atlantis/syslog

# Add convenience packages
apt-get -y install build-essential curl man-db telnet wget screen tmux tree less strace traceroute ngrep tcpdump vim

rm -rf etc

# Add app user
useradd -d /home/user1 -m -s /bin/bash user1

# run provision.extra.sh if it exists
if [ -x "./provision.extra.sh" ]; then
  ./provision.extra.sh
fi

echo "provisioning base done."
