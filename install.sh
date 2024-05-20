#!/usr/bin/env bash

# Host machine IP
IP="$1"

# Make sure your machine is up to date
apt-get update
apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget openssl

# Go into the /tmp folder and download the source
cd /tmp
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-4.1.0.tar.gz
tar xzf nrpe.tar.gz

#Compile 
cd /tmp/nrpe-nrpe-4.1.0/
./configure --enable-command-args --enable-bash-command-substitution --with-ssl-lib=/usr/lib/x86_64-linux-gnu/
make all
 
# Create user and group 
make install-groups-users

# Install binaries and configurations 
make install
make install-config

# Update the services file 
echo >> /etc/services
echo '# Nagios services' >> /etc/services
echo 'nrpe    5666/tcp' >> /etc/services

# Install Service/Daemon
make install-init
systemctl enable nrpe.service

# Open port 5666
mkdir -p /etc/ufw/applications.d
echo '[NRPE]' > /etc/ufw/applications.d/nagios
echo 'title=Nagios Remote Plugin Executor' >> /etc/ufw/applications.d/nagios
echo 'description=Allows remote execution of Nagios plugins' >> /etc/ufw/applications.d/nagios
echo 'ports=5666/tcp' >> /etc/ufw/applications.d/nagios
ufw allow NRPE
ufw reload

# Add the Nagios Core machine IP separated by a comma to allowed hosts. This will allow the Core machine to check Your VM.
sed -i '/^allowed_hosts=/s/$/,'"$IP"'/' /usr/local/nagios/etc/nrpe.cfg

#Change the row dont_blame_nrpe= to dont_blame_nrpe=1, which allows more specific configurations.
sed -i 's/^dont_blame_nrpe=.*/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg

# Start the Service/Daemon
systemctl start nrpe.service

# Furthermore, plugins are needed, so install them using the following commands.
apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.4.6.tar.gz
tar zxf nagios-plugins.tar.gz

cd /tmp/nagios-plugins-release-2.4.6/
./tools/setup
./configure
make
make install

echo "command[run_script]=/usr/bin/bash -c '\$ARG1\$'" >> '/usr/local/nagios/etc/nrpe.cfg'
echo 'nasty_metachars=ˇ' >> '/usr/local/nagios/etc/nrpe.cfg'
sed -i 's/^allow_bash_command_substitution=.*/allow_bash_command_substitution=1/g' '/usr/local/nagios/etc/nrpe.cfg'

usermod -aG ubuntu nagios

systemctl restart nrpe.service