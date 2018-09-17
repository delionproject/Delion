#/bin/bash

cd ~
echo "****************************************************************************"
echo "* Ubuntu 16.04 is the recommended opearting system for this install.       *"
echo "*                                                                          *"
echo "* This script will install and configure your Delion  masternodes.  *"
echo "****************************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                 !"
echo "! Make sure you double check before hitting enter !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo

echo "Do you want to install all needed dependencies (no if you did it before)? [y/n]"
read DOSETUP

if [ $DOSETUP = "y" ]  
then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get update
  sudo apt-get install -y zip unzip

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd

  wget https://github.com/phoenixkonsole/delion/releases/download/v1.1.0.0/Linux.zip
  unzip Linux.zip
  chmod +x Linux/bin/*
  sudo mv  Linux/bin/* /usr/local/bin
  rm -rf Linux.zip Windows Linux Mac

  sudo apt-get install -y ufw
  sudo ufw allow ssh/tcp
  sudo ufw limit ssh/tcp
  sudo ufw logging on
  echo "y" | sudo ufw enable
  sudo ufw status

  mkdir -p ~/bin
  echo 'export PATH=~/bin:$PATH' > ~/.bash_aliases
  source ~/.bashrc
fi

 ## Setup conf
 IP=$(curl -s4 api.ipify.org)
 mkdir -p ~/bin
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"

echo ""
echo "How many nodes do you want to create on this server? [min:1 Max:20]  followed by [ENTER]:"
read MNCOUNT


for i in `seq 1 1 $MNCOUNT`; do
  echo ""
  echo "Enter alias for new node"
  read ALIAS  

  echo ""
  echo "Enter port for node $ALIAS"
  read PORT

  echo ""
  echo "Enter masternode private key for node $ALIAS"
  read PRIVKEY

  RPCPORT=$(($PORT*10))
  echo "The RPC port is $RPCPORT"

  ALIAS=${ALIAS}
  CONF_DIR=~/.delion_$ALIAS

  # Create scripts
  echo '#!/bin/bash' > ~/bin/deliond_$ALIAS.sh
  echo "deliond -daemon -conf=$CONF_DIR/delion.conf -datadir=$CONF_DIR "'$*' >> ~/bin/deliond_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/delion-cli_$ALIAS.sh
  echo "delion-cli -conf=$CONF_DIR/delion.conf -datadir=$CONF_DIR "'$*' >> ~/bin/delion-cli_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/delion-tx_$ALIAS.sh
  echo "delion-tx -conf=$CONF_DIR/delion.conf -datadir=$CONF_DIR "'$*' >> ~/bin/delion-tx_$ALIAS.sh 
  chmod 755 ~/bin/delion*.sh

  mkdir -p $CONF_DIR
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> delion.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> delion.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> delion.conf_TEMP
  echo "rpcport=$RPCPORT" >> delion.conf_TEMP
  echo "listen=1" >> delion.conf_TEMP
  echo "server=1" >> delion.conf_TEMP
  echo "daemon=1" >> delion.conf_TEMP
  echo "logtimestamps=1" >> delion.conf_TEMP
  echo "maxconnections=256" >> delion.conf_TEMP
  echo "masternode=1" >> delion.conf_TEMP
  echo "" >> delion.conf_TEMP

  echo "" >> delion.conf_TEMP
  echo "port=$PORT" >> delion.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> delion.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> delion.conf_TEMP
  sudo ufw allow $PORT/tcp

  mv delion.conf_TEMP $CONF_DIR/delion.conf
  
  sh ~/bin/deliond_$ALIAS.sh
done
