#!/bin/bash

# Installer MariaDB-server
yum install mariadb-server -y

# Start MariaDB-tjenesten
service mariadb start

# Konfigurer MariaDB
mysql -u root -e "CREATE DATABASE roundcubemail;"
mysql -u root -e "GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'192.168.69.2' IDENTIFIED BY 'Kode1234!';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Aktivér fjernadgang til MariaDB-serveren
echo "bind-address = 192.168.69.3" >> /etc/my.cnf

# Genstart MariaDB-tjenesten
service mariadb restart

echo "Database server setup completed."