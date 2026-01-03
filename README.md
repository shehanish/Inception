*This project has been created as part of the 42 curriculum by shkaruna.*

# Inception

## Description

Inception is a system administration project that involves setting up a complete web infrastructure using Docker containers. The project demonstrates proficiency in containerization, service orchestration, and secure deployment practices.

The infrastructure consists of:
- **NGINX**: A web server configured with TLS 1.2/1.3 as the sole entry point
- **WordPress**: A content management system with PHP-FPM
- **MariaDB**: A database server for WordPress data persistence

All services run in isolated Docker containers connected via a custom Docker network, with persistent data storage through Docker volumes.

## Instructions

### Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 1.29 or higher)
- Make
- Linux operating system (tested on Debian/Ubuntu)
- Root or sudo access for volume management

### Domain Configuration

Before running the project, add the following entry to your `/etc/hosts` file:

```bash
sudo echo "127.0.0.1 shkaruna.42.fr" >> /etc/hosts
```

### Building and Running

1. Clone the repository:
```bash
git clone <repository-url>
cd Inception
```

2. Build and start all services:
```bash
make
```

3. Access the website:
- Open your browser and navigate to: `https://shkaruna.42.fr`
- Accept the self-signed certificate warning

### Available Make Commands

- `make` or `make all`: Build images and start containers
- `make build`: Build all Docker images
- `make up`: Start all containers
- `make down`: Stop all containers
- `make restart`: Restart all containers
- `make clean`: Stop containers and remove images
- `make fclean`: Full cleanup including volumes
- `make re`: Rebuild everything from scratch
- `make logs`: View container logs
- `make ps`: Show running containers

### Stopping the Project

```bash
make down
```

## Resources

### Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/support/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [WP-CLI Documentation](https://wp-cli.org/)

### Articles and Tutorials
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Understanding Docker Networking](https://docs.docker.com/network/)
- [Docker Volumes vs Bind Mounts](https://docs.docker.com/storage/)

### AI Usage
AI (GitHub Copilot) was used for:
- **Documentation Writing**: Assistance in structuring and formatting README files
- **Shell Script Debugging**: Identifying issues in initialization scripts
- **Configuration Validation**: Verifying nginx and MariaDB configurations
- **Best Practices Review**: Ensuring Docker security and efficiency standards

AI was **not** used for:
- Writing the core Dockerfile logic
- Implementing the docker-compose configuration
- Designing the overall infrastructure architecture

## Project Description

### Docker in This Project

This project uses Docker to create isolated, reproducible environments for each service. Docker containers package applications with their dependencies, ensuring consistency across different environments.

**Sources Included:**
- `srcs/requirements/nginx/`: NGINX web server configuration and Dockerfile
- `srcs/requirements/mariadb/`: MariaDB database server configuration and Dockerfile
- `srcs/requirements/wordpress/`: WordPress + PHP-FPM configuration and Dockerfile
- `srcs/docker-compose.yml`: Service orchestration configuration
- `srcs/.env`: Environment variables (gitignored)
- `secrets/`: Sensitive credentials (gitignored)
- `Makefile`: Build automation

**Design Choices:**
- **Debian Bullseye Base**: Chosen for stability and extensive package support
- **Multi-stage Health Checks**: Ensures services start in correct order
- **Non-root Runtime**: Services run with minimal privileges where possible
- **Foreground Processes**: All services run as PID 1 without hacky background tricks

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker |
|--------|-----------------|---------|
| **Resource Usage** | High (full OS per VM) | Low (shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Isolation** | Complete hardware virtualization | Process-level isolation |
| **Portability** | Large image files | Small, layered images |
| **Performance** | Near-native with overhead | Near-native performance |
| **Use Case** | Complete OS isolation needed | Application-level isolation |

**Why Docker for this project:**
- Faster deployment and iteration
- Easier to version control and share
- More efficient resource utilization
- Simpler service orchestration with Docker Compose

### Secrets vs Environment Variables

| Aspect | Secrets | Environment Variables |
|--------|---------|----------------------|
| **Security** | Encrypted at rest, in transit | Stored in plain text |
| **Access** | Mounted as files, restricted access | Visible in process list |
| **Rotation** | Can be updated without rebuild | Requires rebuild or restart |
| **Visibility** | Not in logs or inspect output | Visible in docker inspect |
| **Best For** | Passwords, API keys, certificates | Configuration, non-sensitive data |

**Implementation in this project:**
- Database passwords: Docker secrets (mounted at `/run/secrets/`)
- Configuration values: Environment variables (.env file)
- All sensitive files are gitignored

### Docker Network vs Host Network

| Aspect | Docker Network (Bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Containers isolated, custom DNS | No isolation, direct host access |
| **Port Mapping** | Explicit port mapping required | Uses host ports directly |
| **Security** | Better isolation, controlled exposure | Less secure, all ports exposed |
| **Performance** | Slight overhead | No networking overhead |
| **DNS** | Built-in container name resolution | Must use localhost/IPs |

**Why Docker Network:**
- Better security through isolation
- Service discovery via container names (e.g., `mariadb:3306`)
- Flexible port mapping (internal 443 → external 443)
- Compliance with project requirements

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Docker-managed | User-managed |
| **Location** | Docker storage directory | Any host path |
| **Portability** | More portable | Less portable |
| **Performance** | Optimized by Docker | Direct filesystem access |
| **Backups** | Docker volume commands | Standard filesystem tools |

**Implementation in this project:**
- Using Docker volumes with bind mount options
- Volumes point to `/home/shkaruna/data/`
- Provides both Docker management and explicit host paths
- Meets project requirement for data in `/home/login/data`

**Advantages for this project:**
- Data persists after container removal
- Easy to backup and restore
- Explicit control over data location
- Shared access between host and containers

## Project Structure

```
Inception/
├── Makefile                          # Build automation
├── secrets/                          # Credentials (gitignored)
│   ├── .gitignore
│   ├── credentials.txt              # All credentials reference
│   ├── db_password.txt              # WordPress DB user password
│   └── db_root_password.txt         # MariaDB root password
└── srcs/
    ├── .env                          # Environment variables (gitignored)
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── .dockerignore
        │   ├── Dockerfile            # MariaDB container
        │   ├── conf/
        │   │   └── 50-server.cnf     # MariaDB configuration
        │   └── tools/
        │       └── init_db.sh        # Database initialization
        ├── nginx/
        │   ├── .dockerignore
        │   ├── Dockerfile            # NGINX container
        │   └── conf/
        │       └── nginx.conf        # NGINX + TLS configuration
        └── wordpress/
            ├── .dockerignore
            ├── Dockerfile            # WordPress + PHP-FPM
            └── tools/
                └── setup_wordpress.sh # WordPress installation
```

## Security Features

- TLS 1.2/1.3 only with strong cipher suites
- Self-signed SSL certificates (production would use Let's Encrypt)
- Docker secrets for password management
- No passwords in Dockerfiles or version control
- Non-privileged user execution where possible
- Minimal base images (Debian Bullseye)
- Network isolation between services
- Health checks for service dependencies

## License

This project is part of the 42 School curriculum.
