#!/bin/bash

echo ""
echo "############################################################"
echo "#  Fail2Ban for Sentora 1.0.0 or 1.0.3 By: Anthony D. #"
echo "############################################################"

echo -e "\nChecking that minimal requirements are ok"

# Ensure the OS is compatible with the launcher
if [ -f /etc/centos-release ]; then
    OS="CentOs"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 6 or 7
elif [ -f /etc/lsb-release ]; then
    OS=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
    VER=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
elif [ -f /etc/os-release ]; then
    OS=$(grep -w ID /etc/os-release | sed 's/^.*=//')
    VER=$(grep VERSION_ID /etc/os-release | sed 's/^.*"\(.*\)"/\1/')
else
    OS=$(uname -s)
    VER=$(uname -r)
fi
ARCH=$(uname -m)

echo "Detected : $OS  $VER  $ARCH"

if [[ "$OS" = "CentOs" && ("$VER" = "6" || "$VER" = "7" ) || 
      "$OS" = "Ubuntu" && ( "$VER" = "14.04" || "$VER" = "16.04" || "$VER" = "18.04" ) ]] ; then
    echo "- Ok."
else
    echo "Sorry, this OS is not supported by Sentora." 
    exit 1
fi


if [[ "$OS" = "CentOs" ]]; then

## Disable Firewalld 
systemctl stop firewalld
systemctl mask firewalld

## Install other services needed
yum -y install unzip
yum -y install wget

## Install iptables and enable services
yum -y install iptables-services
systemctl enable iptables

## Setup iptable default Sentora Ports
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 465 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 110 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 995 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 143 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 993 -j ACCEPT
service iptables save

## Install Fail2ban 
yum -y install fail2ban

## Make Fail2ban Module folder in Sentora modules
mkdir /etc/sentora/panel/modules/fail2ban
cd /etc/sentora/panel/modules/fail2ban

## Disabled for now
wget -nv -O sentora-fail2ban.zip http://zppy-repo.dukecitysolutions.com/repo/fail2ban/sentora-fail2ban.zip
unzip sentora-fail2ban.zip
cp -f /etc/sentora/panel/modules/fail2ban/filter.d/*.conf /etc/fail2ban/filter.d/
cp -f /etc/sentora/panel/modules/fail2ban/config/centos.jail.local /etc/fail2ban/jail.local
#mv /etc/fail2ban/centos.jail.local /etc/fail2ban/jail.local
chmod 777 /etc/fail2ban/jail.local

## Add fail2ban to cron - Not sure what this does yet
#cp -f /etc/sentora/panel/modules/fail2ban/sentora-fail2ban-centos /etc/cron.daily/

## Check fail2ban Config and start iptables
chkconfig --level 23 fail2ban on
systemctl start iptables
systemctl restart fail2ban

# Add missing logs for Roundcube to allow fail2ban to start on first installs.
touch /var/sentora/logs/roundcube/errors
chown -R apache:apache /var/sentora/logs/roundcube/errors
chmod 0664 /var/sentora/logs/roundcube/errors

elif [[ "$OS" = "Ubuntu" ]]; then

	# Update system
	#apt-get update && apt-get upgrade -y
		
	## Setup UFW default Sentora Ports
	sudo ufw allow 21
	sudo ufw allow 80
	sudo ufw allow 443
	sudo ufw allow 25
	sudo ufw allow 465
	sudo ufw allow 110
	sudo ufw allow 995
	sudo ufw allow 143
	sudo ufw allow 993
	
	#install fail2ban service
	apt-get -y install fail2ban
	
	## Make Fail2ban Module folder in Sentora modules
	mkdir /etc/sentora/panel/modules/fail2ban
	cd /etc/sentora/panel/modules/fail2ban
	
	## Install other services needed
	apt-get -y install unzip
	apt-get -y install wget
	
	## Disabled for now
	wget -nv -O sentora-fail2ban.zip http://zppy-repo.dukecitysolutions.com/repo/fail2ban/sentora-fail2ban.zip
	unzip sentora-fail2ban.zip
	cp -f /etc/sentora/panel/modules/fail2ban/filter.d/*.conf /etc/fail2ban/filter.d/
	cp -f /etc/sentora/panel/modules/fail2ban/config/ubuntu.jail.local /etc/fail2ban/jail.local
	#mv /etc/fail2ban/centos.jail.local /etc/fail2ban/jail.local
	chmod 777 /etc/fail2ban/jail.local
	
	ufw allow ssh
	ufw enable
	
	## Check fail2ban Config and start iptables
	#chkconfig --level 23 fail2ban on
	#systemctl start iptables
	systemctl restart fail2ban
	
	# Add missing logs for Roundcube to allow fail2ban to start on first installs.
	touch /var/sentora/logs/roundcube/errors
	chown -R www-data:www-data /var/sentora/logs/roundcube/errors
	chmod 0664 /var/sentora/logs/roundcube/errors

fi