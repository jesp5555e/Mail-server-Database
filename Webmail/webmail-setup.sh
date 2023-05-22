#!/bin/bash

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
yum install httpd php php-mysqlnd mod_ssl -y

# Installer Roundcube
cd /var/www/html
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.1/roundcubemail-1.6.1-complete.tar.gz
tar -xzf roundcubemail-1.6.1-complete.tar.gz
mv roundcubemail-1.6.1 webmail
chown -R apache:apache webmail
rm -f roundcubemail-1.6.1-complete.tar.gz

# Konfigurer Roundcube
cp -pRv webmail/config/config.inc.php.sample webmail/config/config.inc.php
sed -i "s/\$config\['default_host'\] = '';/\$config\['default_host'\] = 'localhost';/" webmail/config/config.inc.php
sed -i "s/\$config\['smtp_server'\] = '';/\$config\['smtp_server'\] = 'localhost';/" webmail/config/config.inc.php
sed -i "s/\$config\['smtp_user'\] = '';/\$config\['smtp_user'\] = '%u';/" webmail/config/config.inc.php
sed -i "s/\$config\['smtp_pass'\] = '';/\$config\['smtp_pass'\] = '%p';/" webmail/config/config.inc.php

# Generer selvsigneret SSL-certifikat
mkdir /etc/httpd/ssl
openssl req -new -x509 -nodes -days 365 -out /etc/httpd/ssl/server.crt -keyout /etc/httpd/ssl/server.key

# Konfigurer Apache til at bruge SSL
echo "Listen 443" >> /etc/httpd/conf/httpd.conf
echo "<VirtualHost *:443>" >> /etc/httpd/conf/httpd.conf
echo "SSLEngine on" >> /etc/httpd/conf/httpd.conf
echo "SSLCertificateFile /etc/httpd/ssl/server.crt" >> /etc/httpd/conf/httpd.conf
echo "SSLCertificateKeyFile /etc/httpd/ssl/server.key" >> /etc/httpd/conf/httpd.conf
echo "</VirtualHost>" >> /etc/httpd/conf/httpd.conf

# Start Apache-tjenesten
systemctl enable httpd
systemctl start httpd

echo "Mail server and webmail setup completed."