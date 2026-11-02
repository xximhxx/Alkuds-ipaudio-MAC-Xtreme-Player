رفع إصدار القدس r228 — النسخة العادية ونسخة دريم أو إس
=========================================================

ارفع الملفات الستة الموجودة في هذا المجلد إلى جذر فرع main في المستودع،
واستبدل أي ملف قديم يحمل الاسم نفسه:

  installer.sh
  alkuds-status.json
  Alkuds_ipaudio-r228.ipk
  Alkuds_ipaudio-r228-DreamOS-PY27.deb
  alkuds-status-dreamos.json
  installer-dreamos.sh

لا تحذف الملف القديم Alkuds_ipaudio-r223-DreamOS-PY27.deb إن كان موجودًا،
حتى تبقى نسخ installer-dreamos.sh القديمة المحفوظة على بعض الأجهزة قادرة
على العمل. الملف الجديد مستقل ولا يستبدله.

بعد الرفع، يبقى أمر التلنت واحدًا ولا يتغير:

  wget -qO- https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main/installer.sh | sh

الطريقة:
- إذا كانت Enigma2 تعمل ببايثون 3، يثبت installer.sh الحزمة Alkuds_ipaudio-r228.ipk.
- إذا كانت Enigma2 تعمل ببايثون 2.7 على دريم أو إس، يثبت installer.sh الحزمة
  Alkuds_ipaudio-r228-DreamOS-PY27.deb تلقائيًا.
- لا حاجة لتغيير الأمر أو اختيار ملف يدويًا.

البصمات SHA-256:
  installer.sh                          fc8d276b68722be9e26563eb42c776c66b694a2ae3b10559c9b7f6214bf5bd71
  alkuds-status.json                    b2bfa5ca2e53dedac99b1ef6ae0613a1326b0f3d645b5765ff576cfaa654e912
  Alkuds_ipaudio-r228.ipk              74da272310342f5f12f45860a0137d9f5dc7cc21191be1355314dab9b587bd54
  Alkuds_ipaudio-r228-DreamOS-PY27.deb 0bad0c38c787b8166cd0eb87e05c054f349d8bb38ec0441b2087c3367463b934
  alkuds-status-dreamos.json            6fa6506dbc644f37a44de824f8eb8340c3a4eabed85b507966a443e3a15c39c6
  installer-dreamos.sh                  d119d5d0e5547801a82d19c119767f30cb0571e5945dba0c65943dd050ecc8e9

ما الجديد:
- إصلاح جلب المسلسلات والأفلام من EgyDead عبر النطاق a1.egydead.media
  ودعم مشغلات MegaMax، ومن ArabSeed عبر مرآة الموبايل m.asd.watch.
- تحديث معرّفات أقسام Laroza للأفلام العربية والمسلسلات التركية.
- استبعاد محتوى +18 وقسم VIP من نتائج المزودين الثلاثة.
- الإبقاء على إصلاح حفظ اشتراك الصوتيات من صفحة الويب (r227).

ملاحظات:
- نسخة دريم أو إس مبنية على فرع r223-dreamos مع إصلاحات المزودين،
  ولا تتضمن إضافات 5TV الخاصة بنسخة بايثون 3.
- بعد التثبيت أعد تشغيل الواجهة من قائمة الرسيفر.
- نسخة دريم أو إس ما زالت تجريبية وتحتاج اختبارًا على الرسيفر.
