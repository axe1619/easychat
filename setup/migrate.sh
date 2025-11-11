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

echo "🚀 Migrate proyect"

# Option migrations and seeders
echo ""
read -p "Do you want to run migrations and seeders? (yes/no): " RUN_MIGRATIONS

# Convert to lowercase
RUN_MIGRATIONS=$(echo "$RUN_MIGRATIONS" | tr '[:upper:]' '[:lower:]')

case "$RUN_MIGRATIONS" in
  yes|y) RUN_MIGRATIONS=true ;;
  *) echo "❌ Migration canceled."; exit 1 ;;
esac

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

# migrations and seeders
echo "⚡ Running migrations and seeders in a temporary container"
docker compose -f docker-compose.development.yaml run --rm rails bundle exec rails db:chatwoot_prepare

echo "🎉 Setup completed! Your Easy Contact app is ready."

