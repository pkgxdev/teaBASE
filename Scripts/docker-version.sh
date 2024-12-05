#!/bin/sh

export PATH=/usr/bin:/bin

defaults read "$(mdfind "kMDItemCFBundleIdentifier == 'com.docker.docker'" | head -n 1)/Contents/Info.plist" CFBundleShortVersionString
