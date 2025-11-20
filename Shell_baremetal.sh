#!/bin/bash
sudo apt-get update -y
sudo apt-get install apache2 mysql-server mysql-client php php-mysql libapache2-mod-php -y 

# Destination directory
DEST_DIR="/var/www/html/mompopcafe"

# Check if the destination directory exists
if [ ! -d "$DEST_DIR" ]; then
    sudo mkdir -p "$DEST_DIR"
    sudo cp -rf ../../mompopcafe/* "$DEST_DIR/"
    echo "Files copied to $DEST_DIR."
else
    echo "Directory $DEST_DIR already exists. Skipping copy."
fi

# Update Apache DocumentRoot
sudo sed -E -i 's|DocumentRoot[[:space:]]+/var/www/html.*|DocumentRoot /var/www/html/mompopcafe|' \
    /etc/apache2/sites-available/000-default.conf

sudo systemctl restart apache2


#############################
#       MYSQL SECTION       #
#############################

DB_USER="root"
DB_APP_USER="msis"
DB_PASSWORD="Msois@123"
DB_HOST="localhost"
DB_NAME="mom_pop_db"
SQL_SCRIPT="../../mompopdb/create-db.sql"

# Create App User
sudo mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" <<EOF
CREATE USER IF NOT EXISTS '$DB_APP_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_PASSWORD';
ALTER USER '$DB_APP_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$DB_APP_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Create DB if not exists + Execute SQL
DB_EXISTS=$(mysql -h$DB_HOST -u$DB_USER -p$DB_PASSWORD -e \
"SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$DB_NAME';" --skip-column-names)

if [ "$DB_EXISTS" -eq 0 ]; then
    mysql -h$DB_HOST -u$DB_APP_USER -p$DB_PASSWORD -e "CREATE DATABASE $DB_NAME;"
    mysql -h$DB_HOST -u$DB_APP_USER -p$DB_PASSWORD $DB_NAME < $SQL_SCRIPT
    echo "Database created + SQL executed."
else
    echo "Database already exists."
fi


##############################################
#   CREATE getAppParameters.php AUTOMATICALLY
##############################################

cat <<EOF | sudo tee $DEST_DIR/getAppParameters.php > /dev/null
<?php
// Application parameters for DB

\$db_url = "localhost";
\$db_user = "msis";
\$db_password = "Msois@123";
\$db_name = "mom_pop_db";

// Currency symbol
\$currency = "₹";

// Whether to show server metadata or not
\$showServerInfo = false;
?>
EOF

sudo chmod 644 $DEST_DIR/getAppParameters.php
sudo chown www-data:www-data $DEST_DIR/getAppParameters.php

echo "getAppParameters.php created successfully."


# Output app URL
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Cafe app is accessible at: http://$IP_ADDRESS/mompopcafe"
