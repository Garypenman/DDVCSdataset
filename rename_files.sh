#!/usr/bin/env bash

dir="${1:-.}"

for f in "$dir"/*.{xml,hepmc,log}; do
  [ -e "$f" ] || continue

  base=$(basename "$f")
  new="$base"

  # --- Apply transformations ---
  new=$(echo "$new" | sed \
    -e 's/^EIC_//' \
    -e 's/DDVCS/ddvcs/g' \
    -e 's/DVCS/dvcs/g' \
    -e 's/TCS/tcs/g' \
    -e 's/edecay/ee/g' \
    -e 's/mudecay/mumu/g' \
    -e 's/BHONLY/bhonly/g'
  )

  # Rename only if needed
  if [[ "$base" != "$new" ]]; then
    mv -v "$dir/$base" "$dir/$new"
  fi
done
