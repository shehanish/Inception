#!/bin/bash
set -e

echo "MariaDB initialization script started"

# Read secrets
if [ ! -f /run/secrets/db_root_password ] || [ ! -f /run/secrets/db_password ]; then
    echo "ERROR: Secret files not found!"
    exit 1
fi

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

echo "Secrets loaded successfully"

# Check if database is already initialized by looking for a marker file
if [ ! -f "/var/lib/mysql/.initialized" ]; then
    echo "Initializing MariaDB database..."
    
    # Remove any incomplete initialization
    rm -rf /var/lib/mysql/*
    
    # Initialize the database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db

    # Start MariaDB temporarily in background
    echo "Starting temporary MariaDB instance..."
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    # Wait for MariaDB to start
    echo "Waiting for MariaDB to start..."
    sleep 3
    
    for i in {30..0}; do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        echo "MariaDB is starting up... waiting ($i seconds left)"
        sleep 1
    done
    
    if [ "$i" = 0 ]; then
        echo "ERROR: MariaDB failed to start within timeout"
        kill -s TERM "$pid" 2>/dev/null || true
        exit 1
    fi

    echo "MariaDB started successfully"

    # Configure root user (force socket connection by using localhost)
    mysql -u root -h localhost <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        FLUSH PRIVILEGES;
EOSQL

    # Create database and user
    mysql -u root -p"${DB_ROOT_PASSWORD}" -h localhost <<-EOSQL
        CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    echo "Database and user created successfully"

    # Create marker file to indicate successful initialization
    touch /var/lib/mysql/.initialized

    # Stop the temporary MariaDB instance
    echo "Stopping temporary MariaDB instance..."
    if ! mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown 2>/dev/null; then
        echo "Shutdown command failed, forcing stop..."
        kill -s TERM "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi

    echo "MariaDB initialization complete"
else
    echo "MariaDB database already initialized (marker file exists)"
    
    # Verify data directory has valid database files
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "WARNING: Marker file exists but data is corrupted. Re-initializing..."
        rm -f /var/lib/mysql/.initialized
        rm -rf /var/lib/mysql/*
        exec "$0" "$@"
    fi
fi

# Ensure proper permissions
chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /run/mysqld

# Start MariaDB in foreground
echo "Starting MariaDB in foreground..."
exec mysqld --user=mysql --console
