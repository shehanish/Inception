FROM debian:bullseye

# Install MariaDB server
RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy MariaDB configuration
COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/mariadb.cnf

# Copy initialization script
COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

# Create directory for MariaDB runtime files
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql

# Expose MariaDB port
EXPOSE 3306

# Run initialization script
ENTRYPOINT ["/usr/local/bin/init_db.sh"]
