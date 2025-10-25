#!/bin/bash

echo "Waiting for MySQL to start..."
sleep 20

echo "Configuring users..."

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';

    CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

    CREATE USER IF NOT EXISTS '${APP_USERNAME}'@'%' IDENTIFIED BY '${APP_USER_PWD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${APP_USERNAME}'@'%' WITH GRANT OPTION;
    
    FLUSH PRIVILEGES;
EOSQL

echo "User setup finished."
