#!/bin/bash

clear
echo "mod_jk en Debian 12"

# instalacion mod_jk
apt-get install libapache2-mod-jk
a2enmod jk

echo "Instalacion finalizada ..."
echo "Nota: En IPSConfig/Sites/Options/Apache Directives añada la siguiente linea"
echo "JkMount /* ajp13_worker"