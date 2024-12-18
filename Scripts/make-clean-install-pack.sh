#!/usr/bin/env -S pkgx +gum bash -eo pipefail

gum format "# Creating Clean Install Pack"

cd "$(mktemp -d -t teaBASE.XXXXXX)"

gum format \
  "> Using temporary location \`$PWD\`" \
  "## Running \`brew bundle dump\`"

if command -v brew >/dev/null 2>&1; then
  brew bundle dump
fi

gum format "## dotfiles" "Adding whitelisted files"

mkdir dotfiles

for x in "$HOME"/.aws/config/* \
  "$HOME"/.bash_login \
  "$HOME"/.bashrc \
  "$HOME"/.bash_profile \
  "$HOME"/.config/btop/btop.conf \
  "$HOME"/.config/fish/config.fish \
  "$HOME"/.config/**/config.xml \
  "$HOME"/.config/**/config.yml \
  "$HOME"/.config/**/config.json \
  "$HOME"/.config/**/settings.json \
  "$HOME"/.gitconfig \
  "$HOME"/.profile \
  "$HOME"/.ssh/* \
  "$HOME"/.vimrc \
  "$HOME"/.zprofile \
  "$HOME"/.zshenv \
  "$HOME"/.zshrc
do
  if test -f "$x"; then
    gum format "\`$x\`"

    STEM="${x#$HOME/}"
    STEM="$(dirname "$STEM")"
    NAME="$(basename "$x")"
    mkdir -p "dotfiles/$STEM"
    rsync -a "$x" "dotfiles/$STEM/$NAME"
  fi
done

while gum confirm "Add additional files to pack?"; do
  file="$(gum file "$HOME" --all --file --directory)"
  gum format "\`$file\`"
  if test -f "$file"; then
    gum format "\`$file\`"
    cp "$file" dotfiles
  else
    # --ignore-errors ∵ don’t complain about fifos/sockets etc.
    rsync \
      --progress \
      --archive \
      --ignore-errors \
      --exclude=.DS_Store \
      "$file" \
      dotfiles
  fi
done
