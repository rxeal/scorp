#!/bin/bash

echo "Installing scorp CLI..."

INSTALL_DIR="$HOME/.scorp"
BIN_DIR="$INSTALL_DIR/bin"

mkdir -p "$BIN_DIR"

curl -o "$BIN_DIR/scorp" https://raw.githubusercontent.com/rxeal/scorp/main/bin/scorp
curl -o "$BIN_DIR/gitswitch.sh" https://raw.githubusercontent.com/rxeal/scorp/main/bin/gitswitch.sh
curl -o "$BIN_DIR/systemmain.sh" https://raw.githubusercontent.com/rxeal/scorp/main/bin/systemmain.sh

chmod +x "$BIN_DIR/scorp"
chmod +x "$BIN_DIR/gitswitch.sh"
chmod +x "$BIN_DIR/systemmain.sh"

if ! grep -q "$BIN_DIR" <<< "$PATH"; then
    echo 'export PATH="$PATH:$BIN_DIR"' >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
fi

echo "scorp CLI installed successfully!"
