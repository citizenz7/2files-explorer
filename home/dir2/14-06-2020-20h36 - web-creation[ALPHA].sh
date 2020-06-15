#!/bin/bash
#
## ###############################################
## QuickWebCreation (QWC)
## Install apps if needed
## Create automatically a Nginx vhost, mysql user + database,
## ftp and e-mail accounts
##
## Olivier Prieur (citizenz7) - 01/01/20
## Blog: https://www.citizenz.info
## Contact: contact@citizenz.info
##
## Prerequisites :
## 1/ You NEED to run: 'dpkg-reconfigure dash' and answer NO, unless you'll fail running this script
## 2/ If apps are not installed yet, script will propose to install them
## 
## Account created as LOGIN in /var/www/LOGIN'
## ################################################

#Script Console Colors
black=$(tput setaf 0); red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3);
blue=$(tput setaf 4); magenta=$(tput setaf 5); cyan=$(tput setaf 6); white=$(tput setaf 7);
on_red=$(tput setab 1); on_green=$(tput setab 2); on_yellow=$(tput setab 3); on_blue=$(tput setab 4);
on_magenta=$(tput setab 5); on_cyan=$(tput setab 6); on_white=$(tput setab 7); bold=$(tput bold);
dim=$(tput dim); underline=$(tput smul); reset_underline=$(tput rmul); standout=$(tput smso);
reset_standout=$(tput rmso); normal=$(tput sgr0); alert=${white}${on_red}; title=${standout};
sub_title=${bold}${yellow}; repo_title=${black}${on_green}; message_title=${white}${on_magenta}

#check if Ubuntu or Debian
DISTRO=$(lsb_release -is)
RELEASE=$(lsb_release -rs)
CODENAME=$(lsb_release -cs)
SETNAME=$(lsb_release -rc)

#welcome...
echo
echo "${repo_title}                                                             ${normal} "
echo "${repo_title} ${bold}${white}QuickWebCreation (QWC)                                    ${normal} "
echo "${repo_title}                                                             ${normal} "
echo "${title} URL: https://github.com/citizenz7/QWC                       ${normal} "
echo "${title}                                                             ${normal} "
echo "${title} Welcome!                                                    ${normal} "
echo "${title} QuickWebCreation works with Ubuntu 16.04+ and Debian 8+ OS. ${normal} "
echo "${title} The script will perform some checks then configure system.  ${normal} "
echo "${title}                                                             ${normal} "
echo "${message_title}                                                             ${normal} "
echo "${message_title} ${bold}${white}Please answer a few short questions. Let's go!              ${normal} "
echo "${message_title}                                                             ${normal} "
echo

#checks distro
echo "${green}Checking distribution ...${normal}"
if [ ! -x  /usr/bin/lsb_release ]; then
  echo "It looks like you are running $DISTRO, which is not supported by QuickWebCreation."
  echo "Exiting..."
  exit 1
fi

echo "$(lsb_release -a)"

if [[ ! $DISTRO =~ ^(Ubuntu|Debian)$ ]]; then
  echo "$DISTRO: ${alert} It looks like you are running $DISTRO, which is not supported by QuickAppsServer :/ ${normal} "
  echo "Exiting..."
  exit 1
fi
echo
if [[ ! $CODENAME =~ ^(xenial|eoan|disco|bionic|cosmic|artful|zesty|yakkety|buster|stretch|jessie)$ ]]; then
  echo "$CODENAME: ${alert} It looks like you are running $DISTRO $RELEASE '$CODENAME', which is not supported by QuickAppsServer :/ ${normal} "
  echo "Exiting..."
  exit 1
fi

#check if root
if [ "$EUID" -ne 0 ]; then 
  echo "${alert}${bold} ERROR!                                                      ${normal} "
  echo "${alert}${bold} --> Please run this script as root!                         ${normal} "
  echo "${alert}${bold} --> Exiting!                                                ${normal} "
  echo
  exit 1
fi

#go on...
echo "The script will now perform somes checks and install apps if needed..."
echo "Then, just answer the questions."
echo 
echo

#make a small pause 
read -n 1 -s -r -p "Press any key to continue"

#update & upgrade system
apt-get update
apt-get upgrade -y
apt-get autoremove

#domaine name & password
echo -n "Add full qualified domaine name (fqdn) - ex: subdomain.example.com: ";
read login;

echo

read -p "Enter password (Used for MySQL and FTP accounts): " password
read -p "Enter password (again): " password2

#check if passwords match and if not ask again
while [ "$password" != "$password2" ];
do
        echo 
        echo "Password mismatch. Please try again"
        read -p "Enter password: " password
        echo
        read -p "Enter password (again): " password2
done
password=$password

#checking
echo
echo "Account: $login"
echo "Password: $password"
echo -n "Is it ok? ? y/[n]"
read ans

if [ _$ans != _y -a _$ans != _Y ]
then
     echo "OK, let's stop here!"
exit 1
fi

#Verify if apps are installed. If not, install and configure

#Nginx
apt-get -s -y install nginx
if [ $? -eq 0 ] ; then echo "Nginx is installed on your system. Let's continue.";
else
	echo -n "Nginx is not installed on your system. Do you want to install it? (y|n)";
	read apps
	if [[ $apps =~ ^(y|Y|yes|YES)$ ]]; then
		apt-get install -y nginx openssl
		service restart nginx
		ufw allow 80/tcp #ufw HTTP setting
		ufw allow 443/tcp #ufw HTTPS setting
	fi
fi

#E-mail: postfix
apt-get -s -y install postfix
if [ $? -eq 0 ] ; then echo "Postfix is installed on your system. Let's continue.";
else
	echo -n "Postfix is not installed on your system. Do you want to install it? (y|n)";
	read apps
	if [[ $apps =~ ^(y|Y|yes|YES)$ ]]; then
		apt-get install -y libdb5.1 postfix procmail sasl2-bin openssl
		adduser postfix sasl
		postconf -e 'smtpd_sasl_local_domain ='
		postconf -e 'smtpd_sasl_auth_enable = yes'
		postconf -e 'smtpd_sasl_security_options = noanonymous'
		postconf -e 'broken_sasl_auth_clients = yes'
		postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
		postconf -e 'inet_interfaces = all'
		touch /etc/postfix/sasl/smtpd.conf
		echo 'pwcheck_method: saslauthd' >> /etc/postfix/sasl/smtpd.conf
		echo 'mech_list: plain login' >> /etc/postfix/sasl/smtpd.conf
		mkdir /etc/postfix/ssl
		cd /etc/postfix/ssl/
		openssl genrsa -des3 -rand /dev/urandom -out smtpd.key 2048
		openssl req -new -key smtpd.key -out smtpd.csr
		openssl x509 -req -days 3650 -in smtpd.csr -signkey smtpd.key -out smtpd.crt
		openssl rsa -in smtpd.key -out smtpd.key.unencrypted
		mv -f smtpd.key.unencrypted smtpd.key
		chmod 600 smtpd.key
		openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650 
		postconf -e 'smtpd_tls_auth_only = no'
		postconf -e 'smtp_use_tls = yes'
		sudo postconf -e 'smtpd_use_tls = yes'
		postconf -e 'smtp_tls_note_starttls_offer = yes'
		postconf -e 'smtpd_tls_key_file = /etc/postfix/ssl/smtpd.key'
		postconf -e 'smtpd_tls_cert_file = /etc/postfix/ssl/smtpd.crt'
		postconf -e 'smtpd_tls_CAfile = /etc/postfix/ssl/cacert.pem'
		postconf -e 'smtpd_tls_loglevel = 1'
		postconf -e 'smtpd_tls_received_header = yes'
		postconf -e 'smtpd_tls_session_cache_timeout = 3600s'
		postconf -e 'tls_random_source = dev:/dev/urandom'
		postconf -e 'myhostname = $login' 
		postconf -e 'mydestination = $login, localhost.localdomain, localhost'
		service postfix restart
		
		#saslauthd
		apt-get install libsasl2-modules libsasl2-modules-sql libgsasl7 libauthen-sasl-cyrus-perl sasl2-bin libpam-mysql
		mkdir -p /var/spool/postfix/var/run/saslauthd
		rm -fr /var/run/saslauthd
		ln -s /var/spool/postfix/var/run/saslauthd /var/run/saslauthd
		chown -R root:sasl /var/spool/postfix/var/
		chmod 710 /var/spool/postfix/var/run/saslauthd
		adduser postfix sasl
		
		sed -i 's/#START=yes/START=yes/g' /etc/default/saslauthd
		sed -i 's/OPTIONS="-c -m /var/run/saslauthd"/OPTIONS="-m /var/spool/postfix/var/run/saslauthd"/g' /etc/default/saslauthd
		service saslauthd start
		
		ufw allow 25/tcp #ufw SMTP
		ufw allow 587/tcp #ufw Submission
	fi
fi

#Mysql
apt-get -s -y install mariadb-server
if [ $? -eq 0 ] ; then echo "mariadb-server is installed on your system. Let's continue.";
else
	echo -n "mariadb-server is not installed on your system. Do you want to install it? (y|n)";
	read apps
	if [[ $apps =~ ^(y|Y|yes|YES)$ ]]; then
		apt-get install -y mariadb-server
		#secure MySQL
		echo "Let's secure MySQL with a root password:"
		read -p "Enter root MySQL password: " sqlpassword
		read -p "Enter root MySQL password (again): " sqlpassword2
		# check if root MySQL passwords match and if not ask again
		while [ "$sqlpassword" != "$sqlpassword2" ];
		do
			echo 
			echo "Password mismatch. Please try again"
			read -p "Enter root MySQL password: " sqlpassword
			echo
			read -p "Enter root MySQL password (again): " sqlpassword2
		done
		#OK, let's secure MySQL with mysql_secure_installation script
		echo -e '\nY\n$sqlpassword\n$sqlpassword\nY\nY\nY\nY' | sudo mysql_secure_installation
	fi
fi

#php-fpm
apt-get -s -y install php-fpm
if [ $? -eq 0 ] ; then echo 'php-fpm is installed on your system.';
        else
                echo -n 'php-fpm is not installed on your system. Do you want to install it? (y|n)';
                read apps
                if [[ $apps =~ ^(y|Y|yes|YES)$ ]]; then
                apt-get install -y php-fpm
                fi
fi

#php-mysql
apt-get -s -y install php-mysql
if [ $? -eq 0 ] ; then echo 'php-mysql is installed on your system.';
        else
                echo -n 'php-mysql is not installed on your system. Do you want to install it? (y|n)';
                read apps
                if [[ $apps =~ ^(y|Y|yes|YES)$ ]]; then
                apt-get install -y php-mysql
                fi
fi

#pure-ftpd
apt-get -s -y install pure-ftpd-common
if [ $? -eq 0 ] ; then echo 'pure-ftpd is installed on your system.'; 
else
	echo -n 'pure-ftpd is not installed on your system. Do you want to install it? (y|n)';
	read apps
	if [[ $apps =~ ^(y|Y|yes|YES)$ ]]; then
		apt-get install -y pure-ftpd-common
		#set virtualchroot to true
		sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/g' /etc/default/pure-ftpd-common
		groupadd ftpgroup
		useradd -g ftpgroup -d /dev/null -s /bin/false ftpuser
		ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/50pure
		ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/75puredb 
		adduser ftpuser www-data
		echo "29799 29899" > /etc/pure-ftpd/conf/PassivePortRange #activate passive ports
		echo "15" > /etc/pure-ftpd/conf/MaxClientsNumber #limit to 15 connections

		#configure pure-ftpd to allow TLS sessions..
		echo 1 > /etc/pure-ftpd/conf/TLS
		mkdir -p /etc/ssl/private/
		echo "Now, let's create a SSL certificate for pure-ftpd to allow TLS sessions..."
		echo "Just answer next questions:"
		echo
		openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
		chmod 600 /etc/ssl/private/pure-ftpd.pem
		service pure-ftpd restart
		#add ports to firewall
		ufw allow 20:21/tcp #ufw calssic ports setting
		ufw allow 29799:29899/tcp #ufw passive ports setting
	fi
fi

#create directories /web and /logs
/bin/mkdir -p /var/www/$login/web /var/www/$login/logs
echo " + web & logs directories created!"

#create default "welcome" index.php file
echo "
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>Welcome!</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <link rel="shortcut icon" href="/favicon.ico" />
    <meta name="robots" content="noindex" />
	<style type="text/css"><!--
    body {
        color: #444444;
        background-color: #EEEEEE;
        font-family: 'Trebuchet MS', sans-serif;
        font-size: 80%;
    }
    h1 {}
    h2 { font-size: 1.2em; }
    #page{
        background-color: #FFFFFF;
        width: 60%;
        margin: 24px auto;
        padding: 12px;
    }
    #header{
        padding: 6px ;
        text-align: center;
    }
    .header{ background-color: #83A342; color: #FFFFFF; }
    #content {
        padding: 4px 0 24px 0;
    }
    #footer {
        color: #666666;
        background: #f9f9f9;
        padding: 10px 20px;
        border-top: 5px #efefef solid;
        font-size: 0.8em;
        text-align: center;
    }
    #footer a {
        color: #999999;
    }
    --></style>
</head>
<body>
    <div id="page">
        <div id="header" class="header">
            <h1>Welcome to $login</h1>
        </div>
        <div id="content">
            <h2>This is the default index page of your website.</h2>
            <p>This file may be deleted or overwritten without any difficulty.</p>
            <p>For questions or problems please contact support@s3ii.fr.nf.</p>
        </div>
        <div id="footer">
            <p>Powered by <a href="http://www.s3ii.fr.nf">s3ii.fr.nf</a></p>
        </div>
    </div>
</body>
</html>

" >> /var/www/$login/web/index.php

echo "Default index.php file created!"

#change owner www-data:ftpgroup and mod 755
chown -R www-data:ftpgroup /var/www/$login/
chmod  755 /var/www/$login/
chmod -R g+rw /var/www/
echo "Permissions changed in your web directory!"

#create a new Nginx vhost
echo "
server {
        listen 80;
		listen [::]:80;
        server_name $login;
        root /var/www/$login/web;
        index index.php index.html;
        access_log /var/www/$login/logs/access.log combined;
        error_log /var/www/$login/logs/error.log error;

		location / {
                try_files $uri $uri/ =404;
        }

		location ~ \.php$ {
			include snippets/fastcgi-php.conf;
			fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        }
}
" >> /etc/nginx/conf.d/$login.conf
echo " + Nginx VirtualHost created!"

# mysql
echo -n "Do you need a MySQL database? y/[n]"
read ans

if [ _$ans = _y -o _$ans = _Y ]
then
	echo -n "Add a root mysql password:";
	read passroot; 

	/usr/bin/mysqladmin -u root -p$passroot create $login
	echo "MySQL database $login created!"

	/usr/bin/mysql -u root --password=$passroot mysql
	GRANT ALL PRIVILEGES ON $login.* TO "$login"@"localhost" IDENTIFIED BY '$password';
	FLUSH PRIVILEGES;
	/usr/bin/mysqladmin -u root -p$passroot reload 

	echo "MySQL user $login created"
else
	echo "No MySQL database? OK !"
fi

#Pure-FTPd - password is the same as web - Quota 250M
/usr/bin/pure-pw useradd $login -u ftpuser -d /var/www/$login -N 250
/usr/bin/pure-pw mkdb

echo "FTP account created!"

# MAIL address creation: ex. webmaster@login.monsite.org
/usr/bin/mysql -u root --password=$passroot mail
INSERT INTO users (email,password) VALUES ('webmaster@$login', ENCRYPT('$password'));

echo "Mail address created!"

#We're done!
/etc/init.d/apache2 reload
echo "Apache restarted!"
/etc/init.d/pure-ftpd restart
echo "Pure-FTPd restarted!"

echo "New vhost account creation $login done!"
