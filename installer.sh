#!/bin/sh
# Always install the package linked here. No version comparison or GitHub API check.
BASE="https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main"
PACKAGE_NAME="Alkuds_ipaudio-r156.ipk"
PACKAGE_URL="$BASE/$PACKAGE_NAME"
LOCK="/tmp/alkuds-update.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
    echo "Another Alkuds update is running. Wait for it to finish."
    exit 1
fi
PACKAGE_FILE="/tmp/Alkuds_ipaudio-$$.ipk"
LIST_FILE="/tmp/alkuds-github-$$.json"
LOG_FILE="/tmp/alkuds-opkg-$$.log"
cleanup() { rm -f "$PACKAGE_FILE" "$LIST_FILE" "$LOG_FILE"; rmdir "$LOCK" 2>/dev/null; }
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
fail() { echo "ERROR: $*"; exit 1; }
command -v opkg >/dev/null 2>&1 || fail "opkg is unavailable"
PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then PYTHON="$candidate"; break; fi
done
[ -n "$PYTHON" ] || fail "Python is unavailable"
STAMP=$(date +%s)
echo "Downloading $PACKAGE_NAME"
wget -T 30 -O "$PACKAGE_FILE" "$PACKAGE_URL?t=$STAMP" || fail "Download failed"
[ -s "$PACKAGE_FILE" ] || fail "The downloaded package is empty"
"$PYTHON" - "$PACKAGE_FILE" <<'PY'
import sys
with open(sys.argv[1],'rb') as f:
    if f.read(8)!=b'!<arch>\n': raise ValueError('Downloaded file is not an IPK')
PY
[ "$?" -eq 0 ] || fail "Invalid downloaded package"

# Retry only lock contention; never delete opkg's lock or stop other installers.
opkg_retry() {
    attempt=0
    while :; do
        opkg "$@" >"$LOG_FILE" 2>&1
        result=$?
        cat "$LOG_FILE"
        [ "$result" -eq 0 ] && return 0
        if ! grep -Eqi 'opkg_lock|privilege lock|Could not lock .*/opkg.lock' "$LOG_FILE"; then
            return "$result"
        fi
        attempt=$((attempt + 1))
        [ "$attempt" -ge 60 ] && return "$result"
        echo "Package manager is busy. Waiting 3 seconds ($attempt/60)..."
        sleep 3
    done
}

OLD_PACKAGE="enigma2-plugin-extensions-xklass"
OLD_PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/XKlass"
OLD_DATA_DIR="/etc/enigma2/xklass"
NEW_DATA_DIR="/etc/enigma2/alkuds"
if [ -d "$OLD_DATA_DIR" ] && [ ! -d "$NEW_DATA_DIR" ]; then
    mv "$OLD_DATA_DIR" "$NEW_DATA_DIR" || fail "Cannot migrate old settings"
fi
if [ -f /etc/enigma2/settings ]; then
    sed -i 's/^config\.plugins\.XKlass\./config.plugins.Alkuds./' /etc/enigma2/settings 2>/dev/null || true
fi
if opkg status "$OLD_PACKAGE" 2>/dev/null | grep -q 'Status:.*installed'; then
    opkg_retry remove --force-depends "$OLD_PACKAGE" || fail "Cannot remove the old package"
fi
echo "Installing $PACKAGE_NAME..."
opkg_retry install --force-reinstall --force-overwrite --force-downgrade "$PACKAGE_FILE" || fail "Alkuds installation failed; see the error above"
echo "Alkuds update completed. Restart the Enigma2 interface."
