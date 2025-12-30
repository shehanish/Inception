.PHONY: all up down start stop restart clean fclean re logs ps

# Default target
all: up

# Create necessary directories and start containers
up:
	@echo "Creating data directories..."
	@mkdir -p /home/shkaruna/data/mariadb
	@mkdir -p /home/shkaruna/data/wordpress
	@echo "Building and starting containers..."
	@docker-compose -f srcs/docker-compose.yml up --build -d
	@echo "Containers are up and running!"
	@echo "Access your site at: https://shkaruna.42.fr"

# Start existing containers without rebuilding
start:
	@echo "Starting containers..."
	@docker-compose -f srcs/docker-compose.yml start

# Stop containers without removing them
stop:
	@echo "Stopping containers..."
	@docker-compose -f srcs/docker-compose.yml stop

# Restart containers
restart:
	@echo "Restarting containers..."
	@docker-compose -f srcs/docker-compose.yml restart

# Stop and remove containers
down:
	@echo "Stopping and removing containers..."
	@docker-compose -f srcs/docker-compose.yml down

# Stop containers, remove networks
clean: down
	@echo "Cleaning up networks..."
	@docker network prune -f

# Complete cleanup: remove containers, networks, volumes, and data
fclean:
	@echo "Complete cleanup..."
	@docker-compose -f srcs/docker-compose.yml down -v
	@docker system prune -a -f
	@echo "Removing data directories..."
	@sudo rm -rf /home/shkaruna/data/mariadb
	@sudo rm -rf /home/shkaruna/data/wordpress
	@echo "Cleanup complete!"

# Rebuild everything from scratch
re: fclean all

# Show container logs
logs:
	@docker-compose -f srcs/docker-compose.yml logs -f

# Show running containers
ps:
	@docker-compose -f srcs/docker-compose.yml ps

