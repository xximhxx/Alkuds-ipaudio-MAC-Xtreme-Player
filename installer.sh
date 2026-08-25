#!/bin/sh

echo "=========================================================="
echo "      Downloading Alkuds ipaudio-MAC-Xtreme-Player        "
echo "=========================================================="

# مسح أي نسخة قديمة في مجلد tmp لتجنب المشاكل
rm -f /tmp/Alkuds_ipaudio.ipk

# تحميل ملف البلجن من مستودعك برابطه المباشر
wget -O /tmp/Alkuds_ipaudio.ipk "https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main/Alkuds_ipaudio-R31P7-update-ip.ipk"

echo "=========================================================="
echo "               Installing Plugin...                       "
echo "=========================================================="

# أمر التثبيت
opkg install --force-overwrite /tmp/Alkuds_ipaudio.ipk

# حذف الملف بعد التثبيت لتوفير المساحة
rm -f /tmp/Alkuds_ipaudio.ipk

echo "=========================================================="
echo "           Installation Completed Successfully!           "
echo "                Restarting Enigma2 GUI...                 "
echo "=========================================================="

# إعادة تشغيل واجهة الإنيجما
killall -9 enigma2
exit 0
