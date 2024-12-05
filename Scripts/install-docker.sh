#!/bin/sh

if ! test -d /Applications/Docker.app; then
    /opt/homebrew/bin/brew install --cask Docker
else
    /opt/homebrew/bin/brew uninstall --cask Docker
fi
