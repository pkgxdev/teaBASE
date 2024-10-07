#!/usr/bin/env -S pkgx +gh +gum +bpb bash

set -e

# Check for required scopes and perform actions
scopes=$(gh api user -H "Authorization: token $(gh auth token)" -i | grep -i 'X-OAuth-Scopes:')

if [[ $scopes == *"admin:public_key"* && $scopes == *"write:gpg_key"* ]]; then
  true
else
  gum format \
    "firstly, we need to add the \`write:gpg_key\` and " \
    "\`admin:public_key\` scopes to your \`gh\` authentication" \
    "" \
    "> alternatively upload your keys manually:" \
    "> https://github.com/settings/keys"

  gh auth login -h github.com -p https -s write:gpg_key -s admin:public_key -w
fi

if test -f ~/.ssh/id_rsa; then
  gum format \
    "uploading your ssh public key…"

  gh ssh-key add ~/.ssh/id_rsa.pub --title "Added by teaBASE"
fi

if test -f ~/.bpb_keys.toml; then
  gum format \
    "uploading your gpg public key…"

  # NOTE this fails if the key already exists which sucks
  bpb print | gh gpg-key add --title "Added by teaBASE"
fi
