#!/usr/bin/env -S pkgx +mas bash -eo pipefail

cd "$(mktemp -d)"

if command -v brew >/dev/null 2>&1; then
  brew bundle dump
fi

mkdir dotfiles
find ~ -name .\* -maxdepth 1 -exec cp -R {} dotfiles

echo $PWD