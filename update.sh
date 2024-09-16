#!/bin/bash

echo "Updating scorp CLI to the latest version..."

INSTALL_DIR="$HOME/.scorp"
BIN_DIR="$INSTALL_DIR/bin"

curl -o "$BIN_DIR/scorp" https://raw.githubusercontent.com/rxeal/scorp/main/bin/scorp
curl -o "$BIN_DIR/gitswitch.sh" https://raw.githubusercontent.com/rxeal/scorp/main/bin/gitswitch.sh
curl -o "$BIN_DIR/systemmain.sh" https://raw.githubusercontent.com/rxeal/scorp/main/bin/systemmain.sh

chmod +x "$BIN_DIR/scorp"
chmod +x "$BIN_DIR/gitswitch.sh"
chmod +x "$BIN_DIR/systemmain.sh"

echo "scorp CLI updated successfully!"
