#!/bin/bash

clear
echo "Payara en Debian 12"

# instalando java
echo "Instalando Java ..."
wget http://www.mirbsd.org/~tg/Debs/sources.txt/wtf-bookworm.sources
mkdir -p /etc/apt/sources.list.d
mv wtf-bookworm.sources /etc/apt/sources.list.d/
apt update
apt install openjdk-8-jdk

# instalando payara
echo "Instalando Payara 4.1.2.181 ..."
cd /opt
wget https://repo1.maven.org/maven2/fish/payara/distributions/payara/4.1.2.181/payara-4.1.2.181.zip
unzip payara-4.1.2.181.zip
cd /opt/payara41/glassfish/lib/
wget https://downloads.mariadb.com/Connectors/java/connector-java-2.7.1/mariadb-java-client-2.7.1.jar
cd /opt/payara41/glassfish/domains/domain1/config
mv domain.xml domain.xml.bak
wget https://raw.githubusercontent.com/malbino/servidor-centos7/master/domain.xml
useradd payara
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

# firewall payara
echo "Configurando el firewall para Payara ..."
apt install ufw
ufw enable
ufw allow 4848
ufw allow 8009

echo "Instalacion finalizada ..."