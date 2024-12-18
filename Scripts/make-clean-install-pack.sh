#!/usr/bin/env -S pkgx +gum bash -eo pipefail

gum format "# Creating Clean Install Pack"

cd "$(mktemp -d -t teaBASE)"

gum format \
  "> Using temporary location \`$PWD\`" \
  "## Running \`brew bundle dump\`"

if command -v brew >/dev/null 2>&1; then
  brew bundle dump
fi

echo #spacer
gum format "## dotfiles" "Adding whitelisted files"

d="$PWD"
cd "$HOME"

dotfiles=()

for x in .aws/* \
  .bash_login \
  .bashrc \
  .bash_profile \
  .config/btop/btop.conf \
  .config/fish/config.fish \
  .*/config.xml \
  .*/**/config.xml \
  .*/config.yml \
  .*/**/config.yml \
  .*/config.yaml \
  .*/**/config.yaml \
  .*/config.json \
  .*/**/config.json \
  .*/settings.json \
  .*/**/settings.json \
  .gitconfig \
  .profile \
  .ssh/* \
  .vimrc \
  .zprofile \
  .zshenv \
  .zshrc
do
  if test -f "$x"; then
    dotfiles+=("$x")
    gum format "\`~/$STEM\`"
  fi
done

while gum confirm "Add additional files to pack?"; do

  file="$(gum file "$HOME" --all --file --directory)"

  STEM="${file#$HOME/}"
  if test "$STEM" = "$file"; then
    gum format "error: \`$file\` is not in \`$HOME\`" >&2
  else
    STEM="$(dirname "$STEM")"
    if test "$STEM" = "."; then
      STEM="$(basename "$file")"
    else
      STEM="$STEM/$(basename "$file")"
    fi
    gum format "\`~/$STEM\`"
  fi
done

tar cf "$d/dotfiles.tar" "${dotfiles[@]}"
