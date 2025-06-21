#!/bin/bash
# cleanup_docker.sh

echo "Cleaning up Docker..."

# Remove stopped containers
docker container prune -f

# Remove dangling images
docker image prune -f

# Remove unused networks
docker network prune -f

# Remove unused volumes
docker volume prune -f

# Show disk usage
docker system df

echo "Cleanup completed!"