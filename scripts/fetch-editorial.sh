#!/usr/bin/env bash
# Optional editorial photo enhancement. Bundled originals remain if download fails.
set -u
cd "$(dirname "$0")/.."
command -v curl >/dev/null || exit 0
command -v sips >/dev/null || exit 0
mkdir -p assets/editorial
fetch() {
  local name="$1" id="$2" tmp
  tmp=$(mktemp) || return 0
  if curl --silent --show-error --fail --location --connect-timeout 5 --max-time 22 "https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=1800" -o "$tmp" && sips -g pixelWidth -g pixelHeight "$tmp" >/dev/null 2>&1; then
    # Convert explicitly, so the bundled asset always remains a readable JPEG.
    if sips -s format jpeg "$tmp" --out "$tmp.jpg" >/dev/null 2>&1; then mv "$tmp.jpg" "assets/editorial/$name.jpg"; echo "Editorial photo available: $name"; fi
  fi
  rm -f "$tmp" "$tmp.jpg"
}
fetch skyline 5847340 & fetch terminal 5831522 & fetch signal 5831251 & fetch crisis 12564072 & fetch flash 5831253 & wait
fetch franc 36920199 & fetch brexit 15971322 & fetch pandemic 12564073 & fetch inflation 36967062 & fetch banking 7078501 & wait
fetch wall_street 33620019 & fetch london 5012092 & fetch tokyo 35488245 & fetch studio 36598869 & fetch identity 30096225 & wait
exit 0
