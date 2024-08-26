#!/bin/bash

DB_NAME="sitemanager"

MYSQL_USER=$(grep '^user=' /root/my.cnf | cut -d'=' -f2 | tr -d "' ")
MYSQL_PASS=$(grep '^password=' /root/my.cnf | cut -d'=' -f2 | tr -d "' ")

mysql -u $MYSQL_USER -p$MYSQL_PASS -e "TRUNCATE $DB_NAME.b_search_tags;"

TABLES=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$DB_NAME' AND TABLE_COLLATION != 'utf8mb4_unicode_ci';")

for TABLE in $TABLES; do
    mysql -u $MYSQL_USER -p$MYSQL_PASS -e "ALTER TABLE $DB_NAME.$TABLE CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
done