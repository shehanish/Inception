# Developer Documentation - Inception Project

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Project Structure](#project-structure)
3. [Building the Project](#building-the-project)
4. [Managing Containers and Volumes](#managing-containers-and-volumes)
5. [Service Architecture](#service-architecture)
6. [Data Persistence](#data-persistence)
7. [Development Workflow](#development-workflow)
8. [Debugging and Testing](#debugging-and-testing)

## Environment Setup

### Prerequisites

Install the following on your development machine:

```bash
# Update package list
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io

# Install Docker Compose
sudo apt-get install -y docker-compose

# Add user to docker group (optional, to run docker without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Install Make
sudo apt-get install -y make
```

### Domain Configuration

Add the domain to your `/etc/hosts` file:

```bash
sudo bash -c 'echo "127.0.0.1 shkaruna.42.fr" >> /etc/hosts'
```

### Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd Inception

# Verify directory structure
ls -la
```

### Configuration Files

#### 1. Environment Variables (`srcs/.env`)

This file contains all non-sensitive configuration. Create it if it doesn't exist:

```bash
cat > srcs/.env << 'EOF'
# Domain Configuration
DOMAIN_NAME=shkaruna.42.fr

# MySQL/MariaDB Configuration
MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_password
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress_user
MYSQL_PASSWORD_FILE=/run/secrets/db_password
MYSQL_HOST=mariadb

# WordPress Configuration
WP_ADMIN_USER=wpmaster
WP_ADMIN_PASSWORD=AdminPass789Secure!
WP_ADMIN_EMAIL=wpmaster@shkaruna.42.fr
WP_USER=wpuser
WP_USER_PASSWORD=UserPass321!
WP_USER_EMAIL=wpuser@shkaruna.42.fr
WP_TITLE=Inception WordPress
WP_URL=https://shkaruna.42.fr

# Paths
WP_PATH=/var/www/html
DB_DATA_PATH=/home/shkaruna/data/mariadb
WP_DATA_PATH=/home/shkaruna/data/wordpress
EOF
```

**Important**: This file is gitignored. Customize it for your environment.

#### 2. Docker Secrets (`secrets/`)

Create secret files for sensitive data:

```bash
# Create secrets directory
mkdir -p secrets

# Database root password
echo "YourSecureRootPassword123!" > secrets/db_root_password.txt

# WordPress database user password
echo "YourSecureUserPassword456!" > secrets/db_password.txt

# Create credentials reference file
cat > secrets/credentials.txt << 'EOF'
WordPress Admin User: wpmaster
WordPress Admin Password: AdminPass789Secure!
WordPress Regular User: wpuser
Database Root Password: YourSecureRootPassword123!
Database User Password: YourSecureUserPassword456!
EOF

# Ensure secrets are gitignored
echo "*.txt" > secrets/.gitignore
```

**Security Note**: Never commit these files to Git!

### Create Data Directories

```bash
sudo mkdir -p /home/shkaruna/data/mariadb
sudo mkdir -p /home/shkaruna/data/wordpress
```

## Project Structure

```
Inception/
├── Makefile                                 # Build automation
├── README.md                               # Project overview
├── USER_DOC.md                            # User documentation
├── DEV_DOC.md                             # This file
├── secrets/                               # Sensitive credentials (gitignored)
│   ├── .gitignore
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                               # Environment variables (gitignored)
    ├── docker-compose.yml                 # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile                 # MariaDB container definition
        │   ├── .dockerignore             # Files to exclude from build
        │   ├── conf/
        │   │   └── 50-server.cnf         # MariaDB server configuration
        │   └── tools/
        │       └── init_db.sh            # Database initialization script
        ├── nginx/
        │   ├── Dockerfile                 # NGINX container definition
        │   ├── .dockerignore             # Files to exclude from build
        │   └── conf/
        │       └── nginx.conf            # NGINX web server + TLS config
        └── wordpress/
            ├── Dockerfile                 # WordPress + PHP-FPM container
            ├── .dockerignore             # Files to exclude from build
            └── tools/
                └── setup_wordpress.sh     # WordPress installation script
```

## Building the Project

### Using Makefile

The Makefile provides convenient commands:

```bash
# Build all images and start containers
make

# Or step by step:
make build    # Build Docker images only
make up       # Start containers
```

### Using Docker Compose Directly

```bash
# Build images
docker compose -f srcs/docker-compose.yml build

# Build without cache (force rebuild)
docker compose -f srcs/docker-compose.yml build --no-cache

# Build specific service
docker compose -f srcs/docker-compose.yml build nginx

# Start services
docker compose -f srcs/docker-compose.yml up -d

# View build logs
docker compose -f srcs/docker-compose.yml logs -f
```

### Understanding the Build Process

1. **Image Building**: Docker reads each Dockerfile and builds images layer by layer
2. **Layer Caching**: Subsequent builds reuse unchanged layers
3. **Secrets Mounting**: Docker secrets are mounted at runtime (not during build)
4. **Volume Creation**: Named volumes are created or bound to host directories
5. **Network Creation**: Custom bridge network `inception` is created
6. **Container Startup**: Containers start in dependency order (health checks)

### Build Optimization

To optimize build times:

```bash
# Use BuildKit for better caching
export DOCKER_BUILDKIT=1

# Multi-stage builds are already implemented in Dockerfiles
# Remove unused images
docker image prune -f

# Remove build cache
docker builder prune -af
```

## Managing Containers and Volumes

### Container Management

```bash
# List running containers
docker ps
# or
make ps

# List all containers (including stopped)
docker ps -a

# Stop all containers
docker compose -f srcs/docker-compose.yml down
# or
make down

# Restart specific service
docker compose -f srcs/docker-compose.yml restart nginx

# Restart all services
make restart

# View logs for specific container
docker logs nginx
docker logs wordpress
docker logs mariadb

# Follow logs in real-time
docker logs -f nginx

# View logs for all services
make logs

# Execute command in running container
docker exec -it nginx /bin/bash
docker exec -it wordpress /bin/bash
docker exec -it mariadb /bin/bash

# Check container resource usage
docker stats

# Inspect container configuration
docker inspect nginx
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect inception_wordpress_data
docker volume inspect inception_mariadb_data

# Check volume mount points
docker inspect nginx | grep -A 10 Mounts

# View volume contents (via host)
sudo ls -la /home/shkaruna/data/wordpress
sudo ls -la /home/shkaruna/data/mariadb

# Backup volumes
sudo tar -czf backup-wordpress-$(date +%Y%m%d).tar.gz /home/shkaruna/data/wordpress
sudo tar -czf backup-mariadb-$(date +%Y%m%d).tar.gz /home/shkaruna/data/mariadb

# Remove volumes (⚠️ deletes data!)
docker compose -f srcs/docker-compose.yml down --volumes
# or
make fclean
```

### Network Management

```bash
# List networks
docker network ls

# Inspect inception network
docker network inspect inception

# View connected containers
docker network inspect inception | grep -A 5 Containers

# Test connectivity between containers
docker exec wordpress ping -c 3 mariadb
docker exec wordpress ping -c 3 nginx
docker exec nginx ping -c 3 wordpress

# Check DNS resolution
docker exec wordpress nslookup mariadb
```

## Service Architecture

### NGINX (Web Server)

**Purpose**: Reverse proxy and TLS termination

**Key Features**:
- Listens on port 443 (HTTPS only)
- TLS 1.2/1.3 with strong ciphers
- Forwards PHP requests to WordPress container via FastCGI
- Serves static files directly
- Self-signed SSL certificate

**Dockerfile Breakdown**:
```dockerfile
FROM debian:bullseye              # Base image
RUN apt-get install nginx openssl # Install packages
RUN openssl req ...               # Generate SSL cert
COPY conf/nginx.conf ...          # Copy configuration
CMD ["nginx", "-g", "daemon off;"]# Run in foreground (PID 1)
```

**Configuration Files**:
- `nginx.conf`: Main configuration with TLS and FastCGI settings

**Debugging**:
```bash
# Check configuration syntax
docker exec nginx nginx -t

# Reload configuration
docker exec nginx nginx -s reload

# View error logs
docker exec nginx cat /var/log/nginx/error.log

# View access logs
docker exec nginx cat /var/log/nginx/access.log
```

### MariaDB (Database)

**Purpose**: Persistent data storage for WordPress

**Key Features**:
- Binds to all interfaces (0.0.0.0) for container access
- Uses Docker secrets for passwords
- Automatic database initialization
- Health checks via mysqladmin

**Dockerfile Breakdown**:
```dockerfile
FROM debian:bullseye                    # Base image
RUN apt-get install mariadb-server ...  # Install MariaDB
COPY conf/50-server.cnf ...             # Copy config
COPY tools/init_db.sh ...               # Copy init script
ENTRYPOINT ["/usr/local/bin/init_db.sh"]# Run initialization
```

**Initialization Process** (`init_db.sh`):
1. Check if database already initialized
2. Run `mysql_install_db` if needed
3. Start MariaDB temporarily
4. Set root password
5. Create WordPress database and user
6. Stop temporary instance
7. Start MariaDB in foreground

**Debugging**:
```bash
# Connect to database
docker exec -it mariadb mysql -u root -p

# Check database status
docker exec mariadb mysqladmin -u root -p status

# View database list
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Check WordPress database
docker exec mariadb mysql -u root -p wordpress_db -e "SHOW TABLES;"

# View MariaDB logs
docker exec mariadb cat /var/log/mysql/error.log
```

### WordPress (Application Server)

**Purpose**: Content management system with PHP-FPM

**Key Features**:
- PHP 7.4 with FPM (FastCGI Process Manager)
- WP-CLI for command-line management
- Automatic WordPress installation
- Creates admin and regular users
- Connects to MariaDB via Docker network

**Dockerfile Breakdown**:
```dockerfile
FROM debian:bullseye                    # Base image
RUN apt-get install php7.4-fpm ...      # Install PHP-FPM
RUN curl -O wp-cli.phar ...             # Install WP-CLI
RUN sed -i ... php7.4-fpm.sock          # Configure PHP-FPM to listen on port 9000
ENTRYPOINT ["setup_wordpress.sh"]       # Run setup script
```

**Setup Process** (`setup_wordpress.sh`):
1. Wait for MariaDB to be ready
2. Download WordPress core files (if not present)
3. Generate `wp-config.php` with database credentials
4. Run WordPress installation
5. Create additional user
6. Set proper permissions
7. Start PHP-FPM in foreground

**Debugging**:
```bash
# Check WordPress installation
docker exec wordpress wp core version --allow-root

# List WordPress users
docker exec wordpress wp user list --allow-root

# Check plugins
docker exec wordpress wp plugin list --allow-root

# Check themes
docker exec wordpress wp theme list --allow-root

# Test database connectivity
docker exec wordpress wp db check --allow-root

# View PHP-FPM status
docker exec wordpress ps aux | grep php-fpm

# Check PHP-FPM logs
docker exec wordpress cat /var/log/php7.4-fpm.log
```

## Data Persistence

### Volume Types

The project uses **Docker volumes with bind mounts**:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/shkaruna/data/mariadb
```

This provides:
- Docker volume management
- Explicit host path access
- Data persistence across container rebuilds
- Easy backup and restore

### Data Locations

**Host Machine**:
- MariaDB data: `/home/shkaruna/data/mariadb/`
- WordPress files: `/home/shkaruna/data/wordpress/`

**Inside Containers**:
- MariaDB: `/var/lib/mysql`
- WordPress: `/var/www/html`

### Data Persistence Testing

```bash
# Create test post
docker exec wordpress wp post create \
    --post_title="Test Post" \
    --post_content="Testing persistence" \
    --post_status=publish \
    --allow-root

# Stop containers
make down

# Start containers
make up

# Verify post still exists
docker exec wordpress wp post list --allow-root
```

## Development Workflow

### Making Changes to Services

#### 1. Modify NGINX Configuration

```bash
# Edit configuration
vim srcs/requirements/nginx/conf/nginx.conf

# Rebuild and restart
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d nginx

# Test changes
curl -k https://shkaruna.42.fr
```

#### 2. Modify MariaDB Configuration

```bash
# Edit configuration
vim srcs/requirements/mariadb/conf/50-server.cnf

# Rebuild (⚠️ may require data reset)
make fclean
make
```

#### 3. Modify WordPress Setup

```bash
# Edit setup script
vim srcs/requirements/wordpress/tools/setup_wordpress.sh

# Rebuild
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress
```

### Testing Changes

```bash
# Run syntax checks
docker exec nginx nginx -t
docker exec mariadb mysqladmin ping

# View real-time logs
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Check health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Test endpoints
curl -k https://shkaruna.42.fr
curl -k https://shkaruna.42.fr/wp-admin
```

### Environment Variables

To change environment variables:

1. Edit `srcs/.env`
2. Rebuild affected containers
3. Restart services

```bash
# Edit .env
vim srcs/.env

# Apply changes
make down
make up
```

## Debugging and Testing

### Common Issues and Solutions

#### Issue: Containers won't start

```bash
# Check logs
docker logs <container-name>

# Check for port conflicts
sudo netstat -tulpn | grep 443

# Verify Docker service
sudo systemctl status docker

# Check available resources
docker system df
```

#### Issue: Permission denied errors

```bash
# Fix volume permissions
sudo chown -R www-data:www-data /home/shkaruna/data/wordpress
sudo chown -R mysql:mysql /home/shkaruna/data/mariadb

# Check file ownership
docker exec wordpress ls -la /var/www/html
docker exec mariadb ls -la /var/lib/mysql
```

#### Issue: Database connection failed

```bash
# Check MariaDB is running
docker exec mariadb mysqladmin ping

# Test connection from WordPress container
docker exec wordpress mysql -h mariadb -u wordpress_user -p

# Verify network connectivity
docker exec wordpress ping -c 3 mariadb

# Check environment variables
docker exec wordpress env | grep MYSQL
```

#### Issue: SSL certificate errors

```bash
# Regenerate certificate
docker exec nginx openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=shkaruna.42.fr"

# Restart NGINX
docker restart nginx
```

### Useful Commands for Debugging

```bash
# Show all environment variables in container
docker exec <container> env

# Check process list
docker exec <container> ps aux

# Check network interfaces
docker exec <container> ip addr

# Check open ports
docker exec <container> netstat -tulpn

# View filesystem
docker exec <container> ls -la /

# Check disk usage
docker exec <container> df -h

# View running services
docker exec <container> service --status-all

# Monitor resource usage
docker stats

# Inspect container details
docker inspect <container> | jq '.[0].Config'
docker inspect <container> | jq '.[0].NetworkSettings'
docker inspect <container> | jq '.[0].Mounts'
```

### Health Check Testing

```bash
# Check NGINX health
docker exec nginx pgrep nginx

# Check MariaDB health
docker exec mariadb mysqladmin ping -h localhost

# Check WordPress health (PHP-FPM)
docker exec wordpress pgrep php-fpm

# Check if WordPress is installed
docker exec wordpress test -f /var/www/html/wp-config.php && echo "Installed" || echo "Not installed"
```

### Performance Testing

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test NGINX performance
ab -n 1000 -c 10 -k https://shkaruna.42.fr/

# Monitor container resources
docker stats --no-stream

# Check database performance
docker exec mariadb mysqltuner
```

## Advanced Topics

### Docker Compose Override

For local development, create `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  wordpress:
    environment:
      - WP_DEBUG=true
    volumes:
      - ./custom-plugins:/var/www/html/wp-content/plugins/custom

  nginx:
    ports:
      - "80:80"  # Add HTTP for local testing
```

### Custom Scripts

Add custom initialization scripts to `requirements/*/tools/`:

```bash
# Example: Database backup script
cat > srcs/requirements/mariadb/tools/backup.sh << 'EOF'
#!/bin/bash
mysqldump -u root -p"$DB_ROOT_PASSWORD" --all-databases > /backup/all-databases.sql
EOF
```

### Security Hardening

For production:

1. Use Let's Encrypt for real SSL certificates
2. Implement rate limiting in NGINX
3. Use strong, unique passwords
4. Regular security updates
5. Implement firewall rules
6. Enable audit logging

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Build and Test

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build images
        run: make build
      - name: Run tests
        run: docker compose -f srcs/docker-compose.yml up -d && sleep 30 && curl -k https://localhost
```

## Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB Performance Tuning](https://mariadb.com/kb/en/server-system-variables/)
- [NGINX Optimization](https://www.nginx.com/blog/tuning-nginx/)
- [WordPress Debugging](https://wordpress.org/support/article/debugging-in-wordpress/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)

## Contributing

When contributing to this project:

1. Test all changes locally
2. Update documentation
3. Follow Docker best practices
4. Never commit secrets or credentials
5. Use meaningful commit messages
6. Test with `make fclean && make`

## Support

For issues or questions:
- Check the logs: `make logs`
- Review error messages carefully
- Consult the official documentation for each service
- Test components individually
- Verify network connectivity and health checks
