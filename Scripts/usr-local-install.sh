#!/bin/sh
# ^^ using bash fails for the admin escalation API we use, we dunno why

if ! test -d /usr/local/bin; then
    /bin/mkdir -p /usr/local/bin
    /bin/chmod 755 /usr/local/bin
fi

/bin/cp "$1" /usr/local/bin
/bin/chmod 755 /usr/local/bin/"$(/usr/bin/basename "$1")"
