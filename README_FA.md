# اوبلیوین — کلاینت غیررسمی Warp

«اینترنت آزاد برای همه، یا هیچ‌کس»

اوبلیوین دسترسی امن و بهینه‌شده به اینترنت را با رابطی ساده و با فناوری
Cloudflare Warp فراهم می‌کند.

این برنامه روی [Aether](https://github.com/CluvexStudio/Aether) ساخته شده؛ هسته‌ای
فضای کاربری به زبان Rust که MASQUE و WireGuard را پیاده می‌کند و از یک کدبیس روی
اندروید، ویندوز و لینوکس اجرا می‌شود.

همان رابط فلاتر روی موبایل و دسکتاپ است. روی ویندوز پنجره فشرده ۴۴۰×۷۰۰ با سینی
سیستم، تغییر زبان انگلیسی / فارسی (راست‌به‌چپ) و هویت بصری اصلی اوبلیوین ارائه
می‌شود.

![oblivion3.jpg](media/oblivion3.jpg)

[English documentation](README.md)

## امکانات

- **دو ترابری**: MASQUE روی QUIC/HTTP-3 یا HTTP/2، و WireGuard کلاسیک.
- **Zero Trust**: اتصال به‌عنوان دستگاه سازمانی روی حساب کلادفلر سازمان، با کد
  ایمیلی، توکن سرویس، یا توکنی که خودتان نگه می‌دارید.
- **قواعد ترافیک**: مسدود کردن یک مقصد، یا عبور مستقیم بدون تونل (برای بانک‌ها و
  سایت‌های داخلی).
- **تونل انتخابی**: انتخاب اپ‌های اندروید که از تونل رد نشوند.
- **مخفی‌سازی**: پروفایل‌هایی که دست‌دادن را برای شبکه‌های انگشت‌نگار تغییر شکل
  می‌دهند.
- **رابط ساده**: فارسی و انگلیسی، با کلید یک‌ضرب زبان روی دسکتاپ.
- **دسکتاپ ویندوز**: پنجره بومی، سینی سیستم (قطع / در حال اتصال / متصل)، پروکسی
  SOCKS5، پروکسی سیستم اختیاری، و تونل کامل دستگاه با دسترسی مدیر.

## شروع سریع

1. **دانلود**: بسته پلتفرم خود را از صفحه
   [انتشارها](https://github.com/bepass-org/oblivion/releases) بگیرید و نصب کنید.

2. **اتصال**: اوبلیوین را باز کنید و کلید اتصال را بزنید.

روی اندروید برنامه به‌صورت سرویس VPN بدون روت کار می‌کند. روی ویندوز و لینوکس یک
پروکسی محلی SOCKS5 باز می‌شود و مسیریابی کامل دستگاه به دسترسی مدیر نیاز دارد.

### دسکتاپ ویندوز

رانر ویندوز در پوشه `windows/` است و `oblivion.exe` می‌سازد.

```sh
flutter pub get
flutter build windows --release
```

بسته انتشار در این مسیر نوشته می‌شود:

```
build/windows/x64/runner/Release/oblivion.exe
```

کل پوشه `Release` را کپی کنید (فایل exe به‌همراه `data/`، DLL موتور فلاتر و هسته‌های
بومی). کاربر نیازی به نصب فلاتر، راست یا JDK ندارد — فقط `oblivion.exe` را اجرا
می‌کند.

زبان: تنظیمات ← زبان، یا کنترل **EN / فا** روی نوار خانه.

## ساخت پروژه

### پیش‌نیازها

- فلاتر ۳٫۴۴ یا جدیدتر
- راست (stable) برای هسته Aether و پل FFI
- Android NDK r27 یا جدیدتر و JDK 17 برای ساخت اندروید
- Visual Studio 2022 با بار کاری «Desktop development with C++» برای ساخت ویندوز
- CMake، Ninja، Clang و `libgtk-3-dev` برای ساخت لینوکس

### کلون با ساب‌ماژول‌ها

هسته Aether و hev-socks5-tunnel در مخازن جدا هستند و اینجا به‌صورت ساب‌ماژول
وصل شده‌اند؛ پس بازگشتی کلون کنید:

```sh
git clone --recursive https://github.com/bepass-org/oblivion.git
```

اگر بدون `--recursive` کلون کرده‌اید:

```sh
git submodule update --init --recursive
```

### ساخت

```sh
flutter pub get

flutter build apk --release --split-per-abi
flutter build apk --release
flutter build linux --release
flutter build windows --release
```

ساخت اندروید هسته Aether را برای هر ABI درجا کراس‌کامپایل می‌کند، پس اولین ساخت
طول می‌کشد. با `--target-platform android-arm64` فقط یک ABI بسازید.

APK انتشار وقتی `android/key.properties` باشد امضا می‌شود و در غیر این صورت به
کلید دیباگ برمی‌گردد.

فایل `.exe` ویندوز فقط روی میزبان ویندوز با زنجیره ابزار Visual Studio C++ ساخته
می‌شود. این مخزن از قبل رانر کامل ویندوز، اتصال CMake هسته بومی، دارایی‌های سینی
و پوسته دسکتاپ را دارد.

## مشارکت

پروژه‌ای جامعه‌محور هستیم تا اینترنت برای همه در دسترس باشد. اگر می‌خواهید کد
بدهید، پیشنهاد بدهید یا کمک بگیرید، خوشحال می‌شویم. به
[مسائل گیت‌هاب](https://github.com/bepass-org/oblivion/issues) سر بزنید یا
درخواست ادغام بفرستید.

## سپاس و اعتبار

این پروژه از چند ابزار و کتابخانه متن‌باز استفاده می‌کند و از سازندگان آن‌ها
سپاسگزاریم:

### Cloudflare Warp

- **پروژه**: Cloudflare Warp
- **وب‌سایت**: [Cloudflare Warp](https://www.cloudflare.com/products/warp/)
- **مجوز**: [اطلاعات مجوز](https://www.cloudflare.com/application/terms/)
- **شرح**: فناوری کلادفلر برای امنیت و کارایی ترافیک اینترنت. ما از آن برای
  مسیریابی امن و کارآمد استفاده می‌کنیم.

### Aether

- **پروژه**: Aether
- **مخزن**: [Aether در گیت‌هاب](https://github.com/CluvexStudio/Aether)
- **مجوز**: [GNU Affero GPL v3.0](https://github.com/CluvexStudio/Aether/blob/main/LICENSE)
- **شرح**: هسته Warp این برنامه. MASQUE روی QUIC و HTTP/2، WireGuard، کشف نقطه
  پایانی، مخفی‌سازی و ثبت‌نام Zero Trust را پیاده می‌کند و تونل را به‌صورت پروکسی
  محلی در دسترس می‌گذارد.

### quiche

- **پروژه**: quiche
- **مخزن**: [quiche در گیت‌هاب](https://github.com/cloudflare/quiche)
- **مجوز**: [BSD 2-Clause](https://github.com/cloudflare/quiche/blob/master/COPYING)
- **شرح**: پیاده‌سازی QUIC و HTTP/3 کلادفلر. Aether تونل MASQUE را روی آن حمل
  می‌کند.

### hev-socks5-tunnel

- **پروژه**: hev-socks5-tunnel
- **مخزن**: [hev-socks5-tunnel در گیت‌هاب](https://github.com/heiher/hev-socks5-tunnel)
- **مجوز**: [MIT](https://github.com/heiher/hev-socks5-tunnel/blob/main/LICENSE)
- **شرح**: تبدیل tun به socks5. روی اندروید بسته‌های رابط VPN را به اتصال‌های
  پروکسی هسته تبدیل می‌کند.

### BoringTun

- **پروژه**: BoringTun
- **مخزن**: [BoringTun در گیت‌هاب](https://github.com/cloudflare/boringtun)
- **مجوز**: [BSD 3-Clause](https://github.com/cloudflare/boringtun/blob/master/LICENSE)
- **شرح**: پیاده‌سازی فضای کاربری WireGuard به زبان Rust برای ترابری WireGuard.

استفاده از این ابزارها تابع مجوزهای خودشان است.

## مجوز

این پروژه تحت مجوز Creative Commons Attribution-NonCommercial-ShareAlike 4.0
International است. متن کامل:
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

### خلاصه مجوز

- **Attribution (BY)**: باید اعتبار مناسب بدهید، پیوند مجوز را بگذارید و اگر
  تغییری داده‌اید بگویید.
- **NonCommercial (NC)**: استفاده تجاری مجاز نیست.
- **ShareAlike (SA)**: اگر بازترکیب یا تغییر دادید، باید با همین مجوز منتشر کنید.

این فقط یک مرور کوتاه است. برای متن حقوقی کامل به پیوند بالا بروید.
