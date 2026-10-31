#!/bin/sh
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
# Detect an actual Python 3 executable, including versioned image binaries.
# A Python 2 Enigma2 cannot load Python 3 plugins just by installing Python 3.
IS_PY2=0
for e2pid in $(pidof enigma2 2>/dev/null); do
    if grep -q 'libpython2[.]' "/proc/$e2pid/maps" 2>/dev/null; then IS_PY2=1; fi
done
if [ "$IS_PY2" = "1" ]; then
    # ---------- Python 2 Enigma2 (DreamOS DM900/DM920, old OpenATV/OpenPLi): separate PY27 package ----------
    PY2_NAME="Alkuds_ipaudio-r223-DreamOS-PY27.deb"
    PY2_SHA="17379bb4e50b8de37f9456f532657690ade604eba340c4138ecd6afb9cf1a492"
    PY2_FILE="/tmp/Alkuds_py27-$$.deb"
    PY2_IPK="/tmp/Alkuds_py27-$$.ipk"
    trap 'rm -f "$PY2_FILE" "$PY2_IPK"; rmdir "$LOCK" 2>/dev/null' EXIT
    echo "Python 2 Enigma2 detected - installing the Python 2.7 build."
    if [ -n "$1" ] && [ -s "$1" ]; then
        cp "$1" "$PY2_FILE" || fail "Cannot read $1"
        echo "Using local package: $1"
    else
        wget -T 30 -O "$PY2_FILE" "$BASE/$PY2_NAME?t=$(date +%s)" || fail "Download failed ($BASE/$PY2_NAME)"
    fi
    [ -s "$PY2_FILE" ] || fail "The downloaded package is empty"
    if [ "$(head -c 8 "$PY2_FILE")" != "!<arch>" ]; then fail "Downloaded file is not a valid package"; fi
    if command -v sha256sum >/dev/null 2>&1 && [ -z "$1" ]; then
        GOT=$(sha256sum "$PY2_FILE" | cut -d' ' -f1)
        [ "$GOT" = "$PY2_SHA" ] || fail "Package checksum mismatch (outdated upload?). expected $PY2_SHA got $GOT"
    fi
    if command -v dpkg >/dev/null 2>&1 && [ -f /var/lib/dpkg/status ]; then
        echo "Installing with dpkg (DreamOS)..."
        dpkg -i --force-overwrite --force-downgrade "$PY2_FILE" || fail "dpkg reported errors"
    elif command -v opkg >/dev/null 2>&1; then
        cp "$PY2_FILE" "$PY2_IPK"
        echo "Installing with opkg..."
        opkg install --force-reinstall --force-overwrite --force-downgrade "$PY2_IPK" || fail "opkg reported errors"
    else
        fail "Neither dpkg nor opkg is available"
    fi
    DEPS=/usr/lib/enigma2/python/Plugins/Extensions/Alkuds/dependencies.sh
    if [ -r "$DEPS" ]; then
        echo "Checking optional audio/video tools (failures here do not affect the plugin install)..."
        ALKUDS_PYTHON=python2.7 sh "$DEPS" installer || echo "Optional tools need attention. See /tmp/ipaudio-dependencies.log"
    fi
    echo "Alkuds (Python 2.7 build) installed. Restart the Enigma2 interface."
    exit 0
fi
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
