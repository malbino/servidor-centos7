#!/bin/bash
if [ -z "$1" ]; then
	os="otro"
fi
clear
echo "ispconfig en centos-7"
echo "Espero hayas hecho una instalacion minima"
echo
setenforce 0
if [ `egrep -c ^SELINUX=enforcing /etc/sysconfig/selinux` -ne 0 ]; then
        sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/sysconfig/selinux
fi
if [ `egrep -c ^SELINUX=enforcing /etc/selinux/config` -ne 0 ]; then
	sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
fi

if [ $(mount |egrep "/ " |egrep -c xfs) -ne 0 ]; then
	echo "Para activar quotas edita /etc/default/grub"
	echo "y agrega: rootflags=uquota,gquota al final de GRUB_CMDLINE_LINUX"
	echo "luego grub2-mkconfig -o /boot/grub2/grub.cfg"
	echo "y reinicia y vuelve a ejecutar este script"
	echo
fi
echo "Presiona ENTER si quieres continuar, o CTRL C para abortar"
read
yum -y update
yum -y install firewalld wget screen epel-release yum-priorities quota which rsync centos-release-scl

systemctl enable --now firewalld.service
firewall-cmd --zone=public --add-port 443/tcp --add-port 80/tcp --zone=public --add-port 8080/tcp --zone=public --add-port 25/tcp --zone=public --add-port 110/tcp --add-port 22/tcp --add-port 143/tcp --add-port 21/tcp --add-port 587/tcp --permanent
firewall-cmd --reload

touch /usr/bin/cron
chmod +x /usr/bin/cron

sed -i s/enabled=1/enabled=0/g /etc/yum.repos.d/epel.repo

yum clean all

yum --enablerepo=epel -y install clamav-server-systemd clamav-server net-tools NetworkManager-tui ntp httpd mod_ssl mariadb-server php php-mysql php-mbstring phpmyadmin dovecot dovecot-mysql dovecot-pigeonhole postfix postgrey getmail amavisd-new spamassassin clamav clamd clamav-update unzip bzip2 perl-DBD-mysql php php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel pure-ftpd openssl bind bind-utils webalizer awstats perl-DateTime-Format-HTTP perl-DateTime-Format-Builder fail2ban rkhunter mailman roundcubemail python-certbot-apache rh-php73-php-soap rh-php73-php-pear rh-php73-php-xmlrpc rh-php73-php-opcache rh-php73-php-mbstring rh-php73-php-intl rh-php73-php-gd rh-php73-php-fpm rh-php73-php-cli rh-php73-php-mysqlnd

touch /etc/dovecot/dovecot-sql.conf
ln -s /etc/dovecot/dovecot-sql.conf /etc/dovecot-sql.conf

ln -s /etc/clamd.d/amavisd.conf /etc/clamd.conf

systemctl disable --now sendmail.service
systemctl enable dovecot mariadb.service postfix.service clamd@amavis httpd.service amavisd.service
systemctl restart clamd@amavis dovecot mariadb.service postfix.service httpd.service

echo "················ mysql_secure_installation ··············"
mysql_secure_installation

wget -O /etc/httpd/conf.d/phpMyAdmin.conf https://proyectoorion.com/downloads/ispconfig7/phpMyAdmin
wget -O /etc/httpd/conf.d/ssl.conf https://proyectoorion.com/downloads/ispconfig7/ssl
wget -O /etc/phpMyAdmin/config.inc.php https://proyectoorion.com/downloads/ispconfig7/config.myadmin
wget -O /etc/freshclam.conf https://proyectoorion.com/downloads/ispconfig7/freshclam
wget -O /etc/php.ini https://proyectoorion.com/downloads/ispconfig7/php.txt

sa-update
freshclam

#yum -y install https://anku.ecualinux.com/7/x86_64/mod_suphp-0.7.2-1.el7.centos.x86_64.rpm

#wget -q -O /etc/suphp.conf https://proyectoorion.com/downloads/ispconfig7/suphp
#wget  -q -O /etc/httpd/conf.d/mod_suphp.conf https://proyectoorion.com/downloads/ispconfig7/mod_suphp
wget  -q -O /etc/httpd/conf.d/php.conf https://proyectoorion.com/downloads/ispconfig7/php

#chmod +s /usr/sbin/suphp

systemctl enable --now rh-php73-php-fpm
systemctl enable --now httpd.service 
systemctl enable --now pure-ftpd.service

mkdir -p /etc/ssl/private/
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem -subj '/CN=localhost.localdomain/O=My Company Name LTD./C=EC'
chmod 600 /etc/ssl/private/pure-ftpd.pem
systemctl restart pure-ftpd.service

wget -q -O /etc/named.conf https://proyectoorion.com/downloads/ispconfig7/named
touch /etc/named.conf.local
#fail2ban
wget -q -O /etc/fail2ban/jail.d/00-firewalld.conf https://proyectoorion.com/downloads/ispconfig7/00-firewalld
wget -q -O /etc/fail2ban/jail.d/postfix.local https://proyectoorion.com/downloads/ispconfig7/postfix.local
wget -q -O /etc/fail2ban/jail.d/sshd.local https://proyectoorion.com/downloads/ispconfig7/sshd.local

systemctl enable --now named.service
systemctl enable --now fail2ban.service

touch /var/lib/mailman/data/aliases
wget  -q -O /etc/roundcubemail/config.inc.php https://proyectoorion.com/downloads/ispconfig7/config.rc
wget  -q -O /tmp/rcm.sql https://proyectoorion.com/downloads/ispconfig7/rcm

echo "Entre la clave de root de MySQL"
mysql -u root -p < /tmp/rcm.sql

wget -O /etc/httpd/conf.d/roundcubemail.conf https://proyectoorion.com/downloads/ispconfig7/roundcubemail.conf.local

cat /etc/roundcubemail/config.inc.php|egrep -v enable_installer > /tmp/config.inc.php
cat /tmp/config.inc.php > /etc/roundcubemail/config.inc.php

systemctl restart httpd.service

cd /tmp
wget https://ispconfig.org/downloads/ISPConfig-3.2.5.tar.gz
tar xfz ISPConfig-3.2.5.tar.gz
cd ispconfig3_install/install/

php -q install.php
wget -O /usr/lib/mailman/Mailman/mm_cfg.py https://proyectoorion.com/downloads/ispconfig7/mm_cfg.py
chown root.mailman /usr/lib/mailman/Mailman/mm_cfg.py

#systemctl restart mailman

rm -rf /tmp/ispconfig3_install /tmp/*.rpm /tmp/ispconfig.tar.gz
cd /usr/local/ispconfig/server/scripts
wget https://www.ispconfig.org/downloads/ispconfig_patch
chmod 700 ispconfig_patch
chown root:root ispconfig_patch
ln -s /usr/local/ispconfig/server/scripts/ispconfig_patch /usr/local/bin/ispconfig_patch
wget -O /etc/postfix/master.cf https://proyectoorion.com/downloads/ispconfig7/master.cf
wget -O /etc/postfix/main.cf https://proyectoorion.com/downloads/ispconfig7/main.cf
openssl req -new -outform PEM -out /etc/postfix/smtpd.cert -newkey rsa:2048 -nodes -keyout /etc/postfix/smtpd.key -keyform PEM -days 365 -x509 -subj '/CN=localhost.localdomain/O=My Company Name LTD./C=EC'

wget -O /etc/sysconfig/postgrey https://proyectoorion.com/downloads/ispconfig7/postgrey.txt
wget -O /etc/postfix/postgrey_whitelist_clients https://raw.githubusercontent.com/schweikert/postgrey/master/postgrey_whitelist_clients
#wget -O /usr/local/ispconfig/server/conf-custom/vhost.conf.master https://proyectoorion.com/downloads/ispconfig7/vhost.conf.master
#chmod 760 /usr/local/ispconfig/server/conf-custom/vhost.conf.master
#chown root.root /usr/local/ispconfig/server/conf-custom/vhost.conf.master

systemctl enable postgrey httpd
systemctl restart postgrey postfix dovecot
systemctl reload httpd

#yum -y erase NetworkManager*

rm -f /usr/bin/cron

echo "Vete al ispconfig System -> Aditional PHP versions y agrega una nueva"
echo "PHPName: rh-php73"
echo "PHP CGI: /opt/rh/rh-php73/root/usr/bin/php-cgi * /etc/opt/rh/rh-php73"
echo "PHP-FPM: rh-php73-php-fpm * /etc/opt/rh/rh-php73 * /etc/opt/rh/rh-php73/php-fpm.d"
