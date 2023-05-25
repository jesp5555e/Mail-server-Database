#!/bin/bash

# Installer nødvendige pakker
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
yum install firewalld -y

# Start og aktiver firewalld-tjenesten
systemctl start firewalld
systemctl enable firewalld

# Konfigurer firewall-regler for webmail-serveren
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=smtp
firewall-cmd --reload

# Installer Postfix og Dovecot
yum install postfix dovecot -y

# Konfigurer Postfix
echo "myhostname = mail-server.kbytech.dom" >> /etc/postfix/main.cf
echo "mydomain = kbytech.dom" >> /etc/postfix/main.cf
echo "myorigin = \$mydomain" >> /etc/postfix/main.cf
echo "inet_interfaces = all" >> /etc/postfix/main.cf
echo "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain" >> /etc/postfix/main.cf
echo "mynetworks = 127.0.0.0/8" >> /etc/postfix/main.cf
echo "home_mailbox = Maildir/" >> /etc/postfix/main.cf
echo "smtpd_sasl_type = dovecot" >> /etc/postfix/main.cf
echo "smtpd_sasl_path = private/auth" >> /etc/postfix/main.cf
echo "smtpd_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "smtpd_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
echo "smtpd_sasl_local_domain =" >> /etc/postfix/main.cf
echo "smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination" >> /etc/postfix/main.cf

# Genstart Postfix-tjenesten
systemctl restart postfix

# Konfigurer Dovecot
echo "mail_location = maildir:~/Maildir" >> /etc/dovecot/conf.d/10-mail.conf
echo "auth_mechanisms = plain login" >> /etc/dovecot/conf.d/10-auth.conf
echo "ssl = no" >> /etc/dovecot/conf.d/10-ssl.conf

# Aktivér og start Dovecot-tjenesten
systemctl enable dovecot
systemctl start dovecot

# Installer nødvendige pakker for webmail
yum install httpd php php-mysqlnd mod_ssl mysql yum-utils -y

# Installer og konfigurer Remi-repository
yum install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
yum-config-manager --set-enable remi

# Opdater systemet
yum update -y
yum upgrade -y

# Installer Roundcube fra Remi-repository
yum install roundcubemail -y

# Konfigurer Roundcube
cp -pRv /etc/roundcubemail/config.inc.php.sample /etc/roundcubemail/config.inc.php
sed -i "s/\$config\['db_dsnw'\] = 'mysql://roundcube:pass@localhost/roundcubemail';/\$config\['db_dsnw'\] = 'mysql://roundcube:Kode1234!@192.168.69.3/roundcubemail';/" /etc/roundcubemail/config.inc.php
sed -i "s/\$config\['default_host'\] = 'localhost';/\$config\['default_host'\] = 'localhost';/" /etc/roundcubemail/config.inc.php
sed -i "s/\$config\['smtp_server'\] = 'localhost';/\$config\['smtp_server'\] = 'localhost';/" /etc/roundcubemail/config.inc.php
sed -i "s/\$config\['smtp_user'\] = '%u';/\$config\['smtp_user'\] = '%u';/" /etc/roundcubemail/config.inc.php
sed -i "s/\$config\['smtp_pass'\] = '%p';/\$config\['smtp_pass'\] = '%p';/" /etc/roundcubemail/config.inc.php

# Company details selvsigneret SSL-certifikat
country=DK
state=Sjaelland
locality=Keldby
organization=Keldby Technology
organizationalunit=IT
email=mail@kbytech.dom

# Generer selvsigneret SSL-certifikat
mkdir /etc/httpd/ssl
openssl req -new -x509 -nodes -days 365 -out /etc/httpd/ssl/server.crt -keyout /etc/httpd/ssl/server.key -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

# Konfigurer Apache til at bruge SSL
echo "<VirtualHost *:443>" >> /etc/httpd/conf/httpd.conf
echo "SSLEngine on" >> /etc/httpd/conf/httpd.conf
echo "SSLCertificateFile /etc/httpd/ssl/server.crt" >> /etc/httpd/conf/httpd.conf
echo "SSLCertificateKeyFile /etc/httpd/ssl/server.key" >> /etc/httpd/conf/httpd.conf
echo "</VirtualHost>" >> /etc/httpd/conf/httpd.conf

# Start Apache-tjenesten
systemctl enable httpd
systemctl start httpd

echo "Mail server and webmail setup completed."