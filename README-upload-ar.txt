رفع إصدار القدس r227 — النسخة العادية ونسخة دريم أو إس
=========================================================

ارفع الملفات الستة الموجودة في هذا المجلد إلى جذر فرع main في المستودع،
واستبدل أي ملف قديم يحمل الاسم نفسه:

  installer.sh
  alkuds-status.json
  Alkuds_ipaudio-r227.ipk
  Alkuds_ipaudio-r227-DreamOS-PY27.deb
  alkuds-status-dreamos.json
  installer-dreamos.sh

لا تحذف الملف القديم Alkuds_ipaudio-r223-DreamOS-PY27.deb إن كان موجودًا،
حتى تبقى نسخ installer-dreamos.sh القديمة المحفوظة على بعض الأجهزة قادرة
على العمل. الملف الجديد مستقل ولا يستبدله.

بعد الرفع، يبقى أمر التلنت واحدًا ولا يتغير:

  wget -qO- https://raw.githubusercontent.com/xximhxx/Alkuds-ipaudio-MAC-Xtreme-Player/main/installer.sh | sh

الطريقة:
- إذا كانت Enigma2 تعمل ببايثون 3، يثبت installer.sh الحزمة Alkuds_ipaudio-r227.ipk.
- إذا كانت Enigma2 تعمل ببايثون 2.7 على دريم أو إس، يثبت installer.sh الحزمة
  Alkuds_ipaudio-r227-DreamOS-PY27.deb تلقائيًا.
- لا حاجة لتغيير الأمر أو اختيار ملف يدويًا.

البصمات SHA-256:
  installer.sh                          6ed2809658c05d55cae0dacb974f3d035cf5b18655cc0e8d85289a3ed4debb7c
  alkuds-status.json                    1dc4bb3459e9b8afad8524dc13e2d35da7063fd616b121bf2c5b005eccb5230c
  Alkuds_ipaudio-r227.ipk               a2729e4a2180185d6057827693cf5303f0751a7d940d3b2856d0a642f4b3c666
  Alkuds_ipaudio-r227-DreamOS-PY27.deb  d842212c2f735a91de584d6322c4f3fdb9d53b90ce3850d4f0018d28f8d71224
  alkuds-status-dreamos.json            c27176ce6dfba2ca565d8943e2303469afb2e583204e345f235ab078dddacb1e
  installer-dreamos.sh                  704db2bf5cf2be3c5794e3b1e2cc0d6c641d61f6010ee7a2bae9c65731e5ebbd

ما الجديد:
- إصلاح حفظ اشتراك الصوتيات من صفحة الويب في النسختين.
- إزالة خطأ HTTP 403 الذي كان يظهر عند اختلاف المنفذ أو بروتوكول الصفحة.
- إبقاء حماية CSRF إلزامية لكل عملية حفظ.
- إصلاح إضافي في نسخة دريم أو إس: فحص عنوان العميل كان يرفض كل الطلبات
  بسبب تحويل النص إلى bytes في بايثون 2.7.

ملاحظات:
- نسخة دريم أو إس مبنية على فرع r223-dreamos مع إصلاح حفظ الصوتيات،
  ولا تتضمن إضافات 5TV الخاصة بنسخة بايثون 3.
- بعد التثبيت أعد تشغيل الواجهة من قائمة الرسيفر، ثم افتح صفحة الصوتيات
  من جديد ولا تستخدم صفحة قديمة مفتوحة قبل التحديث.
- نسخة دريم أو إس ما زالت تجريبية وتحتاج اختبارًا على الرسيفر.
