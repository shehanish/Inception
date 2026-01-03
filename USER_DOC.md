# User Documentation - Inception Project

## Overview

The Inception project provides a fully functional WordPress website served over HTTPS. The infrastructure consists of three main services:

1. **Web Server (NGINX)**: Handles all incoming HTTPS traffic on port 443
2. **WordPress**: Content management system for creating and managing your website
3. **Database (MariaDB)**: Stores all WordPress data

## Starting and Stopping the Project

### Starting All Services

To start the complete infrastructure:

```bash
cd /path/to/Inception
make
```

Or individually:
```bash
make build    # Build Docker images
make up       # Start containers
```

The services will start in the correct order:
1. MariaDB (database)
2. WordPress (waits for database)
3. NGINX (waits for WordPress)

### Stopping All Services

To stop all running containers:

```bash
make down
```

This preserves all your data in the volumes.

### Restarting Services

To restart all services:

```bash
make restart
```

## Accessing the Website

### Main Website

1. Open your web browser
2. Navigate to: **https://shkaruna.42.fr**
3. Accept the self-signed certificate warning (click "Advanced" → "Proceed")
4. You should see your WordPress homepage

### WordPress Administration Panel

1. Navigate to: **https://shkaruna.42.fr/wp-admin**
2. Use the administrator credentials (see below)
3. You can now manage your website, create posts, install themes, etc.

## Credentials

All credentials are stored in the `secrets/` directory. The main credentials file is:

```
secrets/credentials.txt
```

### Default Credentials

**WordPress Administrator:**
- Username: `wpmaster`
- Password: `AdminPass789Secure!`
- Email: `wpmaster@shkaruna.42.fr`

**WordPress Regular User:**
- Username: `wpuser`
- Password: `UserPass321!`
- Email: `wpuser@shkaruna.42.fr`

**Database Access:**
- Database Name: `wordpress_db`
- Database User: `wordpress_user`
- Database Password: `WpUserPass456Secure!`
- Root Password: `RootPass123Secure!`

> ⚠️ **Important**: Change these passwords in a production environment!

## Checking Service Status

### View Running Containers

```bash
make ps
```

Or directly with Docker:
```bash
docker ps
```

You should see three containers running:
- `nginx`
- `wordpress`
- `mariadb`

### View Service Logs

To see logs from all services:
```bash
make logs
```

To see logs from a specific service:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Check Service Health

All services have health checks. To verify:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Healthy services will show "Up" with "(healthy)" status.

### Manual Health Checks

**NGINX:**
```bash
curl -k https://shkaruna.42.fr
```

**MariaDB:**
```bash
docker exec mariadb mysqladmin ping -h localhost
```

**WordPress:**
```bash
docker exec wordpress ls -la /var/www/html/wp-config.php
```

## Data Storage Locations

All persistent data is stored on the host machine:

```
/home/shkaruna/data/
├── mariadb/      # Database files
└── wordpress/    # WordPress files (themes, plugins, uploads)
```

### Backup Your Data

To backup your data:

```bash
# Backup database
sudo tar -czf wordpress-db-backup-$(date +%Y%m%d).tar.gz /home/shkaruna/data/mariadb

# Backup WordPress files
sudo tar -czf wordpress-files-backup-$(date +%Y%m%d).tar.gz /home/shkaruna/data/wordpress
```

### Restore from Backup

1. Stop the services: `make down`
2. Restore the data:
```bash
sudo rm -rf /home/shkaruna/data/mariadb/*
sudo rm -rf /home/shkaruna/data/wordpress/*
sudo tar -xzf wordpress-db-backup-YYYYMMDD.tar.gz -C /
sudo tar -xzf wordpress-files-backup-YYYYMMDD.tar.gz -C /
```
3. Start the services: `make up`

## Common Tasks

### Reset Everything

To completely reset the project (⚠️ deletes all data):

```bash
make fclean
make
```

### Update WordPress

WordPress updates can be done through the admin panel:
1. Go to https://shkaruna.42.fr/wp-admin
2. Navigate to Dashboard → Updates
3. Click "Update Now"

### Add a New User

Via admin panel:
1. Login to WordPress admin
2. Go to Users → Add New
3. Fill in the details and assign a role

Via command line:
```bash
docker exec wordpress wp user create newuser newuser@example.com \
    --role=editor --user_pass=SecurePassword123 --allow-root
```

### Install Plugins/Themes

Via admin panel:
1. Login to WordPress admin
2. Go to Plugins → Add New or Appearance → Themes → Add New
3. Search, install, and activate

Via WP-CLI:
```bash
# Install a plugin
docker exec wordpress wp plugin install plugin-name --activate --allow-root

# Install a theme
docker exec wordpress wp theme install theme-name --activate --allow-root
```

## Troubleshooting

### Website Not Loading

1. Check if containers are running:
```bash
make ps
```

2. Check NGINX logs:
```bash
docker logs nginx
```

3. Verify domain resolution:
```bash
ping shkaruna.42.fr
```

4. Check if `/etc/hosts` is configured:
```bash
cat /etc/hosts | grep shkaruna
```

### Database Connection Errors

1. Check MariaDB logs:
```bash
docker logs mariadb
```

2. Verify database is responding:
```bash
docker exec mariadb mysqladmin ping -h localhost
```

3. Check network connectivity:
```bash
docker exec wordpress ping -c 3 mariadb
```

### SSL Certificate Warnings

The project uses self-signed certificates. In a browser:
1. Click "Advanced" when you see the warning
2. Click "Proceed to shkaruna.42.fr (unsafe)"

For production, you would use Let's Encrypt certificates.

### Permission Issues

If you encounter permission errors:

```bash
# Fix volume permissions
sudo chown -R www-data:www-data /home/shkaruna/data/wordpress
sudo chown -R mysql:mysql /home/shkaruna/data/mariadb
```

### Containers Keep Restarting

Check the logs for the specific container:
```bash
docker logs <container-name>
```

Common causes:
- Configuration errors
- Missing environment variables
- Database not ready (should auto-resolve with health checks)

## Additional Resources

For database access and port configuration instructions, see [DATABASE_AND_PORT_GUIDE.md](DATABASE_AND_PORT_GUIDE.md).

For WordPress help:
- [WordPress Support](https://wordpress.org/support/)
- [WordPress Codex](https://codex.wordpress.org/)
