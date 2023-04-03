#!/bin/bash

clear
echo "Orion en Centos 7"

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
wget https://raw.githubusercontent.com/malbino/servidor-centos7/master/domain.xml
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
wget https://raw.githubusercontent.com/malbino/servidor-centos7/master/payara.service
systemctl enable payara
systemctl start payara

# csf firewall
echo "Configurando el firewall para Payara ..."
sed -i "s|2030,2031,2082,2083,2086,2087,2095,2096|2030,2031,2082,2083,2086,2087,2095,2096,4848|" /etc/csf/csf.conf
csf -r

# instalacion mod_jk
echo "Instalando mod_jk de Apache ..."
yum install httpd-devel gcc libtool
cd /opt
wget https://downloads.apache.org/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.48-src.tar.gz
tar zxf tomcat-connectors-1.2.48-src.tar.gz
cd tomcat-connectors-1.2.48-src/native
LDFLAGS=-lc ./configure -with-apxs=/usr/local/apache/bin/apxs
make
cp ./apache-2.0/mod_jk.so /usr/local/apache/modules

# configuracion mod_jk
echo "Configurando mod_jk de Apache ..."
# "JkMount /* worker1" IPSConfig/Sites/Options/Apache Directives
cd /usr/local/apache/conf.d/
wget https://raw.githubusercontent.com/malbino/servidor-centos7/master/mod_jk_cwp
mv mod_jk_cwp mod_jk.conf
wget https://raw.githubusercontent.com/malbino/servidor-centos7/master/worker.properties
cd /usr/lib/systemd/system
mv httpd.service httpd.service.bak
wget https://raw.githubusercontent.com/malbino/servidor-centos7/master/httpd.service
systemctl enable httpd.service
systemctl restart httpd.service

echo "Instalacion finalizada ..."
echo "Nota: En CWP7.admin/WebServer Settings/WebServers Conf Editor/</usr/local/apache/conf.d/vhosts>"
echo "en el <Conf File> <dominio.ssl.conf> agrege la siguiente linea dentro la seccion <VirtualHost ip:443>"
echo "JkMount /* worker1"