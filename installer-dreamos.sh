#!/bin/sh
set -eu
BASE=https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main
NAME=Alkuds_ipaudio-r223-DreamOS-PY27.deb
[ "$#" -le 1 ] || { echo "Usage: sh installer-dreamos.sh [local.deb]";exit 1; }
FILE=""
TEMP_FILE=""
cleanup() { if [ -n "$TEMP_FILE" ]; then rm -f "$TEMP_FILE";fi; }
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
PY=""
for candidate in python2.7 python; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import sys;sys.exit(0 if sys.version_info[:2]==(2,7) else 1)' >/dev/null 2>&1; then PY="$candidate";break;fi
done
[ -n "$PY" ] || { echo "Python 2.7 is required; no installation attempted.";exit 1; }
command -v dpkg >/dev/null 2>&1 || { echo "This build is for DreamOS/dpkg receivers.";exit 1; }
for pid in $(pidof enigma2 2>/dev/null || true); do
    if grep -q 'libpython3[.]' "/proc/$pid/maps" 2>/dev/null; then echo "Python 3 Enigma2 detected; use the regular build.";exit 1;fi
done
if [ "$#" -eq 0 ]; then
    TEMP_FILE=$(mktemp /tmp/alkuds-dreamos.XXXXXX)
    FILE="$TEMP_FILE"
    wget -T 30 -O "$FILE" "$BASE/$NAME?t=$(date +%s)"
else
    FILE="$1"
    [ -s "$FILE" ] || { echo "Local DEB not found: $FILE";exit 1; }
fi
"$PY" - "$FILE" <<'PY'
import sys,hashlib
with open(sys.argv[1],'rb') as handle:data=handle.read()
if not data.startswith('!<arch>\n') or hashlib.sha256(data).hexdigest()!='51655d3fae9b4b7e8c5998d19f51693fa171b2fdd8bfed1d50731cdeeb45c6f4':
    raise SystemExit('The DreamOS package is outdated or mismatched. Upload all three release files together.')
PY
# Only use the receiver's configured feeds. Never install another Python runtime.
if ! "$PY" -c 'import requests,six' >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -y install python-requests python-six
fi
dpkg --force-confold -i "$FILE"
DEPS=/usr/lib/enigma2/python/Plugins/Extensions/Alkuds/dependencies.sh
if [ -f "$DEPS" ]; then ALKUDS_PYTHON="$PY" sh "$DEPS" --auto || true;fi
echo "Restart the GUI from the receiver menu. This is the experimental DreamOS Python 2.7 build."
