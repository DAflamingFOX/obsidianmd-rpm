#!/bin/bash
set -e

# Fetch latest version of Obsidian from the official releases repository
LATEST_VERSION=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep '"tag_name":' | cut -d '"' -f 4 | sed 's/v//')

echo "Found latest Obsidian version: $LATEST_VERSION"
echo "VERSION=$LATEST_VERSION" >> $GITHUB_ENV

# Download the tar.gz for the latest version
wget "https://github.com/obsidianmd/obsidian-releases/releases/download/v${LATEST_VERSION}/obsidian-${LATEST_VERSION}.tar.gz"