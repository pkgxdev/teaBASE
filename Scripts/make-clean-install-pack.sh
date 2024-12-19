#!/usr/bin/env -S pkgx +gum bash>=4 -eo pipefail

gum format \
  "# teaBASE clean install pack" \
  "clean installing your machine regularly is great developer hygiene." \
  "## firstly we need an encryption password"

tmpdir="$(mktemp -d -t teaBASE)"

hdiutil create \
    -size 20g \
    -volname "teaBASE Clean Install" \
    -encryption AES-256 \
    -stdinpass \
    -attach \
    -type SPARSEBUNDLE \
    "$tmpdir"/tmp.sparsebundle

cd "/Volumes/teaBASE Clean Install"

if command -v brew >/dev/null 2>&1; then
  gum format "## Running \`brew bundle dump\`"
  brew bundle dump
fi

echo #spacer
gum format "## dotfiles" "adding whitelisted files"

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
  .zshrc \
  "${XDG_CONFIG_HOME:-$HOME/.config}"/pkgx/bpb.toml \
do
  if test -f "$x"; then
    dotfiles+=("$x")
    gum format "\`~/$x\`"
  fi
done

tar cf "$d/dotfiles.tar" "${dotfiles[@]}"

add_file() {
  STEM="$1"

  gitdirs=()
  mapfile -d '' gitdirs < <(find "$STEM" -name .git -type d -print0)

  if [ "${#gitdirs[@]}" -eq 0 ]; then
    tar rf "$d/dotfiles.tar" "$STEM"
  else
    srcdirs=()
    for gitdir in "${gitdirs[@]}"; do
      srcdir="$(dirname "$gitdir")"
      srcdirs+=("$srcdir")

      # get a list of all files except those that are ignored
      # rationale: `node_modules` etc. are gigabytes of caching
      tracked_files=()
      mapfile -d '' tracked_files < <(git -C "$srcdir" ls-files --others --exclude-standard -z)

      tracked_with_stem=()
      for file in "${tracked_files[@]}"; do
        if test -e "$file"; then
          # ^^ file may be in the tracking index, but deleted
          tracked_with_stem+=("$srcdir/$file")
        fi
      done

      tar rf "$d/dotfiles.tar" "${tracked_with_stem[@]}" "$gitdir"
    done

    excludes=()
    for srcdir in "${srcdirs[@]}"; do
      excludes+=("--exclude=$srcdir")
    done

    tar rf "$d/dotfiles.tar" "${excludes[@]}" "$STEM"
  fi
}

gum format \
  "# add additional files" \
  "for example, you may like to add your \`~/srcs\` directory." \
  "> we exclude files according to any discovered \`.gitignore\` files." \
  "> add dotfiles to our whitelist: https://github.com/teaxyz/teaBASE/issues/new"

while gum confirm "add additional files to pack?"
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
      gum spin --show-output --title "adding \`~/$STEM\`" -- bash -c "add_file \"$STEM\""
    fi
  fi
done

cd "$d"

if test -x /usr/local/bin/bpb; then
  BPB="$(security find-generic-password -s xyz.tea.BASE.bpb -w)"
  if test "$BPB"; then
    BPB=".bin/bpb import $BPB"
  fi
fi

#TODO pkg brew into pkgx
cat <<EoSH >restore.command
#!/bin/bash

set -eo pipefail

cd "\$(dirname "\$0")"

set -a
eval "\$(.bin/pkgx +gum +mas)"
set +a

if gum confirm "extract dotfiles to \\\`\$HOME\\\`?"; then
  tar xf dotfiles.tar --cd "\$HOME"
fi

if test -f Brewfile; then
  if ! gum confirm 'install Homebrew; restore \`Brewfile\`?'; then
    exit 2
  fi

  /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  PATH="/opt/homebrew/bin:\$PATH" brew bundle install

  $BPB
fi
EoSH

chmod +x restore.command

mkdir .bin
cp "$(which pkgx)" .bin
if test "$BPB"; then
  cp "$(which bpb)" .bin
  unset BPB
fi

cd ~/Downloads  # or it won’t detach
hdiutil detach "$d"

hdiutil convert $tmpdir/tmp.sparsebundle -format UDZO -o Clean\ Install\ Pack.dmg

rm -rf "$tmpdir"
