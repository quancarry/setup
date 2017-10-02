[default]
# set Hostname
server.hostname =VWM

# Enable sshd 0|1
server.ssh=1

# Enable service apache  0|1
server.apache=1

# Enable service mysql 0|1
server.mysql=1

# Enable service php 0|1
server.php=1

# Enable python env 0|1
server.python=1

# Eet env VWM path; as command: export $VWM=/var/www/html/vwm
vwm.root=/var/www/html/vwm

[firewall]
# Enable firewall iptables | firewalld
fw.enable=1

# List open ports
declare -a fw.allow_port=("80" "22" "443" "514")


[web_config]
# Enable/disable the appserver
web.server = 1

# This is the port used for both SSL and non-SSL (we only have 1 port now).
web.port = 80

# This determines whether to start web in http or https 0|1
web.ssl = 0

# Enable HTTP AUTH 0|1
web.httpauth=1
USER='VWM-user' 
PASSWD='12345' 

# Enable htaccess 0|1
web.htaccess=1

# SSL certificate files.
privKeyPath = /var/www/html/key/privkey.pem
serverCert = /var/www/html/key/cert.pem

[database]
# Enable database mysql
db.enable=1

# Enable root account
db.root=1

# Set password
db.root_pass=abc@123


[log_config]
# folder save log file
log.saved = /var/log/http

# HTTP access log filename
log.access_file = web_access.log

# Maximum file size of the access log, in bytes
log.access_maxsize = 25000000

# Maximum number of rotated log files to retain
log.access_maxfiles = 5

# Maximum file size of the web_service.log file, in bytes
log.error_maxsize = 25000000

# Maximum number of rotated log files to retain
log.error_maxfiles = 5

PERMISSION = `whoami`
RELEASE=`cat /etc/redhat-release`
SUBSTR=`echo $RELEASE|cut -c1-22`

func_install_centos6(){

	#Change hostname
		
		
		
		
	#Enable ssh
		if [[ "$server.ssh" == 1]];
			then
			#yum -y install openssh-server openssh-clients
			service sshd start
		fi
		
	#Enable Apache
		if [[ "$server.apache" == 1]];
			then
				#yum -y install httpd
				service httpd start
		fi
	#Enable mysql(mariadb)
		if [[ "$server.mysql" == 1]];
			then
				#echo [mariadb]\nname = MariaDB\nbaseurl = http://yum.mariadb.org/10.1/centos6-amd64\ngpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck=1 > /etc/yum.repos.d/MariaDB.repo
				#yum install MariaDB-server MariaDB-client -y
				service mysqld start
		fi

	#install php

		yum -y install php php-mysql
		
	#config mysql
		if [[ "$db.root" == 1]];
			then
				echo -e "\ny\ny\n$db.root_pass\n$db.root_pass\ny\ny\ny\ny" | /usr/bin/mysql_secure_installation
		fi
#VWM path : 

		#Create owner dictionary
		
			mkdir /var/www/html/vwm
		
		#Define root path
		
			#$VM_path=/var/www/html/vwm

#Enable Authentication 
		if [[ "$web.httpauth" == 1]];
			then
				
				htpasswd -c -b /etc/httpd/.htpasswd $USER @PASSWD
				sed '/<Directory \/var\/www\html>/,/<\/Directory>/ s/AllowOverride None/AllowOverride AuthConfig/' /etc/httpd/conf/httpd.conf 
				echo AuthType Basic\nAuthName "Restricted Content"\nAuthUserFile /etc/httpd/.htpasswd\nRequire $USER > /var/www/html/vwm/.htaccess
				apachectl restart
		fi
	
	#config ssl
	#
	#
	#
	#
	#
	#

	#Enable .htaccess
		if [[ "web.htaccess" == 1]];
			then
				sed -n -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf

		fi
	#Enable iptables
		if [[ "fw.enable" == 1]];
			then
				service iptables start
		fi
	#Iptable allows ports:
		
		# get length of an array
		arraylength=${#fw.allow_port[@]}

		# use for loop to read all values and indexes
		for (( i=1; i<${arraylength}+1; i++ ));
		do
		  iptables -A INPUT -p tcp -m tcp --dport ${fw.allow_port[$i]} -j ACCEPT
		done
		
		service iptables start
		
	#Folder save log file

		$log.saved

	#Access log name

		sed -i -e 's#CustomLog "logs/access.log" combined#CustomLog "logs/$log.access_file" combined#' /etc/httpd/conf/http.conf
		
	# Config Logrotate

		sed  -i -e '$a\\n"/var/log/httpd/web_access.log" /var/log/httpd/error.log{ \n rotate $log.access_maxfiles \n size $log.access_maxsize}  /' /etc/logrotate.conf
	}


if [[ "$PERMISSION" == "root" ]];

then 
	if [[ "$SUBSTR" == "CentOS release 7" ]];
		then
			echo '===== Detected Centos OS 7.* ======'
			func_install_centos7
	else 
			echo '===== Detected Centos OS 6.* ======'
	fi
else
	echo '===== Permission Denied ======'
	exit
fi
