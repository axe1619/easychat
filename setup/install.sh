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

echo "🚀 Starting the project installation"

#  start process
echo ""
echo "🚀 Configuration:"
echo ""
echo "-------------------------------------------------------------"
echo "Mode: development"
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

echo "🔧 Starting containers in the background..."

echo "📦 Downloading images..."
docker compose -f docker-compose.development.yaml pull

echo "⚡ Running containers..."    
docker compose -f docker-compose.development.yaml up -d

echo "🎉 Setup completed! Your Easy Contact app is ready."

