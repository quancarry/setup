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
#version 5.6 or 7.0
server_php_version_minimum=70

# Enable python env 0|1

server_python=1
#version recommended is 2.6,2.7 or 3.6
server_python_version_minimum=36

#alias name to call python custom"
alias_name=py3

# Eet env VWM path; as command: export $VWM=/var/www/html/vwm
vwm_root=/var/www/html/vwm

#[firewall]
# Enable firewall iptables | firewalld
fw_enable=1

# List open ports
declare -a fw_allow_port=("80" "22" "443" "514")

#[web_config]

# This is the port used for both SSL and non-SSL (we only have 1 port now)_
web_port=80

# This determines whether to start web in http or https 0|1
web_ssl=1

# Enable HTTP AUTH 0|1
web_httpauth=1
USER='VWM-user' 
PASSWD='12345' 

# Enable htaccess 0|1
web_htaccess=1

# SSL certificate files_
privKeyPath=/var/www/html/key/privkey.pem
serverCert=/var/www/html/key/cert.pem

#[database]
# Enable database mysql
db_enable=1

# Enable root account
db_root=1

# Set password
db_root_pass=abc@123


#[log_config]


# HTTP access log filename
log_access_file=web_access.log

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
SUBSTR=`echo $RELEASE|cut -c1-16`
py_mini_1=`echo $server_python_version_minimum | cut -c 1`
py_mini_2=`echo $server_python_version_minimum | cut -c 2`

installing(){
	#disable refresh-packagekit
	sed -i 's/enabled=.*/enabled=0/' /etc/yum/pluginconf.d/refresh-packagekit.conf
			echo '===== Config Hostname ======'
			RELEASE_RPM=$(rpm -qf /etc/redhat-release)
							 RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
							 change_hostname(){
								case ${RELEASE} in
									6*) sed -i "s/HOSTNAME=.*/HOSTNAME=$server_hostname"/ /etc/sysconfig/network
	sed -n "s/HOSTNAME=.*/HOSTNAME=$server_hostname"/p /etc/sysconfig/network
	printf "127.0.0.1	$server_hostname $server_hostname\n127.0.0.1	localhost localhost.localdomain localhost4 localhost4.localdomain4\n::1		localhost localhost.localdomain localhost6 localhost6.localdomain6\n" > /etc/hosts
	cat /etc/hosts | grep "$server_hostname"
	hostname $server_hostname;;
									7*) hostnamectl set-hostname $server_hostname.com;;
								esac
									}
	change_hostname
	
	#install php

		#yum -y install php php-mysql
		# Script to setup the IUS public repository on your EL server.
		# Tested on CentOS/RHEL 6/7.

		supported_version_check(){
			case ${RELEASE} in
				6*) echo "EL 6 is supported" ;;
				7*) echo "EL 7 is supported" ;;
				*)
					echo "Unsupported OS version"
					exit 1
					;;
			esac
		}

		centos_install_epel(){
			# CentOS has epel release in the extras repo
			yum -y install epel-release
			import_epel_key
		}

		rhel_install_epel(){
			case ${RELEASE} in
				6*) yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;;
				7*) yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;;
			esac
			import_epel_key
		}

		import_epel_key(){
			case ${RELEASE} in
				6*) rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6;;
				7*) rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7;;
			esac
		}

		centos_install_ius(){
			case ${RELEASE} in
				6*) yum -y install https://centos6.iuscommunity.org/ius-release.rpm;;
				7*) yum -y install https://centos7.iuscommunity.org/ius-release.rpm;;
			esac
			import_ius_key
		}

		rhel_install_ius(){
			case ${RELEASE} in
				6*) yum -y install https://rhel6.iuscommunity.org/ius-release.rpm;;
				7*) yum -y install https://rhel7.iuscommunity.org/ius-release.rpm;;
			esac
			import_ius_key
		}

		import_ius_key(){
			rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
		}
	if [[ "$server_php" == 1 ]];
		then
		PHP_VER=`php -v | grep "PHP [0-9]"|cut -c 5,7`
		if [[ "$PHP_VER" < "$server_php_version_minimum" ]];
		then
			echo '===== Installing epel lastest & ius ======'
			if [[ -e /etc/redhat-release ]]; then
				RELEASE_RPM=$(rpm -qf /etc/redhat-release)
				RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
				case ${RELEASE_RPM} in
					centos*)
						echo "detected CentOS ${RELEASE}"
						supported_version_check
						centos_install_epel
						centos_install_ius
						;;
					redhat*)
						echo "detected RHEL ${RELEASE}"
						supported_version_check
						rhel_install_epel
						rhel_install_ius
						;;
					*)
						echo "unknown EL clone"
						exit 1
						;;
				esac

			else
				echo "not an EL distro"
				exit 1
			fi
		echo '===== Remove old php ======'
		yum -y remove php-cli mod_php php-common
		echo "===== Installing php version $server_php_version_minimum ======"
		yum -y install php${server_php_version_minimum}u-mysqlnd mod_php${server_php_version_minimum}u php${server_php_version_minimum}u-cli
		else
		echo '===== Php version is suitable . Skip ======'
		fi
	fi
	if [[ "$server_python" == 1 ]];
		then
			echo '===== Config python env ======'
			RELEASE_RPM=$(rpm -qf /etc/redhat-release)
							 RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
							 centos_install_ius(){
								case ${RELEASE} in
									6*) yum -y install https://centos6.iuscommunity.org/ius-release.rpm;;
									7*) yum -y install https://centos7.iuscommunity.org/ius-release.rpm;;
								esac
									}
			
			
			if hash python;
				then
					PY_VER=`python -c "import sys;ver=sys.version_info[:3];print('{0}{1}'.format(*ver));"`
					echo "===== Detected Python ver  $PY_VER ======"
						if [[ "$PY_VER" < "$server_python_version_minimum" ]];
						then
							 echo "===== Installing python ver $server_python_version_minimum ======"
							 
							  centos_install_ius
							  yum -y install python${server_python_version_minimum}u
							  yum -y install python${server_python_version_minimum}u-devel
							  sed -i "\$a alias ${alias_name}='/usr/bin/python${py_mini_1}.${py_mini_2}'" ~/.bashrc
							 
						else 
						echo '===== Python version is suitable . Skip ======'
						fi
			else 
			echo '===== Python not installed . ======'
			echo "===== Installing python ver $server_python_version_minimum ======"
				centos_install_ius
				yum -y install python${server_python_version_minimum}u
				yum -y install python${server_python_version_minimum}u-devel
				sed -i "$a\ alias ${alias_name}=${alias_value}" ~/.bashrc
			fi
			#export PATH : = $server_python_path
	fi
	#Enable ssh
		if [[ "$server_ssh" == 1 ]];
			then
				echo '===== Enable SSH ======'
				#yum -y install openssh-server openssh-clients
				service sshd start
				service sshd status
		fi
		
	#Enable Apache
		#Port webserver 
		sed -i "s/Listen[[:space:]].*/Listen $web_port/" /etc/httpd/conf/httpd.conf
		if [[ "$server_apache" == 1 ]];
			then
				echo '===== Enable Apache ======'
				#yum -y install httpd
				sed -i "s/#ServerName.*/ServerName localhost:$web_port/" /etc/httpd/conf/httpd.conf
				sed -n "s/ServerName localhost:$web_port//p" /etc/httpd/conf/httpd.conf
		fi
	#Enable mysql(mariadb)
		if [[ "$server_mysql" == 1 ]];
			then
				echo '===== Enable MySql ======'
				#echo [mariadb]\nname = MariaDB\nbaseurl = http://yum_mariadb_org/10_1/centos6-amd64\ngpgkey=https://yum_mariadb_org/RPM-GPG-KEY-MariaDB\ngpgcheck=1 > /etc/yum_repos_d/MariaDB_repo
				#yum install MariaDB-server MariaDB-client -y
				service mysqld start
		fi

	#config mysql
		if [[ "$db_root" == 1 ]];
			then
				echo '===== Config SQL ======'
				mysqladmin -u root password $db_root_pass
		fi
	#VWM path : 

		#Create owner dictionary
		if [ ! -d "/var/www/html/vwm" ]; then
			mkdir /var/www/html/vwm
		else
			echo 'Directory really exists . Skip'
		
		fi
	#Define root path
			sed  -i  "\$a export vwm_root=$vwm_root" ~/.bashrc
			
#Enable Authentication 
		if [[ "$web_httpauth" == 1 ]];
			then
				echo '===== Config Authentication ======'
				if [[ ! -e /etc/httpd/.htpasswd ]];
				then
					htpasswd -c -b /etc/httpd/.htpasswd $USER $PASSWD
					sed -i '/<Directory \"\/var\/www\/html\">/,/<\/Directory>/ s/AllowOverride None/AllowOverride AuthConfig/' /etc/httpd/conf/httpd.conf 
					sed -n '/<Directory \"\/var\/www\/html\">/,/<\/Directory>/ s/AllowOverride AuthConfig//p' /etc/httpd/conf/httpd.conf 
					printf "AuthType Basic
	AuthName \"Restricted Content\"
	AuthUserFile /etc/httpd/.htpasswd
	Require valid-user
	" > /var/www/html/vwm/.htaccess
				else 
				htpasswd -b /etc/httpd/.htpasswd $USER $PASSWD
					sed -i '/<Directory \"\/var\/www\/html\">/,/<\/Directory>/ s/AllowOverride None/AllowOverride AuthConfig/' /etc/httpd/conf/httpd.conf 
					sed -n '/<Directory \"\/var\/www\/html\">/,/<\/Directory>/ s/AllowOverride AuthConfig//p' /etc/httpd/conf/httpd.conf 
					printf "AuthType Basic
	AuthName \"Restricted Content\"
	AuthUserFile /etc/httpd/.htpasswd
	Require valid-user
	" > /var/www/html/vwm/.htaccess
				fi
		fi
	
	#config ssl
	#
	if [ ! -d "/var/www/html/key" ]; then
			mkdir	/var/www/html/key
		else
			echo 'Directory really exists . Skip'
	fi	
		if [[ "$web_ssl" == 0 ]];
			then
				echo '==== Enable non-SSL ======'
				#Shutdown listen 443
			else
				if [ -e '/etc/httpd/conf.d/ssl.conf' ]
					then
					echo '==== Enable SSL Self-Certificate ======'
					#Shutdown listen 80
					echo "\n\n\n\n\n" | openssl req -nodes -x509 -newkey rsa:4096 -keyout $privKeyPath -out $serverCert -days 365 -subj '/CN=localhost'
					sed -i "s/SSLCertificateFile[[:space:]]\/.*/SSLCertificateFile ${serverCert//\//\\/}/" /etc/httpd/conf.d/ssl.conf
					sed -i "s/SSLCertificateKeyFile[[:space:]]\/.*/SSLCertificateKeyFile ${privKeyPath//\//\\/}/" /etc/httpd/conf.d/ssl.conf
					
				else
					echo '==== Install ssl_mod ======'
					yum -y install mod_ssl
					echo '==== Enable SSL Self-Certificate ======'
					#Shutdown listen 80
					echo "\n\n\n\n\n" | openssl req -nodes -x509 -newkey rsa:4096 -keyout $privKeyPath -out $serverCert -days 365 -subj '/CN=localhost'
					sed -i "s/SSLCertificateFile[[:space:]]\/.*/SSLCertificateFile ${serverCert//\//\\/}/" /etc/httpd/conf.d/ssl.conf
					sed -i "s/SSLCertificateKeyFile[[:space:]]\/.*/SSLCertificateKeyFile ${privKeyPath//\//\\/}/" /etc/httpd/conf.d/ssl.conf
					
				fi
		fi
	#Enable _htaccess
		if [[ "$web_htaccess" == 1 ]];
			then
				echo '==== Enable .htaccess ======'
				sed -i '/<Directory \/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf
				
		fi
	#Enable iptables
		if [[ "$fw_enable" == 1 ]];
			then
				echo '===== Enable ipatbles ======'
				service iptables start
		fi
	#Iptable allows ports:
		
		# get length of an array
		arraylength=${#fw_allow_port[@]}

		# use for loop to read all values and indexes
		echo '===== Enable Listen port ======'
		for (( i=0; i<${arraylength}; i++ ));
			do
			  iptables -A INPUT -p tcp -m tcp --dport ${fw_allow_port[$i]} -j ACCEPT
			  echo "Enable port ${fw_allow_port[$i]}"
			done
		echo '===== Start iptables ======'
		service iptables save
		service iptables restart

	#Folder save log file

		#$log_saved

	#Access log name
		echo '===== Logname ======'
		sed -i "s/CustomLog logs\/access_log combined/CustomLog logs\/$log_access_file combined/" /etc/httpd/conf/httpd.conf
		
	# Config Logrotate
		echo '===== Config Logrotate ======'
		sed  -i "\$a/var/log/httpd/*.log{\n rotate $log_access_maxfiles\n size $log_access_maxsize\n}/" /etc/logrotate.conf
		cat /etc/logrotate.conf
		
	#restart service
	service httpd restart

	echo '===== Config Successfully ======'
	bash
	}
	
if [[ "$PERMISSION" == "root" ]];

then 
	if [[ "$SUBSTR" == "CentOS release 7" ]];
		then
			echo '===== Detected Centos OS 7_* ======'
			installing
	fi
	if [[ "$SUBSTR" == "CentOS release 6" ]];
		then
			echo '===== Detected Centos OS 6_* ======'
			installing
	fi
else
	echo '===== Root permission required. ======'
	exit
fi
