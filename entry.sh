#!/bin/bash

for f in /var/lib/mailman/*; do
  [[ -h "$f" ]] || continue
  if [[ "$(readlink "$f")" == /* ]]; then
    rm -f "$f"
  fi
done
cp -RTn /var/lib/mailman-defaults /var/lib/mailman

POSTMASTER="postmaster@${DOMAIN##lists.}"

cat <<EOF >>/etc/postfix/main.cf
relay_domains = $DOMAIN
relay_recipient_maps = hash:/var/lib/mailman/data/virtual-mailman
transport_maps = hash:/etc/postfix/transport
mailman_destination_recipient_limit = 1
EOF

cat <<EOF >/etc/postfix/transport:
$DOMAIN   mailman:
EOF

cat <<EOF >>/etc/mailman/mm_cfg.py
MTA = None # So that mailman skips aliases generation
POSTFIX_STYLE_VIRTUAL_DOMAINS = ['lists.example.com']
# alias for postmaster, abuse and mailer-daemon
DEB_LISTMASTER = '$POSTMASTER'
EOF

if [[ -n "$USER" ]] && [[ -n "$PASSWORD" ]]; then
  echo "$USER:$PASSWORD" >/etc/lighttpd.passwd
  cat <<EOF >>/etc/lighttpd/lighttpd.conf
  auth.require = (
    "/" => (
      "method"  => "digest",
      "realm"   => "Mailman",
      "require" => "valid-user"
    )
  )
EOF
fi

if [[ -n "$SITE_PASSWORD" ]]; then
  mmsitepass "$SITE_PASSWORD"
  chmod 644 /var/lib/mailman/data/adm.pw
fi

/usr/lib/mailman/bin/genaliases

exec supervisord
