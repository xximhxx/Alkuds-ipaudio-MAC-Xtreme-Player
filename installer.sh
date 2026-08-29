#!/bin/sh

echo "=========================================================="
echo "      Downloading Alkuds ipaudio-MAC-Xtreme-Player        "
echo "=========================================================="

rm -f /tmp/Alkuds_ipaudio.ipk

wget -O /tmp/Alkuds_ipaudio.ipk "https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main/Alkuds_ipaudio-R32.ipk"

echo "=========================================================="
echo "               Installing Plugin...                       "
echo "=========================================================="

# تمت إضافة --force-reinstall هنا
opkg install --force-reinstall --force-overwrite /tmp/Alkuds_ipaudio.ipk

rm -f /tmp/Alkuds_ipaudio.ipk

echo "=========================================================="
echo "           Installation Completed Successfully!           "
echo "                Restarting Enigma2 GUI...                 "
echo "=========================================================="

killall -9 enigma2
exit 0
