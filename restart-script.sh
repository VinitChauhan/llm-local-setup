#!/bin/bash

# Docker Restart Script
# This script stops all containers, restarts Docker Desktop, and brings everything back up

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker Desktop is running
is_docker_running() {
    if pgrep -f "Docker Desktop" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for Docker to be ready
wait_for_docker() {
    print_status "Waiting for Docker to be ready..."
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker info > /dev/null 2>&1; then
            print_success "Docker is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "Docker failed to start within the expected time"
    return 1
}

# Function to check if containers are running
check_containers_running() {
    local running_containers=$(docker ps -q | wc -l | tr -d ' ')
    if [ "$running_containers" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Main script starts here
print_status "Starting Docker restart process..."

# Step 1: Stop all running containers
print_status "Stopping all running Docker containers..."
if check_containers_running; then
    docker stop $(docker ps -q) 2>/dev/null || true
    print_success "All containers stopped"
else
    print_warning "No running containers found"
fi

# Step 2: Remove all containers (optional - uncomment if you want to remove them)
# print_status "Removing all containers..."
# docker rm $(docker ps -aq) 2>/dev/null || true

# Step 3: Kill all Docker processes
print_status "Killing all Docker processes..."
pkill -f docker 2>/dev/null || true
pkill -f Docker 2>/dev/null || true

# Step 4: Quit Docker Desktop and restart it
print_status "Quitting Docker Desktop..."
osascript -e 'quit app "Docker Desktop"' 2>/dev/null || true

print_status "Waiting for Docker Desktop to quit completely..."
sleep 5

# Wait for Docker Desktop to fully quit
while is_docker_running; do
    print_status "Still waiting for Docker Desktop to quit..."
    sleep 2
done

print_success "Docker Desktop has quit"

# Step 5: Start Docker Desktop
print_status "Starting Docker Desktop..."
open -a "Docker Desktop"

# Step 6: Wait for Docker to be ready
if ! wait_for_docker; then
    print_error "Failed to start Docker. Please check Docker Desktop manually."
    exit 1
fi

# Step 7: Navigate to the project directory and start services
# print_status "Navigating to AI-Workspace/models/llm-local-setup..."
# if [ ! -d "AI-Workspace/models/llm-local-setup" ]; then
#     print_error "Directory AI-Workspace/models/llm-local-setup not found!"
#     print_error "Please run this script from the correct directory or update the path."
#     exit 1
# fi

# cd AI-Workspace/models/llm-local-setup

# Step 8: Start docker-compose services
print_status "Starting docker-compose services..."
docker-compose up --build -d

# Step 9: Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Step 10: Pull required models
print_status "Pulling llama3.2:3b-instruct-q4_0 model..."
if docker exec -it ollama ollama pull llama3.2:3b-instruct-q4_0; then
    print_success "llama3.2:3b-instruct-q4_0 model pulled successfully"
else
    print_error "Failed to pull llama3.2:3b-instruct-q4_0 model"
fi

print_status "Pulling nomic-embed-text model..."
if docker exec -it ollama ollama pull nomic-embed-text; then
    print_success "nomic-embed-text model pulled successfully"
else
    print_error "Failed to pull nomic-embed-text model"
fi

# Step 11: Show final status
print_status "Checking final container status..."
docker ps

print_success "Docker restart process completed successfully!"
print_status "All services should now be running normally."

# Optional: Show docker-compose logs
read -p "Do you want to see the docker-compose logs? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose logs --tail=50
fi