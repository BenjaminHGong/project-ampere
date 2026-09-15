#!/bin/bash
# update_factorio.sh - Backup, update Factorio, then run server using run.sh

# ----------------------
# Configuration
# ----------------------
FACTORIO_DIR="/home/ubuntu/factorio-server/factorio"   # factorio folder
BACKUP_DIR="/home/ubuntu/factorio-server/backups/factorio_$(date +%Y%m%d_%H%M%S)"
FACTORIO_URL="https://www.factorio.com/get-download/latest/headless/linux64"
RUN_SCRIPT="/home/ubuntu/factorio-server/run.sh"

mkdir -p "$BACKUP_DIR"

# ----------------------
# Stop server if running
# ----------------------
if screen -list | grep -q "\.factorio"; then
    echo "Stopping running Factorio server..."
    screen -S factorio -X quit
    sleep 2
fi

# ----------------------
# Backup saves, config, mods, server-settings.json
# ----------------------
echo "Backing up saves, config, mods, and server-settings.json..."
cp -r "$FACTORIO_DIR/saves" "$BACKUP_DIR/"
cp -r "$FACTORIO_DIR/mods" "$BACKUP_DIR/"
cp "$FACTORIO_DIR/data/server-settings.json" "$BACKUP_DIR/"

# ----------------------
# Download and extract latest Factorio
# ----------------------
echo "Downloading latest Factorio headless x64..."
cd "$FACTORIO_DIR"
wget -q --show-progress "$FACTORIO_URL" -O factorio_headless_x64.tar.xz

echo "Extracting Factorio..."
tar -xf factorio_headless_x64.tar.xz --strip-components=1
rm factorio_headless_x64.tar.xz

# ----------------------
# Restore server-settings.json, mods, config, and saves
# ----------------------
echo "Restoring all critical files..."
cp -r "$BACKUP_DIR/saves"/* "$FACTORIO_DIR/saves/"
cp -r "$BACKUP_DIR/mods"/* "$FACTORIO_DIR/mods/"
cp "$BACKUP_DIR/server-settings.json" "$FACTORIO_DIR/data/server-settings.json"

# ----------------------
# Start server using run.sh
# ----------------------
echo "Starting Factorio server using run.sh..."
bash "$RUN_SCRIPT"

echo "Update and restart completed!"
