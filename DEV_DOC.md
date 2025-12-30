# Developer Documentation

This document provides technical information for developers working on the Inception project.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Architecture](#project-architecture)
3. [Setup and Installation](#setup-and-installation)
4. [Makefile Commands](#makefile-commands)
5. [Docker Compose Configuration](#docker-compose-configuration)
6. [Service Details](#service-details)
7. [Data Persistence](#data-persistence)
8. [Development Workflow](#development-workflow)
9. [Debugging](#debugging)

## Prerequisites

### Required Software

- **Docker Engine**: 20.10+
  ```bash
  docker --version
  ```

- **Docker Compose**: 1.29+
  ```bash
  docker-compose --version
  ```

### System Requirements

- Linux-based system (Debian/Ubuntu recommended)
- Minimum 2GB RAM
- Minimum 10GB free disk space
- Root/sudo privileges for:
  - Creating directories in `/home/shkaruna/data/`
  - Modifying `/etc/hosts`

### Installation

If Docker is not installed:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (optional, requires logout/login)
sudo usermod -aG docker $USER

# Install Docker Compose (if not included)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Project Architecture

### Directory Structure

```
/home/shkaruna/Inception/
├── Makefile                              # Build automation
├── README.md                             # Project overview
├── USER_DOC.md                          # End-user documentation
├── DEV_DOC.md                           # This file
├── secrets/                             # Sensitive data (not in git)
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                             # Environment variables
    ├── docker-compose.yml               # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile               # MariaDB image
        │   ├── conf/
        │   │   └── mariadb.cnf         # MariaDB configuration
        │   └── tools/
        │       └── init_db.sh          # Database initialization script
        ├── nginx/
        │   ├── Dockerfile               # NGINX image
        │   ├── conf/
        │   │   └── nginx.conf          # NGINX configuration
        │   └── tools/                   # (empty, reserved for scripts)
        └── wordpress/
            ├── Dockerfile               # WordPress/PHP-FPM image
            ├── conf/                    # (empty, reserved for configs)
            └── tools/
                └── setup_wordpress.sh   # WordPress setup script
```

### Service Architecture

```
┌─────────────────────────────────────────┐
│           Host Machine                   │
│  https://shkaruna.42.fr:443             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│         NGINX Container                   │
│  - Port 443 (HTTPS)                      │
│  - SSL/TLS Termination                   │
│  - Reverse Proxy                         │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│      WordPress Container                  │
│  - PHP-FPM on port 9000                  │
│  - WordPress Core                        │
│  - WP-CLI                                │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│       MariaDB Container                   │
│  - Port 3306 (internal)                  │
│  - MySQL Database                        │
│  - WordPress DB                          │
└──────────────────────────────────────────┘

All containers connected via: inception network (bridge)
```

## Setup and Installation

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url> /home/shkaruna/Inception
   cd /home/shkaruna/Inception
   ```

2. **Configure domain name**:
   ```bash
   sudo echo "127.0.0.1 shkaruna.42.fr" >> /etc/hosts
   ```

3. **Create environment file**:
   ```bash
   # Create .env in srcs/ directory
   nano srcs/.env
   ```
   See Environment Variables section below.

4. **Build and start**:
   ```bash
   make
   ```

### Environment Variables

The `srcs/.env` file must contain:

```bash
# Domain
DOMAIN_NAME=https://shkaruna.42.fr

# MariaDB Configuration
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=your_db_password

# WordPress Admin User
WP_ADMIN_USER=admin_user
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com

# WordPress Regular User
WP_USER=author_user
WP_USER_EMAIL=author@example.com
WP_USER_PASSWORD=author_password
```

**Security Note**: Never commit `.env` to git. It should be in `.gitignore`.

## Makefile Commands

### Available Targets

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build and start all services (default) |
| `make up` | Same as `make all` |
| `make start` | Start existing containers without rebuilding |
| `make stop` | Stop containers without removing them |
| `make restart` | Restart all containers |
| `make down` | Stop and remove containers (preserves volumes) |
| `make clean` | Stop containers and prune networks |
| `make fclean` | Complete cleanup: removes everything including data |
| `make re` | Rebuild from scratch (fclean + up) |
| `make logs` | View logs from all services |
| `make ps` | List running containers |

### Makefile Implementation Details

```makefile
# Default target
all: up

# Build and start
up:
	mkdir -p /home/shkaruna/data/mariadb
	mkdir -p /home/shkaruna/data/wordpress
	docker-compose -f srcs/docker-compose.yml up --build -d
```

The Makefile:
- Creates data directories automatically
- Uses `-f` flag to specify docker-compose.yml location
- Uses `-d` flag for detached mode
- Includes proper cleanup targets

## Docker Compose Configuration

### docker-compose.yml Overview

```yaml
version: '3.8'

services:
  mariadb:     # Database service
  wordpress:   # PHP-FPM + WordPress
  nginx:       # Web server + SSL

volumes:
  mariadb_data:   # Database persistence
  wordpress_data: # WordPress files persistence

networks:
  inception:      # Bridge network for inter-container communication
```

### Service Dependencies

- `wordpress` depends on `mariadb` (with healthcheck)
- `nginx` depends on `wordpress`
- Dependencies ensure proper startup order

### Network Configuration

All services communicate via the `inception` bridge network:
- Containers can reference each other by service name
- Internal DNS resolution provided by Docker
- Isolated from host network

### Volume Configuration

Bind mounts to host directories:
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/shkaruna/data/mariadb
```

## Service Details

### NGINX Service

**Dockerfile**: `srcs/requirements/nginx/Dockerfile`

**Base Image**: `debian:bullseye`

#SSL and TLS are security protocols that encrypt communication between browsers and servers.

#SSL (Secure Sockets Layer)
TLS (Transport Layer Security)
Browser → requests https://shkaruna.42.fr
NGINX → presents SSL certificate (self-signed)
Browser → encrypts data using TLS
NGINX → decrypts, forwards to WordPress
Response → encrypted back to browser


**Key Components**:
- NGINX web server
- OpenSSL for SSL certificate generation
- Self-signed certificate for `shkaruna.42.fr`

**Configuration**:
- Listens on port 443 (HTTPS only)
- SSL/TLS v1.2/v1.3 enabled
- Proxies PHP requests to WordPress container via FastCGI
- Serves static files from WordPress volume

**NGINX Config** (`conf/nginx.conf`):
- Server block for `shkaruna.42.fr`
- SSL certificate paths
- FastCGI pass to `wordpress:9000`
- Root directory: `/var/www/html`

**CMD**: `nginx -g "daemon off;"` (runs in foreground)

### WordPress Service

**Dockerfile**: `srcs/requirements/wordpress/Dockerfile`

**Base Image**: `debian:bullseye`

**Key Components**:
- PHP 7.4-FPM
- Required PHP extensions (mysqli, gd, curl, mbstring, xml, etc.)
- WP-CLI for WordPress management
- MariaDB client

**Configuration**:
- PHP-FPM listens on port 9000
- `clear_env = no` to allow environment variables

**Setup Script** (`tools/setup_wordpress.sh`):
1. Waits for MariaDB to be ready
2. Downloads WordPress core (if not present)
3. Creates `wp-config.php` with database credentials
4. Installs WordPress with admin user
5. Creates additional author user
6. Sets proper file permissions

**CMD**: `php-fpm7.4 -F` (runs in foreground)

### MariaDB Service

**Dockerfile**: `srcs/requirements/mariadb/Dockerfile`

**Base Image**: `debian:bullseye`

**Key Components**:
- MariaDB server and client
- Configuration for remote connections

**Configuration** (`conf/mariadb.cnf`):
- Bind to all interfaces (0.0.0.0)
- Port 3306
- Custom my.cnf settings

**Init Script** (`tools/init_db.sh`):
1. Initializes data directory (if first run)
2. Starts MySQL in bootstrap mode
3. Sets root password
4. Creates WordPress database
5. Creates WordPress user with remote access
6. Grants privileges
7. Starts MySQL in foreground

**Healthcheck**:
```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 10s
  timeout: 5s
  retries: 5
```

**CMD**: `mysqld` (runs in foreground)

## Data Persistence

### Volume Paths

Data persists in:
- **MariaDB**: `/home/shkaruna/data/mariadb`
- **WordPress**: `/home/shkaruna/data/wordpress`

### Container Mount Points

- **MariaDB**: `/var/lib/mysql` → `/home/shkaruna/data/mariadb`
- **WordPress**: `/var/www/html` → `/home/shkaruna/data/wordpress`
- **NGINX**: `/var/www/html` → `/home/shkaruna/data/wordpress` (read-only)

### Data Lifecycle

1. **First run**: Directories are created, databases initialized
2. **Subsequent runs**: Existing data is reused
3. **`make down`**: Containers removed, data preserved
4. **`make fclean`**: Everything deleted, including data

## Development Workflow

### Making Changes

#### Modifying NGINX Configuration

1. Edit `srcs/requirements/nginx/conf/nginx.conf`
2. Rebuild and restart:
   ```bash
   docker-compose -f srcs/docker-compose.yml up -d --build nginx
   ```

#### Modifying WordPress Setup

1. Edit `srcs/requirements/wordpress/tools/setup_wordpress.sh`
2. Rebuild (requires fresh start):
   ```bash
   make fclean
   make up
   ```

#### Modifying MariaDB Configuration

1. Edit `srcs/requirements/mariadb/conf/mariadb.cnf`
2. Rebuild and restart:
   ```bash
   docker-compose -f srcs/docker-compose.yml up -d --build mariadb
   ```

### Testing Changes

```bash
# Check container status
docker ps

# View logs
docker-compose -f srcs/docker-compose.yml logs -f

# Execute commands in container
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Test database connection
docker exec -it mariadb mysql -u wpuser -p wordpress
```

### Docker Commands Reference

```bash
# Build images
docker-compose -f srcs/docker-compose.yml build

# Start services
docker-compose -f srcs/docker-compose.yml up -d

# Stop services
docker-compose -f srcs/docker-compose.yml down

# View logs
docker-compose -f srcs/docker-compose.yml logs [service_name]

# Execute command in container
docker-compose -f srcs/docker-compose.yml exec service_name command

# List volumes
docker volume ls

# Inspect volume
docker volume inspect volume_name

# List networks
docker network ls

# Inspect network
docker network inspect network_name
```

## Debugging

### Container Logs

```bash
# All services
docker-compose -f srcs/docker-compose.yml logs

# Specific service
docker-compose -f srcs/docker-compose.yml logs nginx
docker-compose -f srcs/docker-compose.yml logs wordpress
docker-compose -f srcs/docker-compose.yml logs mariadb

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f
```

### Interactive Shell Access

```bash
# NGINX
docker exec -it nginx bash

# WordPress
docker exec -it wordpress bash

# MariaDB
docker exec -it mariadb bash
```

### Database Access

```bash
# Connect to MariaDB
docker exec -it mariadb mysql -u root -p

# Use WordPress database
USE wordpress;
SHOW TABLES;
```

### Network Troubleshooting

```bash
# Test connectivity between containers
docker exec -it wordpress ping mariadb
docker exec -it nginx ping wordpress

# Check network configuration
docker network inspect srcs_inception
```

### Common Issues

#### Build Fails

- Check Dockerfile syntax
- Verify base image is accessible
- Check internet connection

#### Container Crashes

- Check logs: `docker-compose -f srcs/docker-compose.yml logs service_name`
- Verify ENTRYPOINT script has execute permissions
- Ensure script doesn't exit prematurely

#### Database Connection Fails

- Verify MariaDB is running and healthy
- Check credentials in `.env` file
- Test connection: `docker exec -it mariadb mysql -u wpuser -p`

#### WordPress Setup Fails

- Check WordPress logs
- Verify MariaDB is accessible
- Ensure volumes have correct permissions

## Best Practices

### Security

- Never commit `.env` or credentials to git
- Use strong passwords
- Keep Docker images updated
- Regularly backup data

### Performance

- Use `.dockerignore` to exclude unnecessary files
- Minimize layers in Dockerfiles
- Use multi-stage builds if needed
- Clean up unused images and volumes

### Maintenance

- Regularly update base images
- Monitor disk space usage
- Review and rotate logs
- Test backup/restore procedures

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
