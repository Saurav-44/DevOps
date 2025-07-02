#!/bin/bash

# Backup home directory to a compressed tar file




BACKUP_DIR="$HOME/backup"

mkdir -p "$BACKUP_DIR"




FILE_NAME="backup_$(date +%F_%T).tar.gz"

tar -czvf "$BACKUP_DIR/$FILE_NAME" "$HOME"




echo "Backup saved to $BACKUP_DIR/$FILE_NAME"
