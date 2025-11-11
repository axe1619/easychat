#!/bin/sh
set -e
cd "$(dirname "$0")/.."

cat << "EOF"
#      _____                   ____            _             _   
#     | ____|__ _ ___ _   _   / ___|___  _ __ | |_ __ _  ___| |_ 
#     |  _| / _` / __| | | | | |   / _ \| '_ \| __/ _` |/ __| __|
#     | |__| (_| \__ \ |_| | | |__| (_) | | | | || (_| | (__| |_ 
#     |_____\__,_|___/\__, |  \____\___/|_| |_|\__\__,_|\___|\__|
#                     |___/                                      
EOF

echo "🚀 Restarting project"

# Option mode proyect
echo "Select the execution mode:"
echo ""
echo "1) development"
echo "2) production"
echo ""
read -p "Enter 1 or 2: " MODE

case "$MODE" in
  1) 
     MODE="development"
     COMPOSE_FILE="docker-compose.development.yaml"
     COMPOSE_OPTIONS=""
     ;;
  2) 
     MODE="production"
     COMPOSE_FILE="docker-compose.production.yaml"
     COMPOSE_OPTIONS="--profile task"
     ;;
  *) 
     echo "❌ Invalid option. Exiting..."
     exit 1
     ;;
esac

#  start process
echo ""
echo "🚀 Ready to start the setup with the following configuration:"
echo ""
echo "-------------------------------------------------------------"
echo "Mode: $MODE"
echo "-------------------------------------------------------------"
echo ""

# verify docker install
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is not installed. Please install it before continuing."
  exit 1
fi

# verify docker compose install
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker Compose is not available. Install Docker Compose or Docker Desktop."
  exit 1
fi

# runnig containers
echo "🔧 Starting containers in the background..."

echo "🛑 Stopping containers..."
docker compose -f docker-compose.development.yaml down

echo "⚡ Up containers..."
docker compose -f "$COMPOSE_FILE" ${COMPOSE_OPTIONS:+$COMPOSE_OPTIONS} up -d

echo "🎉 Setup completed! Your Easy Contact app is ready."

