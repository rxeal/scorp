#!/bin/bash

INSTALL_DIR="/home/scorpio/Packages/scorp"

mkdir -p "$INSTALL_DIR"

echo "Downloading scorp CLI..."
curl -L -o "$INSTALL_DIR/scorp" https://github.com/rxeal/scorp/raw/main/scorp
curl -L -o "$INSTALL_DIR/gitswitch.sh" https://github.com/rxeal/scorp/raw/main/gitswitch.sh
curl -L -o "$INSTALL_DIR/systemmain.sh" https://github.com/rxeal/scorp/raw/main/systemmain.sh

chmod +x "$INSTALL_DIR/scorp"
chmod +x "$INSTALL_DIR/gitswitch.sh"
chmod +x "$INSTALL_DIR/systemmain.sh"

if ! grep -q "$INSTALL_DIR" ~/.bashrc; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
    echo "Added $INSTALL_DIR to PATH in ~/.bashrc"
fi

source ~/.bashrc

echo "scorp CLI installed successfully!"
