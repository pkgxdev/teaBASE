#!/bin/sh

if ! test -d /Applications/Docker.app; then
    brew install --cask Docker
else
    brew uninstall --cask Docker
fi
