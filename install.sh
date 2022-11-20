#! /usr/bin/env bash

# Author: João Paulo <ojpojao@gmail.com> <joaopaul93@gmail.com>
# Jornada DevOps com AWS - Impulso
#
# Realiza a instalação do servidor Apache com certificado SSL autoassinado e
# configura o site disponibilizado pelo DIO para este desafio de código.

set -xe

echo "##############################################################"
echo "Instalação servidor Apache - Jornada DevOps com AWS - Impulso"
echo "##############################################################"
echo ""

# ajuste timezone
timedatectl set-timezone America/Belem
echo ""

# instala apache
export DEBIAN_FRONTEND=noninteractive
apt update &>/dev/null
apt upgrade -y &>/dev/null
apt install -y \
    apache2 \
    unzip \
    wget &>/dev/null

#
cd /tmp
wget https://github.com/denilsonbonatti/linux-site-dio/archive/refs/heads/main.zip
unzip main.zip &>/dev/null
rm -f /var/www/html/index.html
mv -fu linux-site-dio-main/* /var/www/html/
rm -rf linux-site-dio-main main.zip
cd ~

# cria a chave e o certificado ssl
mkdir -p /etc/dio/certs
mkdir -p /etc/dio/private
SSL_COUNTRY_NAME="BR"
SSL_PROVINCE_NAME="PARA"
SSL_LOCALITY_NAME="ANANINDEUA"
SSL_ORGANIZATION_NAME="Jornada DevOps com AWS - Impulso"
SSL_ORGANIZATION_UNIT=""
SSL_COMMON_NAME=""
SSL_EMAIL_ADDRESS="jornada_devops@teste.local"
SSL_VALIDATE_DAYS="365"
SSL_CERT_PATH="/etc/dio/certs/dio.pem"
SSL_KEYOUT_PATH="/etc/dio/private/dio.key"
openssl req \
    -new \
    -newkey rsa:2048 \
    -days ${SSL_VALIDATE_DAYS}\
    -nodes \
    -x509 \
    -subj "/C=${SSL_COUNTRY_NAME}/ST=${SSL_PROVINCE_NAME}/L=${SSL_LOCALITY_NAME}/O=${SSL_ORGANIZATION_NAME}/OU=${SSL_ORGANIZATION_UNIT}/CN=${SSL_COMMON_NAME}" \
    -out ${SSL_CERT_PATH} \
    -keyout ${SSL_KEYOUT_PATH}
ls -ls /etc/dio/*
chown -R root:root /etc/dio
chmod -R 755 /etc/dio

# configura ssl no apache
cat << EOF > /etc/apache2/conf-available/ssl-params.conf
SSLCipherSuite EECDH+AESGCM:EDH+AESGCM
# Requires Apache 2.4.36 & OpenSSL 1.1.1
SSLProtocol -all +TLSv1.3 +TLSv1.2
SSLOpenSSLConfCmd Curves X25519:secp521r1:secp384r1:prime256v1
# Older versions
# SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLHonorCipherOrder On
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
# Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set X-Frame-Options DENY
Header always set X-Content-Type-Options nosniff
# Requires Apache >= 2.4
SSLCompression off
SSLUseStapling on
SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
# Requires Apache >= 2.4.11
SSLSessionTickets Off
EOF

## /etc/apache2/sites-available/default-ssl.conf
cp -f /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak
SERVER_ADMIN_MAIL="jornada_devops@teste.local"
IFACE=$(ip route | grep default | awk '{print $5}')
SERVER_NAME=$(ip -4 addr | grep inet | grep $IFACE | awk '{print $2}' | cut -d '/' -f1)
sed -i '4 a\ \ \ \ \ \ \ \ ServerName "'${SERVER_NAME}'"' /etc/apache2/sites-available/default-ssl.conf
sed -i -r 's@(^\s+SSLCertificateFile).*$@\1 '${SSL_CERT_PATH}'@' /etc/apache2/sites-available/default-ssl.conf
sed -i -r 's@(^\s+SSLCertificateKeyFile).*$@\1 '${SSL_KEYOUT_PATH}'@' /etc/apache2/sites-available/default-ssl.conf

## /etc/apache2/sites-available/000-default.conf
sed -i '28 a\ \ \ \ \ \ \ \ redirect "/" "https://'${SERVER_NAME}'/"' /etc/apache2/sites-available/000-default.conf
# sed -i '29 a' /etc/apache2/sites-available/000-default.conf

# habilita ssl no apache
a2enmod ssl
a2enmod headers
a2ensite default-ssl
systemctl reload apache2
a2enconf ssl-params
apache2ctl configtest

echo "Reiniciando Serviço do Apache"
echo ""
systemctl restart apache2
sleep 4
APACHE_STATUS=$(systemctl status apache2.service --no-pager | grep -i active | awk '{print $2,$3}' | tr -d '()' | awk '{print $2}')

# limpa as variáveis criadas
unset SSL_COUNTRY_NAME
unset SSL_PROVINCE_NAME
unset SSL_LOCALITY_NAME
unset SSL_ORGANIZATION_NAME
unset SSL_ORGANIZATION_UNIT
unset SSL_COMMON_NAME
unset SSL_EMAIL_ADDRESS
unset SSL_VALIDATE_DAYS
unset SSL_CERT_PATH
unset SSL_KEYOUT_PATH
unset SERVER_ADMIN_MAIL
unset IFACE
unset SERVER_NAME
if [ $APACHE_STATUS == "running" ]; then
    echo "Apache reiniciado com sucesso!!!"
    echo "###### Configuração finalizada com sucesso!!######"
    echo ""
    unset APACHE_STATUS
    exit 0
else
    systemctl status apache2.service --no-pager
    journalctl -xe -u apache2 --no-pager
    echo "Ohh, mano! Deu BO na tua instalação."
    unset APACHE_STATUS
    exit 1
fi
