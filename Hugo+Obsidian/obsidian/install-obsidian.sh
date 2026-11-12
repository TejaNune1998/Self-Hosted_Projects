#!/bin/bash
set -e

echo "Loading .env..."
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "!!! ERROR: .env file not found!"
  exit 1
fi

echo "Starting CouchDB + Obsidian containers..."
docker-compose up -d

echo "Waiting for CouchDB to start..."
sleep 10

echo "Configuring CouchDB (single-node, CORS, etc.)..."

export hostname="http://IP-Address:5984"
export username="${COUCHDB_USER}"
export password="${COUCHDB_PASSWORD}"
export database="${COUCHDB_DB_NAME}"

curl -s https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/couchdb/couchdb-init.sh | bash

echo "CouchDB initialization complete."

export hostname="https://obsidian-sync.yourdomain.com"

echo "Waiting a bit for TLS / DNS..."
sleep 10

if ! command -v deno >/dev/null 2>&1; then
  echo "Installing Deno..."
  curl -fsSL https://deno.land/install.sh | sh
  export PATH="$HOME/.deno/bin:$PATH"
fi

deno run -A https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/flyio/generate_setupuri.ts \
  > /opt/docker_files/LabLog/obsidian/setupuri.txt

echo "Setup URI and passphrase:"
cat /opt/docker_files/LabLog/obsidian/setupuri.txt

read -p 'Observe CouchDB logs? (y/n) ' input
if [[ "$input" =~ ^[Yy]$ ]]; then
  docker logs -f obsidian-livesync
fi

echo "Done."
exit 0
