#!/bin/bash

for f in /var/lib/mailman/*; do
  [[ -h "$f" ]] || continue
  if [[ "$(readlink "$f")" == /* ]]; then
    rm -f "$f"
  fi
done
cp -RTn /var/lib/mailman-defaults /var/lib/mailman
exec supervisord
