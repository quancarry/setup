# !bin/bash
#[default]
# set Hostname
server_hostname=VWM

# Enable sshd 0|1
server_ssh=1

# Enable service apache  0|1
server_apache=1

# Enable service mysql 0|1
server_mysql=1

# Enable service php 0|1
server_php=1

# Enable python env 0|1
server_python=1

# Eet env VWM path; as command: export $VWM=/var/www/html/vwm
vwm_root=/var/www/html/vwm

#[firewall]
# Enable firewall iptables | firewalld
fw_enable=1

# List open ports
declare -a fw_allow_port=("80" "22" "443" "514")


#[web_config]
# Enable/disable the appserver
web_server=1

# This is the port used for both SSL and non-SSL (we only have 1 port now)_
web_port=80

# This determines whether to start web in http or https 0|1
web_ssl=0

# Enable HTTP AUTH 0|1
web_httpauth=1
USER='VWM-user' 
PASSWD='12345' 

# Enable htaccess 0|1
web_htaccess=1

# SSL certificate files_
privKeyPath=/var/www/html/key/privkey_pem
serverCert=/var/www/html/key/cert_pem

#[database]
# Enable database mysql
db_enable=1

# Enable root account
db_root=1

# Set password
db_root_pass=abc@123


#[log_config]
# folder save log file
log_saved=/var/log/http

# HTTP access log filename
log_access_file=web_access_log

# Maximum file size of the access log, in bytes
log_access_maxsize=25000000

# Maximum number of rotated log files to retain
log_access_maxfiles=5

# Maximum file size of the web_service_log file, in bytes
log_error_maxsize=25000000

# Maximum number of rotated log files to retain
log_error_maxfiles=5

PERMISSION=`whoami`
RELEASE=`cat /etc/redhat-release`
SUBSTR=`echo $RELEASE|cut -c1-22`

func_install_centos6(){

	#Change hostname
	echo '===== Set hostname ======'	
	sed -i 's/HOSTNAME=.*/HOSTNAME=$server_hostname/' /etc/sysconfig/network
	sed -i '1 i\127.0.0.1   $server_hostname $server_hostname' /etc/hosts
	hostname $server_hostname
		
	#Enable ssh
		if [[ "$server_ssh" == 1 ]];
			then
				echo '===== Enable SSH ======'
				#yum -y install openssh-server openssh-clients
				service sshd start
		fi
		
	#Enable Apache
		if [[ "$server_apache" == 1 ]];
			then
				echo '===== Enable Apache ======'
				#yum -y install httpd
				sed -i 's/#ServerName.*/ServerName localhost:$web_port/' /etc/httpd/conf/http.conf
				service httpd start
		fi
	#Enable mysql(mariadb)
		if [[ "$server_mysql" == 1 ]];
			then
				echo '===== Enable MySql ======'
				#echo [mariadb]\nname = MariaDB\nbaseurl = http://yum_mariadb_org/10_1/centos6-amd64\ngpgkey=https://yum_mariadb_org/RPM-GPG-KEY-MariaDB\ngpgcheck=1 > /etc/yum_repos_d/MariaDB_repo
				#yum install MariaDB-server MariaDB-client -y
				service mysqld start
		fi

	#install php

		yum -y install php php-mysql
		
	#config mysql
		if [[ "$db_root" == 1 ]];
			then
				echo '===== Config SQL ======'
				$ mysqladmin -u root password $db_root_pass
		fi
#VWM path : 

		#Create owner dictionary
		
			mkdir /var/www/html/vwm
		
		#Define root path
			sed  -i -e '$a\export $vwm_root=/var/www/html/vwm/' /bashrc


#Enable Authentication 
		if [[ "$web_httpauth" == 1 ]];
			then
				echo '===== Config Authentication ======'
				htpasswd -c -b /etc/httpd/.htpasswd $USER @PASSWD
				sed '/<Directory \/var\/www\html>/,/<\/Directory>/ s/AllowOverride None/AllowOverride AuthConfig/' /etc/httpd/conf/httpd.conf 
				echo AuthType Basic\nAuthName "Restricted Content"\nAuthUserFile /etc/httpd/.htpasswd\nRequire $USER > /var/www/html/vwm/.htaccess
				service httpd restart
		fi
	
	#config ssl
	#
	#
	#
	#
	#
	#

	#Enable _htaccess
		if [[ "web_htaccess" == 1 ]];
			then
				echo '==== Enable .htaccess ======'
				sed -n -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf

		fi
	#Enable iptables
		if [[ "fw_enable" == 1 ]];
			then
				echo '===== Enable ipatbles ======'
				service iptables start
		fi
	#Iptable allows ports:
		
		# get length of an array
		arraylength=${#fw_allow_port[@]}

		# use for loop to read all values and indexes
		echo '===== Enable Listen port ======'
		for (( i=1; i<${arraylength}+1; i++ ));
			do
			  iptables -A INPUT -p tcp -m tcp --dport ${fw_allow_port[$i]} -j ACCEPT
			done
		echo '===== Start iptables ======'
		service iptables start
	#Port webserver 
		sed -i 's/Listen[[:space:]].*/Listen $web_port/' /etc/httpd/conf/http.conf
		service httpd restart
	#Folder save log file

		$log_saved

	#Access log name
		echo '===== Logname ======'
		sed -i -e 's#CustomLog "logs/access_log" combined#CustomLog "logs/$log_access_file" combined#' /etc/httpd/conf/http.conf
		
	# Config Logrotate
		echo '===== Config Logrotate ======'
		sed  -i -e '$a\\n"/var/log/httpd/web_access_log" /var/log/httpd/error_log{ \n rotate $log_access_maxfiles \n size $log_access_maxsize}  /' /etc/logrotate.conf
	echo '===== Config Successfully ======'
	bash
	}


if [[ "$PERMISSION" == "root" ]];

then 
	if [[ "$SUBSTR" == "CentOS release 7" ]];
		then
			echo '===== Detected Centos OS 7_* ======'
			func_install_centos7
	else 
			echo '===== Detected Centos OS 6_* ======'
			func_install_centos6
	fi
else
	echo '===== Permission Denied ======'
	exit
fi
