#!/bin/sh
set -eu
BASE=https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main
NAME=Alkuds_ipaudio-r239-DreamOS-PY27.deb
[ "$#" -le 1 ] || { echo "Usage: sh installer-dreamos.sh [local.deb]";exit 1; }
FILE=""
TEMP_FILE=""
cleanup() { if [ -n "$TEMP_FILE" ]; then rm -f "$TEMP_FILE";fi; }
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
download_file() {
    url="$1"
    dest="$2"
    rm -f "$dest"
    if command -v wget >/dev/null 2>&1; then
        if wget --no-check-certificate -T 60 -O "$dest" "$url"; then
            [ -s "$dest" ] && return 0
        fi
        rm -f "$dest"
        if wget -T 60 -O "$dest" "$url"; then
            [ -s "$dest" ] && return 0
        fi
    fi
    rm -f "$dest"
    if command -v curl >/dev/null 2>&1; then
        if curl -kL --connect-timeout 20 --max-time 300 -o "$dest" "$url"; then
            [ -s "$dest" ] && return 0
        fi
    fi
    rm -f "$dest"
    return 1
}
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
    download_file "$BASE/$NAME?t=$(date +%s)" "$FILE" || { echo "Download failed. Check the network and receiver date, then retry.";exit 1; }
else
    FILE="$1"
    [ -s "$FILE" ] || { echo "Local DEB not found: $FILE";exit 1; }
fi
"$PY" - "$FILE" <<'PY'
import sys,hashlib
with open(sys.argv[1],'rb') as handle:data=handle.read()
if not data.startswith('!<arch>\n') or hashlib.sha256(data).hexdigest()!='80d32dfd1c9c7c29f80c0a84b9217084bad0069620523e4e7e92a541fcce4202':
    raise SystemExit('The DreamOS package is outdated or mismatched. Upload the matching release files together.')
PY
# Only use the receiver's configured feeds. Never install another Python runtime.
if ! "$PY" -c 'import requests,six' >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -y install python-requests python-six
fi
dpkg --force-confold -i "$FILE"
DEPS=/usr/lib/enigma2/python/Plugins/Extensions/Alkuds/dependencies.sh
if [ -f "$DEPS" ]; then ALKUDS_PYTHON="$PY" sh "$DEPS" --auto || true;fi
echo "Restart the GUI from the receiver menu. This is the DreamOS Python 2.7 build."
internal_update=0
ancestor=$PPID
while [ -n "$ancestor" ] && [ "$ancestor" -gt 1 ] 2>/dev/null; do
    command_name=$(cat "/proc/$ancestor/comm" 2>/dev/null || true)
    if [ "$command_name" = "enigma2" ]; then internal_update=1;break;fi
    ancestor=$(awk '/^PPid:/{print $2}' "/proc/$ancestor/status" 2>/dev/null || true)
done
if [ "$internal_update" = 1 ] && command -v systemctl >/dev/null 2>&1; then
    old_enigma_pids=$(pidof enigma2 2>/dev/null || true)
    echo "Internal update completed. Restarting Enigma2 safely..."
    sync
    if systemctl --no-block restart enigma2; then
        wait_count=0
        while [ "$wait_count" -lt 15 ]; do
            alive=0
            for old_pid in $old_enigma_pids; do kill -0 "$old_pid" 2>/dev/null && alive=1;done
            [ "$alive" = 0 ] && exit 0
            wait_count=$((wait_count + 1))
            sleep 1
        done
    fi
fi

