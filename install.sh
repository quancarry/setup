# !bin/bash

#Update 

	yum -y update && yum -y upgrade 


func_install_centos7(){

	#Change hostname
		
		hostnamectl set-hostname VWM
		
		
	#Install ssh

		yum -y install openssh-server openssh-clients
		
		systemctl restart sshd.service
		
	#install Apache

		yum -y install httpd
		
	#install mysql(mariadb)

		yum -y install mariadb-server mariadb

	#Enable webserver
		
		systemctl start mariadb
		systemctl enable mariadb.service
		
		systemctl enable httpd.service
		systemctl start httpd.service
		
	#install php

		yum -y install php php-mysql
		
	#config mysql

		dbpass='abc@123'
		echo -e "\ny\ny\n$dbpass\n$dbpass\ny\ny\ny\ny" | /usr/bin/mysql_secure_installation

	#Enable Authentication 
		
		USER='VWM-user' 
		PASSWD='12345' 
		htpasswd -c -b /etc/httpd/.htpasswd $USER @PASSWD
		sed '/<Directory \/var\/www\html>/,/<\/Directory>/ s/AllowOverride None/AllowOverride AuthConfig/' /etc/httpd/conf/httpd.conf 
		echo AuthType Basic\nAuthName "Restricted Content"\nAuthUserFile /etc/httpd/.htpasswd\nRequire $USER > /var/www/html/vwm/.htaccess
		apachectl restart
		
	#VWM path : 

		#Create owner dictionary
		
			mkdir /var/www/html/vwm
		
		#Define root path
		
			#$VM_path=/var/www/html/vwm

	#config ssl
	#
	#
	#
	#
	#
	#

	#Enable .htaccess

		sed -n -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf


	#Enable iptables

		service iptables start

	#Iptable allows ports:
		
		iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
		iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
		iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
		iptables -A INPUT -p tcp -m tcp --dport 514 -j ACCEPT
		service iptables start
		
	#Folder save log file

		#mkdir /var/log/httpd

	#Access log name

		sed -i -e 's#CustomLog "logs/access.log" combined#CustomLog "logs/web_access.log" combined#' /etc/httpd/conf/http.conf
		
	# Config Logrotate

		sed  -i -e '$a\\n"/var/log/httpd/web_access.log" /var/log/httpd/error.log{ \n rotate 5 \n size 20M}  /' /etc/logrotate.conf
	}
func_install_centos6(){

	#Change hostname
		
		
		
		
	#Install ssh

		yum -y install openssh-server openssh-clients
		
		service sshd start
		
	#install Apache

		yum -y install httpd
		
	#install mysql(mariadb)

		yum -y install mariadb-server mariadb

	#Enable webserver
		
		service httpd start
		service mysqld start
		
	#install php

		yum -y install php php-mysql
		
	#config mysql

		dbpass='abc@123'
		echo -e "\ny\ny\n$dbpass\n$dbpass\ny\ny\ny\ny" | /usr/bin/mysql_secure_installation

	#Enable Authentication 
		
		USER='VWM-user' 
		PASSWD='12345' 
		htpasswd -c -b /etc/httpd/.htpasswd $USER @PASSWD
		sed '/<Directory \/var\/www\html>/,/<\/Directory>/ s/AllowOverride None/AllowOverride AuthConfig/' /etc/httpd/conf/httpd.conf 
		echo AuthType Basic\nAuthName "Restricted Content"\nAuthUserFile /etc/httpd/.htpasswd\nRequire $USER > /var/www/html/vwm/.htaccess
		apachectl restart
		
	#VWM path : 

		#Create owner dictionary
		
			mkdir /var/www/html/vwm
		
		#Define root path
		
			#$VM_path=/var/www/html/vwm

	#config ssl
	#
	#
	#
	#
	#
	#

	#Enable .htaccess

		sed -n -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf


	#Enable iptables

		service iptables start

	#Iptable allows ports:
		
		iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
		iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
		iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
		iptables -A INPUT -p tcp -m tcp --dport 514 -j ACCEPT
		service iptables start
		
	#Folder save log file

		#mkdir /var/log/httpd

	#Access log name

		sed -i -e 's#CustomLog "logs/access.log" combined#CustomLog "logs/web_access.log" combined#' /etc/httpd/conf/http.conf
		
	# Config Logrotate

		sed  -i -e '$a\\n"/var/log/httpd/web_access.log" /var/log/httpd/error.log{ \n rotate 5 \n size 20M}  /' /etc/logrotate.conf
	}
RELEASE=`cat /etc/redhat-release`

SUBSTR=`echo $RELEASE|cut -c1-22`

if ["$SUBSTR" == "CentOS Linux release 7"];

then 
	func_install_centos7
	echo 'Detected Centos OS 7'

else 
	func_install_centos6
fi
	
