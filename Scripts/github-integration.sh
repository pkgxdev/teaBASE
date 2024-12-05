#!/bin/bash

PATH="$(cd "$(dirname "$0")"/../MacOS && pwd)${PATH:+:$PATH}"

set -a
# gh command uses git underneath for auth for some reason
eval "$(pkgx +gh +gum +git)"
set +a

set -eo pipefail

if gh auth status 2>/dev/null; then
    # check for required scopes
    scopes="$(gh api user -H "Authorization: token $(gh auth token)" -i | grep -i 'X-OAuth-Scopes:')"
fi

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

if ls ~/.ssh/id_* &>/dev/null; then
  gum format \
    "uploading your ssh public keys…"

    for x in ~/.ssh/id_*.pub; do
        gum format "uploading $(basename "$x")…"
        gh ssh-key add "$x" --title "$(hostname -s) (added by teaBASE)"
    done
fi


gum format "uploading your gpg public key…"

if GPG="$(bpb print)"; then
    echo "$GPG" | gh gpg-key add --title "$(hostname -s) (added by teaBASE)"
    # ^^ this errors out if the key already exists which sucks
    # ^^ TODO report bug
fi
