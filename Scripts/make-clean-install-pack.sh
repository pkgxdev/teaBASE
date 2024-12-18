#!/usr/bin/env -S pkgx +gum bash -eo pipefail

gum format "# Creating Clean Install Pack"

cd "$(mktemp -d -t teaBASE)"

gum format \
  "> Using temporary location \`$PWD\`" \
  "## Running \`brew bundle dump\`"

if command -v brew >/dev/null 2>&1; then
  brew bundle dump
fi

gum format "## dotfiles" "Adding whitelisted files"

mkdir home

for x in "$HOME"/.aws/* \
  "$HOME"/.bash_login \
  "$HOME"/.bashrc \
  "$HOME"/.bash_profile \
  "$HOME"/.config/btop/btop.conf \
  "$HOME"/.config/fish/config.fish \
  "$HOME"/.*/**/config.xml \
  "$HOME"/.*/**/config.yml \
  "$HOME"/.*/**/config.yaml \
  "$HOME"/.*/**/config.json \
  "$HOME"/.*/**/settings.json \
  "$HOME"/.gitconfig \
  "$HOME"/.profile \
  "$HOME"/.ssh/* \
  "$HOME"/.vimrc \
  "$HOME"/.zprofile \
  "$HOME"/.zshenv \
  "$HOME"/.zshrc
do
  if test -f "$x"; then
    STEM="${x#$HOME/}"
    STEM="$(dirname "$STEM")"
    if test "$STEM" = "."; then
      STEM="$(basename $x)"
    else
      mkdir -p "home/$STEM"
      STEM="$STEM/$(basename "$x")"
    fi

    gum format "\`~/$STEM\`"

    rsync -a "$x" "home/$STEM"
  fi
done

while gum confirm "Add additional files to pack?"; do
  file="$(gum file "$HOME" --all --file --directory)"
  gum format "k, adding: \`$file\`…"
  if test -f "$file"; then
    STEM="${file#$HOME/}"
    if test "$STEM" = "$file"; then
      echo "error: $file is not in $HOME" >&2
    else
      STEM="$(dirname "$STEM")"
      if test "$STEM" = "."; then
        STEM="$(basename $file)"
      else
        mkdir -p "home/$STEM"
        STEM="$STEM/$(basename "$file")"
      fi
      rsync --archive "$file" home/"$STEM"
    fi
  else
    rsync \
      --archive \
      --exclude=.DS_Store \
      "$file" \
      home
  fi
done
