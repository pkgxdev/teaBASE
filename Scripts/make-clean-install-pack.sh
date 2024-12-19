#!/usr/bin/env -S pkgx +gum bash>=4 -eo pipefail

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

# note, not space safe
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
    gum format "\`~/$x\`"
  fi
done

tar cf "$d/dotfiles.tar" "${dotfiles[@]}"

add_file() {
  gitdirs=()
  mapfile -d '' gitdirs < <(find "$1" -name .git -type d -print0)

  if [ "${#gitdirs[@]}" -eq 0 ]; then
    tar rf "$d/dotfiles.tar" "$1"
  else
    srcdirs=()
    for gitdir in "${gitdirs[@]}"; do
      srcdir="$(dirname "$gitdir")"
      srcdirs+=("$srcdir")

      tracked_files=()
      mapfile -d '' tracked_files < <(git -C "$srcdir" ls-files -z)
      tar rf "$d/dotfiles.tar" "${tracked_files[@]}" "$gitdir"
    done

    tar rf "$d/dotfiles.tar" "${srcdirs[@]}"
  fi
}

while gum confirm "Add additional files to pack?"
do
  file="$(gum file "$HOME" --all --file --directory)"

  STEM="${file#$HOME/}"

  if test "$STEM" = "$file"; then
    gum format "error: \`$file\` is not in \`$HOME\`" >&2
  else
    if test -f "$file"; then
      tar rf "$d/dotfiles.tar" "$STEM"
    else
      export d
      export -f add_file
      gum spin --show-output --title "Adding \`~/$STEM\`" -- bash -c "add_file \"$STEM\""
    fi

    gum format "\`~/$STEM\`"
  fi
done

gum spin --show-output --title "compressing tarball" -- gzip "$d/dotfiles.tar"

cd "$d"