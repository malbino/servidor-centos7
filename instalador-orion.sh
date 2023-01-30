#!/bin/bash

clear
echo "Orion en Centos 7"

# actualizando MariaDB
echo "Actualizando MariaDB ..."
systemctl stop mariadb
cd /etc/yum.repos.d
wget https://proyectoorion.com/downloads/MariaDB.repo
yum update
systemctl enable mariadb
systemctl start mariadb
echo "Ingrese la contraseña del usuario root de mariadb"
mysql_upgrade -u root -p

# instalando payara
echo "Instalando Payara 4.1.2.181 ..."
yum install java-1.8.0-openjdk-devel
cd /opt
wget https://repo1.maven.org/maven2/fish/payara/distributions/payara/4.1.2.181/payara-4.1.2.181.zip
unzip payara-4.1.2.181.zip
cd /opt/payara41/glassfish/lib/
wget https://downloads.mariadb.com/Connectors/java/connector-java-2.7.1/mariadb-java-client-2.7.1.jar
cd /opt/payara41/glassfish/domains/domain1/config
mv domain.xml domain.xml.bak
wget https://proyectoorion.com/downloads/domain.xml
adduser payara
chown -R payara:payara /opt/payara41

# configuracion consola administracion de payara
echo "Configurando la consola de administracion de Payara ..."
su payara -c "/opt/payara41/glassfish/bin/asadmin change-admin-password --domain_name domain1"
su payara -c "/opt/payara41/glassfish/bin/asadmin start-domain domain1"
su payara -c "/opt/payara41/glassfish/bin/asadmin enable-secure-admin --port 4848"
su payara -c "/opt/payara41/glassfish/bin/asadmin stop-domain domain1"

# servicio payara
echo "Instalando el servicio de Payara ..."
cd /etc/systemd/system/
wget https://proyectoorion.com/downloads/payara.service
systemctl enable payara
systemctl start payara

# firewall payara
echo "Configurando el firewall para Payara ..."
firewall-cmd --zone=public --add-port=4848/tcp --permanent
firewall-cmd --reload

# instalacion mod_jk
echo "Instalando mod_jk de Apache ..."
yum install gcc gcc-c++ autoconf libtool
mkdir -p /opt/mod_jk/
cd /opt/mod_jk
wget https://downloads.apache.org/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.48-src.tar.gz
tar zxf tomcat-connectors-1.2.48-src.tar.gz
cd tomcat-connectors-1.2.48-src/native
./configure --with-apxs=/usr/bin/apxs
make
libtool --finish /usr/lib64/httpd/modules
make install

# configuracion mod_jk
echo "Configurando mod_jk de Apache ..."
# "JkMount /* worker1" IPSConfig/Sites/Options/Apache Directives
cd /etc/httpd/conf.modules.d/
wget https://proyectoorion.com/downloads/mod_jk
mv mod_jk mod_jk.conf
wget https://proyectoorion.com/downloads/worker.properties

echo "Instalacion finalizada ..."
echo "Nota: En IPSConfig/Sites/Options/Apache Directives añada la siguiente linea"
echo "JkMount /* worker1"