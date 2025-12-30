FROM debian:bookworm

# Install MariaDB
RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories and set permissions
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# Copy configuration file
COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh

# Expose MariaDB port
EXPOSE 3306

# Run initialization script, then start MariaDB
ENTRYPOINT ["/usr/local/bin/init_db.sh"]
CMD ["mysqld"]