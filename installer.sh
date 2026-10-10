#!/bin/sh
# Alkuds ipaudio updater - run on the receiver with:
#   wget -qO- https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main/installer.sh | sh
#
# Everything lives inside main() so the shell reads the whole file before it
# runs anything; a truncated download therefore never executes half a script.
# Commands that could read stdin get </dev/null, because stdin is this script.

main() {
    FILE="Alkuds_ipaudio-r149.ipk"
    URL="https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main/$FILE"
    TMP="/tmp/$FILE"
    MIN_BYTES=500000

    echo "================================"
    echo " Alkuds updater - $FILE"
    echo "================================"

    rm -f "$TMP"

    echo "Downloading..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$TMP" "$URL" </dev/null
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$TMP" "$URL" </dev/null
    else
        echo "ERROR: neither wget nor curl is available."
        return 1
    fi

    if [ ! -s "$TMP" ]; then
        echo "ERROR: download failed (check the internet connection)."
        rm -f "$TMP"
        return 1
    fi

    SIZE="$(wc -c < "$TMP" 2>/dev/null | tr -d ' ')"
    MAGIC="$(dd if="$TMP" bs=1 count=7 2>/dev/null </dev/null)"
    if [ "${SIZE:-0}" -lt "$MIN_BYTES" ] || [ "$MAGIC" != '!<arch>' ]; then
        echo "ERROR: downloaded file is not a valid package (size=${SIZE:-0})."
        rm -f "$TMP"
        return 1
    fi
    echo "Downloaded ${SIZE} bytes."

    echo "Installing..."
    if command -v opkg >/dev/null 2>&1; then
        opkg install --force-reinstall --force-overwrite "$TMP" </dev/null
    elif command -v dpkg >/dev/null 2>&1; then
        dpkg -i --force-overwrite "$TMP" </dev/null
    else
        echo "ERROR: no package manager (opkg/dpkg) found."
        rm -f "$TMP"
        return 1
    fi
    RESULT=$?

    rm -f "$TMP"

    if [ "$RESULT" -ne 0 ]; then
        echo "ERROR: installation failed (exit code $RESULT)."
        return "$RESULT"
    fi

    echo "================================"
    echo " Update installed successfully."
    echo " Restarting Enigma2 now..."
    echo "================================"
    sync
    sleep 3
    killall -9 enigma2 2>/dev/null
    return 0
}

main
exit $?
