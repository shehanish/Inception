# Inception

*This project has been created as part of the 42 curriculum by shkaruna*

## Description

Inception is a system administration project that focuses on virtualizing several Docker images by creating them in a personal virtual machine. The project involves setting up a small infrastructure composed of different services following specific rules:

- NGINX with TLSv1.2 or TLSv1.3
- WordPress with php-fpm (without nginx)
- MariaDB (without nginx)
- Docker volumes for WordPress database and website files
- A docker-network to establish connections between containers

Each service runs in a dedicated container built from either Alpine or Debian (penultimate stable version). The containers are managed using docker-compose, and the entire infrastructure is configured to restart automatically in case of a crash.

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- A virtual machine or Linux system
- Root or sudo access for directory creation

### Setup

1. Clone this repository
2. Ensure the required directories exist (they will be created automatically by the Makefile)
3. Configure your `/etc/hosts` file to map `shkaruna.42.fr` to `127.0.0.1`
4. Run `make` to build and start all services

### Usage

- **Build and start**: `make` or `make up`
- **Stop services**: `make stop`
- **Start services**: `make start`
- **Restart services**: `make restart`
- **Stop and remove containers**: `make down`
- **Complete cleanup**: `make fclean`

### Accessing the Services

- WordPress site: https://shkaruna.42.fr
- WordPress admin: https://shkaruna.42.fr/wp-admin

## Resources

### Documentation

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/support/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

### AI Usage

AI tools (GitHub Copilot, ChatGPT) were used in this project for:

- **Configuration file syntax**: Assistance with docker-compose.yml syntax and NGINX configuration structure
- **Bash scripting**: Help with shell script logic for database initialization and WordPress setup
- **Troubleshooting**: Debugging Docker networking issues and container connectivity
- **Documentation**: Structuring and formatting documentation files

All code was reviewed, understood, and adapted to meet project requirements. AI was used as a learning aid and productivity tool, not as a replacement for understanding the underlying concepts.

## Project Structure

```
.
├── Makefile                    # Build automation
├── README.md                   # This file
├── USER_DOC.md                # User documentation
├── DEV_DOC.md                 # Developer documentation
├── secrets/                    # Credentials (not in git)
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                    # Environment variables
    ├── docker-compose.yml      # Service orchestration
    └── requirements/
        ├── mariadb/           # MariaDB container
        ├── nginx/             # NGINX container
        └── wordpress/         # WordPress container
```

## Author

**shkaruna** - 42 Student
