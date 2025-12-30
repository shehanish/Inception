# User Documentation

This document provides instructions for end users and administrators on how to use and manage the Inception infrastructure.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Starting and Stopping the Stack](#starting-and-stopping-the-stack)
3. [Accessing the Website](#accessing-the-website)
4. [Managing Credentials](#managing-credentials)
5. [Basic Checks and Troubleshooting](#basic-checks-and-troubleshooting)

## Getting Started

### System Requirements

- Docker Engine 20.10 or higher
- Docker Compose 1.29 or higher
- At least 2GB of free disk space
- Root or sudo access

### Initial Setup

Before starting the services for the first time:

1. **Add domain to hosts file**:
   ```bash
   sudo echo "127.0.0.1 shkaruna.42.fr" >> /etc/hosts
   ```

2. **Ensure directories exist**:
   The Makefile will automatically create the required directories at `/home/shkaruna/data/mariadb` and `/home/shkaruna/data/wordpress`.

## Starting and Stopping the Stack

### Start All Services

To build and start all services:
```bash
make
```
or
```bash
make up
```

This command will:
- Create necessary data directories
- Build Docker images for all services
- Start all containers in detached mode
- Display the URL to access your site

**Expected output**: "Containers are up and running!"

### Stop Services

To stop all running containers without removing them:
```bash
make stop
```

Use this when you want to temporarily stop services but keep all data intact.

### Start Existing Services

To start previously stopped containers:
```bash
make start
```

### Restart Services

To restart all services:
```bash
make restart
```

Useful after configuration changes or when services become unresponsive.

### Stop and Remove Containers

To stop and remove all containers:
```bash
make down
```

This removes containers but preserves volumes and data.

### Complete Cleanup

To perform a complete cleanup (⚠️ **Warning**: This removes all data):
```bash
make fclean
```

This will:
- Stop and remove all containers
- Remove all volumes
- Remove all Docker images
- Delete data directories
- Prune the Docker system

**Use with caution**: All WordPress content and database data will be lost.

## Accessing the Website

### WordPress Website

Once the stack is running, access the website at:
```
https://shkaruna.42.fr
```

**Note**: Your browser will show a security warning because the SSL certificate is self-signed. This is expected. Click "Advanced" and "Proceed to site" to continue.

### WordPress Admin Panel

To access the WordPress administration dashboard:

1. Navigate to: `https://shkaruna.42.fr/wp-admin`
2. Log in with the administrator credentials (see Managing Credentials section)

### Available Users

Two WordPress users are created by default:
- **Administrator**: Full access to all WordPress features
- **Author**: Can create and publish posts

## Managing Credentials

### Viewing Credentials

Credentials are stored in the `secrets/` directory:

```bash
# Database root password
cat secrets/db_root_password.txt

# Database user password
cat secrets/db_password.txt

# WordPress credentials
cat secrets/credentials.txt
```

### Environment Variables

The `.env` file in the `srcs/` directory contains all configuration:

```bash
cat srcs/.env
```

### Changing Passwords

To change passwords:

1. **Stop the services**:
   ```bash
   make down
   ```

2. **Edit the .env file**:
   ```bash
   nano srcs/.env
   ```

3. **Perform a clean rebuild**:
   ```bash
   make fclean
   make up
   ```

**Important**: Changing passwords after initial setup requires a complete rebuild.

## Basic Checks and Troubleshooting

### Check Service Status

To view running containers:
```bash
docker ps
```

You should see three containers running:
- `nginx`
- `wordpress`
- `mariadb`

### Check Logs

To view logs for all services:
```bash
docker-compose -f srcs/docker-compose.yml logs
```

To view logs for a specific service:
```bash
docker-compose -f srcs/docker-compose.yml logs nginx
docker-compose -f srcs/docker-compose.yml logs wordpress
docker-compose -f srcs/docker-compose.yml logs mariadb
```

To follow logs in real-time:
```bash
docker-compose -f srcs/docker-compose.yml logs -f
```

### Check Volumes

To verify that data volumes exist:
```bash
docker volume ls
```

To inspect a volume:
```bash
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

### Check Network

To verify the Docker network:
```bash
docker network ls
```

You should see a network named `srcs_inception`.

### Common Issues

#### Cannot access https://shkaruna.42.fr

**Solution**:
1. Check that services are running: `docker ps`
2. Verify `/etc/hosts` contains: `127.0.0.1 shkaruna.42.fr`
3. Check NGINX logs: `docker-compose -f srcs/docker-compose.yml logs nginx`

#### WordPress shows installation page

**Solution**:
- WordPress setup may have failed. Check logs: `docker-compose -f srcs/docker-compose.yml logs wordpress`
- Rebuild: `make fclean && make up`

#### Database connection error

**Solution**:
1. Check MariaDB is running: `docker ps | grep mariadb`
2. Check MariaDB logs: `docker-compose -f srcs/docker-compose.yml logs mariadb`
3. Verify credentials in `.env` file match

#### Port 443 already in use

**Solution**:
- Another service is using port 443
- Stop the conflicting service or change the port in `docker-compose.yml`

### Verifying Installation

After starting the services, verify everything works:

1. **Check all containers are running**:
   ```bash
   docker ps
   ```
   All three containers should have status "Up".

2. **Access the website**:
   Open https://shkaruna.42.fr in your browser.

3. **Log in to admin panel**:
   Navigate to https://shkaruna.42.fr/wp-admin and log in.

4. **Test WordPress functionality**:
   - Create a new post
   - Add a comment
   - Edit a page

### Data Persistence

Data is stored in two locations:

- **MariaDB data**: `/home/shkaruna/data/mariadb`
- **WordPress files**: `/home/shkaruna/data/wordpress`

This data persists even after running `make down`. To completely remove all data, use `make fclean`.

### Backup Recommendations

To backup your data:

```bash
# Backup WordPress files
sudo tar -czf wordpress-backup.tar.gz /home/shkaruna/data/wordpress

# Backup MariaDB data
sudo tar -czf mariadb-backup.tar.gz /home/shkaruna/data/mariadb
```

## Support

For technical issues or questions:
- Check the logs first
- Review the DEV_DOC.md for technical details
- Consult Docker and WordPress official documentation
