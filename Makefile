.PHONY: all build up down restart clean fclean re logs ps

# Default target
all: build up

# Build all Docker images
build:
	@echo "Building Docker images..."
	@mkdir -p /home/shkaruna/data/wordpress
	@mkdir -p /home/shkaruna/data/mariadb
	docker-compose -f srcs/docker-compose.yml build

# Start all containers
up:
	@echo "Starting containers..."
	@mkdir -p /home/shkaruna/data/wordpress
	@mkdir -p /home/shkaruna/data/mariadb
	@sudo chown -R $(shell id -u):$(shell id -g) /home/shkaruna/data/wordpress
	@sudo chown -R $(shell id -u):$(shell id -g) /home/shkaruna/data/mariadb
	docker-compose -f srcs/docker-compose.yml up -d

# Stop all containers
down:
	@echo "Stopping containers..."
	docker-compose -f srcs/docker-compose.yml down

# Restart all containers
restart:
	@echo "Restarting containers..."
	docker-compose -f srcs/docker-compose.yml restart

# Stop containers and remove images
clean: down
	@echo "Removing Docker images..."
	docker-compose -f srcs/docker-compose.yml down --rmi all

# Full cleanup including volumes
fclean: down
	@echo "Full cleanup..."
	docker-compose -f srcs/docker-compose.yml down --rmi all --volumes
	@sudo rm -rf /home/shkaruna/data/wordpress/* /home/shkaruna/data/wordpress/.*  2>/dev/null || true
	@sudo rm -rf /home/shkaruna/data/mariadb/* /home/shkaruna/data/mariadb/.* 2>/dev/null || true
	docker system prune -af --volumes

# Rebuild everything from scratch
re: fclean all

# Show logs
logs:
	docker-compose -f srcs/docker-compose.yml logs -f

# Show running containers
ps:
	docker-compose -f srcs/docker-compose.yml ps
