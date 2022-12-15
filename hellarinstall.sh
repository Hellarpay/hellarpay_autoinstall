#!/bin/bash
#
# Copyright (C) 2022 Hellarpay Team
#
# Hellarpay Masternode installation script, by Hellarpay.
#
# Only Ubuntu 16.04 supported at this moment (tested with 18.04, Debian 9 working)

set -o errexit

# OS_VERSION_ID=`gawk -F= '/^VERSION_ID/{print $2}' /etc/os-release | tr -d '"'`

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef"-o Dpkg::Options::="--force-confold" upgrade
sudo apt install curl wget git python3 python3-pip virtualenv -y

HEL_DAEMON_USER_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo ""`
HELIQ_DAEMON_RPC_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 ; echo ""`
HELMN_NAME_PREFIX=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6 ; echo ""`
HELMN_EXTERNAL_IP=`curl -s -4 ifconfig.co`

sudo useradd -U -m hellar -s /bin/bash
sudo echo "hellar:${HEL_DAEMON_USER_PASS}"| sudo chpasswd
sudo wget https://github.com/hellarpay/releases/download/v0.1.0.0/hellar-0.1.0-x86_64-linux-gnu.tar.gz --directory-prefix /home/hellar/
sudo tar -xzvf /home/hellar/hellar-0.1.0-x86_64-linux-gnu.tar.gz -C /home/hellar/
sudo rm /home/hellar/hellar-0.1.0-x86_64-linux-gnu.tar.gz
sudo mkdir /home/hellar/.hellarcore/
sudo chown -R hellar:hellar /home/hellar/hellar*
sudo chmod 755 /home/hellar/hellar*
echo -e "rpcuser=hellarrpc\nrpcpassword=${HELIQ_DAEMON_RPC_PASS}\nlisten=1\nserver=1\nrpcallowip=127.0.0.1\nmaxconnections=256"  | sudo tee /home/hellar/.hellar/hellar.conf
sudo chown -R hellar:hellar /home/hellar/.hellarcore/
sudo chown 500 /home/hellar/.hellarcore/hellar.conf
sudo mv /home/hellar/hellar-0.1.0/bin/hellar-cli /home/hellar/
sudo mv /home/hellar/hellar-0.1.0/bin/hellard /home/hellar/

sudo tee /etc/systemd/system/hellar.service <<EOF
[Unit]
Description=Hellar, World Wide Cryptocurrency
After=network.target
[Service]
User=hellar
Group=hellar
WorkingDirectory=/home/hellar/
ExecStart=/home/hellar/hellard
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=2s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable hellar
sudo systemctl start hellar
echo "Booting HELLAR node and creating wallet, please wait!"
sleep 120

echo "Now open your Hellar wallet, go to Console, and type "masternode genkey" and "bls generate"!"
echo "Now from local wallet paste your genkey and bls priv key!"
read MNGENKEY
read BLSGENKEY
echo -e "masternode=1\nmasternodeprivkey=${MNGENKEY}\nmasternodeblsprivkey=${BLSGENKEY}\nexternalip=${SIBMN_EXTERNAL_IP}:1945" | sudo tee -a /home/hellar/.hellar/hellar.conf
sudo systemctl restart hellar

echo "Installing sentinel engine, please standby!"
sudo gitclone https://github.com/ivansib/sentinel.git /home/hellar/hellar/
sudo chown -R hellar:hellar /home/hellar/sentinel/
cd /home/hellar/sentinel/
echo -e "hellar_conf=/user/hellar/.hellar/hellar.conf" | sudo tee -a /home/hellar/sentinel/sentinel.conf
sudo -H -u hellar virtualenv -p python3 ./venv
sudo virtualenv venv
sudo ./venv/bin/pip install -r requirements.txt

echo "* * * * * cd /home/hellar/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" | sudo tee /etc/cron.d/hellar_sentinel
sudo chmod 644 /etc/cron.d/hellar_sentinel

echo " "
echo " "
echo "==============================="
echo "HEL v.10 Masternode installed by HELLAR Rux Script"
echo "==============================="
echo "Copy and keep that information in secret:"
echo "Masternode key: ${MNGENKEY}"
echo "BLS key: ${BLSGENKEY}"
echo "SSH password for user \"hellar\": ${SIB_DAEMON_USER_PASS}"
echo "Prepared masternode.conf string:"
echo "mn_${SIBMN_NAME_PREFIX} ${SIBMN_EXTERNAL_IP}:14014 ${MNGENKEY} INPUTTX INPUTINDEX"

exit 0
