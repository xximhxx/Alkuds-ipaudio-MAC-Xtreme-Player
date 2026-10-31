#!/bin/sh
# One public URL; choose the package matching Enigma2's actual Python runtime.
E2_MAJOR=""
SEEN2=0
SEEN3=0
for e2pid in $(pidof enigma2 2>/dev/null); do
    if grep -q 'libpython2[.]' "/proc/$e2pid/maps" 2>/dev/null; then SEEN2=1;fi
    if grep -q 'libpython3[.]' "/proc/$e2pid/maps" 2>/dev/null; then SEEN3=1;fi
done
if [ "$SEEN2" = 1 ] && [ "$SEEN3" = 1 ]; then
    echo "Cannot determine one Enigma2 Python runtime; no installation attempted."
    exit 1
elif [ "$SEEN2" = 1 ]; then E2_MAJOR=2
elif [ "$SEEN3" = 1 ]; then E2_MAJOR=3
else
    # When the GUI is stopped, inspect its linked runtime before using defaults.
    E2_BINARY=$(command -v enigma2 2>/dev/null || true)
    if [ -n "$E2_BINARY" ] && command -v ldd >/dev/null 2>&1; then
        E2_LINKS=$(ldd "$E2_BINARY" 2>/dev/null || true)
        case "$E2_LINKS" in *libpython2.*) E2_MAJOR=2;; *libpython3.*) E2_MAJOR=3;; esac
    fi
    if [ -z "$E2_MAJOR" ]; then
        if command -v python >/dev/null 2>&1; then
            E2_MAJOR=$(python -c 'import sys;print(sys.version_info[0])' 2>/dev/null || true)
        elif command -v python3 >/dev/null 2>&1; then
            E2_MAJOR=$(python3 -c 'import sys;print(sys.version_info[0])' 2>/dev/null || true)
        fi
    fi
fi
case "$E2_MAJOR" in
    2)
        if ! command -v dpkg >/dev/null 2>&1; then
            echo "Python 2 detected, but this build requires DreamOS/dpkg. No installation attempted."
            exit 1
        fi
        echo "DreamOS Python 2 detected: using the dedicated DEB build."
        (
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
if not data.startswith('!<arch>\n') or hashlib.sha256(data).hexdigest()!='17379bb4e50b8de37f9456f532657690ade604eba340c4138ecd6afb9cf1a492':
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

        )
        exit $?
        ;;
    3)
        echo "Python 3 detected: using the regular IPK build."
        ;;
    *)
        echo "Unable to identify Enigma2 Python; no installation attempted."
        exit 1
        ;;
esac
# Always install the package linked here. No version comparison or GitHub API check.
BASE="https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main"
PACKAGE_NAME="Alkuds_ipaudio-r223.ipk"
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
ALKUDS_PYTHON=""
for candidate in python3 python3.14 python3.13 python3.12 python3.11 python3.10 python3.9 python3.8 python3.7 python3.6 python; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
        ALKUDS_PYTHON="$candidate"
        break
    fi
done
if [ -z "$ALKUDS_PYTHON" ]; then
    echo "ERROR: No usable Python 3 interpreter found. This is a runtime compatibility issue, not a download error."
    echo "Do not install another Python version blindly; use a build matching the image's Enigma2 Python."
    exit 1
fi
PYTHON="$ALKUDS_PYTHON"
STAMP=$(date +%s)
echo "Downloading $PACKAGE_NAME"
wget -T 30 -O "$PACKAGE_FILE" "$PACKAGE_URL?t=$STAMP" || fail "Download failed"
[ -s "$PACKAGE_FILE" ] || fail "The downloaded package is empty"
"$PYTHON" - "$PACKAGE_FILE" <<'PY'
import sys, hashlib
with open(sys.argv[1],'rb') as f:
    if f.read(8)!=b'!<arch>\n': raise ValueError('Downloaded file is not an IPK')
    f.seek(0)
    if hashlib.sha256(f.read()).hexdigest() != '698ca2a5843b6d264b19930415a75b6b6eab0482aead883bb5bd19e9e6d84aca':
        raise ValueError('The downloaded package is outdated or mismatched. Upload all three release files together.')
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
export ALKUDS_PYTHON
export ALKUDS_DEPS_FOREGROUND=1
echo "Installing $PACKAGE_NAME..."
opkg_retry install --force-reinstall --force-overwrite --force-downgrade "$PACKAGE_FILE" || fail "opkg reported errors; inspect Alkuds and any other pending packages above. Other plugins were not modified by this installer"
"$PYTHON" - <<'PY'
import hashlib
path='/usr/lib/enigma2/python/Plugins/Extensions/Alkuds/subscriptioncheck.py'
with open(path,'rb') as handle: content=handle.read()
if hashlib.sha256(content).hexdigest() != '8f55e75d16673eca4e142901282ea3882f83ae83d73d7ea491d59e1be60218c5':
    raise ValueError('Installed menu does not match this release')
if b'backup_one' in content or b'backup_all' in content:
    raise ValueError('Old menu entries are still installed')
PY
[ "$?" -eq 0 ] || fail "Installed menu verification failed"
DEPS=/usr/lib/enigma2/python/Plugins/Extensions/Alkuds/dependencies.sh
if [ -r "$DEPS" ]; then
    echo "Checking audio/video tools using this image's configured feeds..."
    sh "$DEPS" installer || echo "Dependency setup needs attention. See /tmp/ipaudio-dependencies.log"
fi
echo "Alkuds update completed. Review /tmp/ipaudio-dependencies.log for unavailable tools."
echo "Restart the Enigma2 interface after setup completes."
