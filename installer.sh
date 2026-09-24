#!/bin/sh

PACKAGE_URL="https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main/Alkuds_ipaudio-24092026.ipk"
PACKAGE_FILE="/tmp/Alkuds_ipaudio.ipk"
OLD_PACKAGE="enigma2-plugin-extensions-xklass"
OLD_PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/XKlass"
OLD_DATA_DIR="/etc/enigma2/xklass"
NEW_DATA_DIR="/etc/enigma2/alkuds"

cleanup() {
    rm -f "$PACKAGE_FILE"
}

fail() {
    echo "ERROR: $1"
    cleanup
    exit 1
}

echo "=========================================================="
echo "      Downloading Alkuds ipaudio-MAC-Xtreme-Player        "
echo "=========================================================="

cleanup
wget -O "$PACKAGE_FILE" "$PACKAGE_URL" || fail "Unable to download Alkuds package."
[ -s "$PACKAGE_FILE" ] || fail "Downloaded package is empty."

echo "=========================================================="
echo "      Removing the old XClass/XKlass installation...      "
echo "=========================================================="

# Keep playlists and account data while moving them to the new Alkuds name.
if [ -d "$OLD_DATA_DIR" ] && [ ! -d "$NEW_DATA_DIR" ]; then
    mv "$OLD_DATA_DIR" "$NEW_DATA_DIR" 2>/dev/null || true
fi

# Keep Enigma2 settings while changing the configuration namespace.
if [ -f /etc/enigma2/settings ]; then
    sed -i 's/^config\.plugins\.XKlass\./config.plugins.Alkuds./' /etc/enigma2/settings 2>/dev/null || true
fi

# Remove the old package record when present. Failure is non-fatal because
# some receivers have the old files installed without an opkg database entry.
if command -v opkg >/dev/null 2>&1; then
    if opkg status "$OLD_PACKAGE" 2>/dev/null | grep -q '^Status:.* installed'; then
        opkg remove --force-depends "$OLD_PACKAGE" || true
    fi
else
    fail "opkg was not found on this receiver."
fi

# Always remove leftover files from the former plugin folder and components.
rm -rf "$OLD_PLUGIN_DIR"
rm -f /usr/lib/enigma2/python/Components/Converter/XKlassServiceInfo.py \
      /usr/lib/enigma2/python/Components/Converter/XKlassServiceInfo.pyc \
      /usr/lib/enigma2/python/Components/Converter/XKlassServicePosition.py \
      /usr/lib/enigma2/python/Components/Converter/XKlassServicePosition.pyc \
      /usr/lib/enigma2/python/Components/Renderer/XKlassRunningText.py \
      /usr/lib/enigma2/python/Components/Renderer/XKlassRunningText.pyc 2>/dev/null || true

echo "=========================================================="
echo "               Installing Alkuds Plugin...                "
echo "=========================================================="

opkg install --force-reinstall --force-overwrite "$PACKAGE_FILE" \
    || fail "Alkuds installation failed."

cleanup

echo "=========================================================="
echo "           Installation Completed Successfully!           "
echo "                    IBRAHEM HAMDAN                         "
echo "=========================================================="

exit 0
