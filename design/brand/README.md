# هوية بستان القرآن البصرية (2026)

هوية جديدة كليًا لمنصّة بستان القرآن نفسها (الشعار، اللون الافتراضي، الأيقونة،
شاشة البدء). **لا علاقة لها بألوان مركز بعينه** — كل مركز يبقى يختار ألوانه
الخاصة من إعدادات المركز كما كان دائمًا؛ هذه الهوية هي ما يظهر قبل اختيار
المركز لونه (مركز جديد، صفحة الدخول، صفحات المنصة، لوحة المالك) وما يظهر على
أيقونة التطبيق نفسها بغضّ النظر عن المركز.

## الفكرة

"بستان" = حديقة/بستان. العلامة مصحف مفتوح تنبت منه غصن — المعرفة القرآنية
كبستان ينمو. إطار دائري ذهبي رفيع يوحي بزخرفة المخطوطات القرآنية.

## الألوان

| الاسم | Hex | الاستخدام |
|---|---|---|
| Emerald (أساسي) | `#1E7A54` | اللون الأساسي الافتراضي — أزرار، روابط، إطار الشعار |
| Deep ink-green (غامق) | `#0B3B2E` | الوضع الداكن، خلفية شاشة البدء الداكنة |
| Adaptive icon bg | `#12523A` | خلفية أيقونة أندرويد المتكيّفة |
| Gold (ثانوي) | `#D4A24C` | لمسات ذهبية — الغصن، الإطار الدائري |
| Parchment (محايد) | `#FBF8F1` | خلفية الصفحات الفاتحة، صفحات المصحف/الكتاب |

المصدر الوحيد لهذه القيم: `apps/web/tailwind.config.ts` (fallback لكل مركز
جديد) و`apps/mobile/lib/core/theme/app_theme.dart`
(`kDefaultBrandColor`) وعمود `organizations.primary_color`/`secondary_color`
الافتراضي (`0053_new_platform_identity.sql`).

## الملفات

- `icon-source.svg` / `.png` (1024×1024) — الأيقونة الكاملة (خلفية + علامة)، تُستخدم لأيقونة iOS ولصفحة الويب (`apps/web/src/app/icon.png`, `apple-icon.png`).
- `icon-foreground.svg` / `.png` (1024×1024, شفافة) — العلامة وحدها، لطبقة "adaptive icon" في أندرويد.
- `splash-image.svg` / `.png` (640×640, شفافة) — العلامة لشاشة البدء (`flutter_native_splash`).
- `icon-512.png`, `icon-180.png`, `icon-32.png` — مقاسات جاهزة لصفحات الويب/الفافيكون.

## إعادة التوليد

عند تعديل أي SVG، أعد توليد PNG (يحتاج حزمة `sharp`، أُزيلت بعد الاستخدام):

```bash
cd design/brand && npm init -y && npm install sharp
node -e "
const sharp = require('sharp');
sharp('icon-source.svg', {density:384}).resize(1024,1024).png().toFile('icon-source.png');
sharp('icon-foreground.svg', {density:384}).resize(1024,1024).png().toFile('icon-foreground.png');
sharp('splash-image.svg', {density:384}).resize(640,640).png().toFile('splash-image.png');
"
rm -rf node_modules package.json package-lock.json
cp icon-source.png icon-foreground.png splash-image.png ../../apps/mobile/assets/brand/
```

ثم في `apps/mobile`:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

(عند إضافة منصّة iOS لاحقًا: `flutter create --platforms=ios .` ثم اجعل
`ios: true` في إعداد `flutter_launcher_icons` بـ `pubspec.yaml`.)

## برومتات لصور إضافية (لأداة توليد صور بالذكاء الاصطناعي)

الرمز نفسه (SVG) جاهز ومُركَّب في التطبيق فعليًا. الصور التالية فنّية/تسويقية
أوسع من أن تُكتب متجهات يدويًا بجودة جيدة — هذه برومتات جاهزة للصق في أي أداة
توليد صور (Midjourney، DALL·E، Ideogram...). اذكر معها دومًا: بلا نصوص عربية
داخل الصورة (الأدوات تكتبها مشوَّهة)، وبلا وجوه واضحة المعالم (زخرفة/تجريد
أفضل لمركز تعليم ديني).

**1) صورة الغلاف الرئيسية لصفحة الويب التسويقية (hero)**
> A serene minimalist Islamic garden at golden hour, geometric arabesque
> patterns woven into rows of green plants and an open book motif, emerald
> green (#1E7A54) and warm gold (#D4A24C) color palette on a soft parchment
> background (#FBF8F1), flat vector illustration style, no text, no
> recognizable human faces, wide 16:9 composition, plenty of negative space
> on the right third for a headline overlay.

**2) خلفية شاشة تسجيل الدخول (موبايل وويب)**
> Abstract Islamic geometric pattern inspired by mosque tilework, thin gold
> line art on a deep emerald green background, subtle and low-contrast so
> text stays readable on top, seamless/tileable, no text, square or
> portrait 3:4 composition.

**3) صورة مشاركة اجتماعية (Open Graph / OG image، 1200×630)**
> Flat vector illustration of an open Quran with a small green sprout
> growing from its spine, encircled by a thin gold ring, centered on a deep
> emerald gradient background, generous empty margin on both sides for a
> logo and headline, no text baked into the image, 1200x630 landscape.

**4) رسمة حالة فارغة (empty state) — "لا يوجد عناصر بعد"**
> Simple friendly flat-line illustration of a small potted plant next to a
> closed book, single thin gold outline on transparent background, minimal
> and modern, no shading, no background, square 1:1.

**5) صورة متجر التطبيقات (feature graphic، 1024×500)**
> Wide banner: emerald green gradient background, centered open-book-and-
> sprout emblem in warm gold and cream, thin gold ring around it, generous
> clean space left and right, flat vector, no text, 1024x500 landscape.

استخدم الناتج مباشرة كصور ثابتة (لا تحتاج شفافية غالبًا)، أو اطلب من الأداة
نسخة بخلفية شفافة لدمجها فوق الألوان الفعلية بنفسك.
