# Refocus Design System

> **Take back your attention.**

Dokumen ini menjadi acuan visual dan UX untuk pengembangan **Refocus**, aplikasi Android open-source yang membantu pengguna mengurangi distraksi dan mengambil kembali kendali atas perhatian mereka.

## 1. Design Philosophy

Refocus bukan aplikasi yang bertujuan membuat pengguna terus berada di dalam aplikasi. Tujuan desainnya adalah membantu pengguna **keluar dari distraction zone dan kembali ke aktivitas yang ingin mereka lakukan**.

Prinsip utama:
- **Calm over addictive** — antarmuka tenang, tidak dirancang untuk membuat pengguna terus membuka aplikasi.
- **Clarity over decoration** — informasi penting harus mudah dipahami.
- **Minimal intervention** — intervensi hanya muncul ketika diperlukan.
- **No shame** — jangan menggunakan bahasa yang menghakimi pengguna.
- **Privacy first** — UI tidak boleh memberi kesan bahwa Refocus membaca atau mengumpulkan isi pribadi pengguna.
- **Progress without pressure** — statistik membantu memahami kebiasaan, bukan menciptakan tekanan.
- **Accessible by default** — warna, ukuran teks, kontras, dan interaksi memperhatikan accessibility.

## 2. Brand Identity

### Brand Name
**Refocus**

Gunakan `Refocus` sebagai bentuk standar. `ReFocus` hanya digunakan jika mengikuti bentuk wordmark resmi.

### Tagline
**Take back your attention.**

Tagline digunakan sebagai supporting statement pada landing page, README, onboarding, About screen, dan presentasi brand. Tidak perlu muncul di setiap halaman aplikasi.

## 3. Logo

Logo Refocus terdiri dari:
1. **Mark** — simbol geometris berbentuk R dengan aksen sparkle.
2. **Wordmark** — `ReFocus`.
3. **Tagline** — `Take back your attention.`

### Logo Assets

```text
assets/
└── branding/
    ├── refocus-logo.png
    ├── refocus-logo-dark.png
    └── refocus-mark.png
```

| Asset | Penggunaan |
|---|---|
| `refocus-logo.png` | Logo lengkap |
| `refocus-logo-dark.png` | Logo pada background terang |
| `refocus-mark.png` | App icon, favicon, avatar |

### App Icon

Android launcher icon menggunakan **mark**, bukan logo lengkap. Wordmark terlalu kecil untuk terbaca pada ukuran launcher icon.

### Logo Do
- Berikan ruang kosong yang cukup.
- Pertahankan proporsi.
- Gunakan versi yang sesuai dengan background.
- Gunakan mark untuk ukuran kecil.

### Logo Don't
Jangan mengubah proporsi, memutar logo, menambahkan shadow berlebihan, menggunakan gradient baru di luar brand system, menambahkan outline, mengubah warna secara sembarangan, atau menempatkan logo pada background dengan kontras buruk.

## 4. Color System

Refocus menggunakan visual direction **dark-first**, dengan warna netral gelap dan accent yang memiliki makna fungsional.

### Core Colors

| Token | Hex | Fungsi |
|---|---|---|
| Background | `#0F1117` | Background utama |
| Surface | `#1A1D27` | Card, panel, surface |
| Text Primary | `#EEF0F6` | Teks utama |
| Text Secondary | `#7A7F94` | Teks sekunder |
| Border | `#2A2E3A` | Divider dan border |

### State Colors

| State | Hex | Makna |
|---|---|---|
| Idle | `#6EE7B7` | Protection aktif dan kondisi normal |
| Distracting | `#FBBF24` | Pengguna berada dalam distraction zone |
| Cooldown | `#818CF8` | Cooldown sedang berlangsung |
| Locked | `#F87171` | Daily limit telah tercapai |

State colors adalah **semantic signal**, bukan dekorasi. Jangan menggunakan seluruh state colors sekaligus pada satu screen.

## 5. Typography

Font baseline: **Roboto**.

Hierarchy:
```text
Display / Hero
Large heading
Section heading
Body
Secondary text
Caption
```

Gunakan hierarchy yang jelas, jangan terlalu banyak font weight, hindari ALL CAPS untuk paragraf, dan jangan membuat angka statistik terlalu dekoratif.

## 6. Spacing

Gunakan sistem spacing berbasis kelipatan **4 dp**.

```text
4   micro
8   compact
12  small
16  default
24  section
32  large
48  major separation
64  hero
```

Default horizontal page padding: **16–24 dp**.

## 7. Shape & Radius

Rekomendasi:
```text
Small component    8 dp
Card               12–16 dp
Dialog / Overlay   16–20 dp
Large container    20–24 dp
```

Hindari pill shape berlebihan dan radius yang berbeda-beda tanpa alasan.

## 8. Elevation & Surface

Refocus tidak menggunakan glassmorphism sebagai gaya utama.

Gunakan solid surfaces, subtle border, dan sedikit elevation jika diperlukan. Hindari shadow besar.

Hierarchy:
```text
Background
   ↓
Surface
   ↓
Elevated Surface
   ↓
Dialog / Overlay
```

## 9. Iconography

Gunakan icon yang simple, line-based, mudah dikenali, dan konsisten.

Contoh:
- Apps → App/grid
- Timer → Clock
- Cooldown → Pause/timer
- Settings → Gear
- Protection → Shield
- Statistics → Chart

Hindari emoji sebagai icon utama production UI.

## 10. Core App States

State machine utama:
```text
NORMAL / IDLE
      │
      │ protected app digunakan
      ▼
DISTRACTING
      │
      │ trigger duration tercapai
      ▼
COOLDOWN
      │
      │ cooldown selesai
      ▼
NORMAL / IDLE

COOLDOWN
      │
      │ daily session limit tercapai
      ▼
DAILY LOCKED
```

### Idle
Soft green indicator dan timer tidak aktif.

Tone:
> Protection is active.

### Distracting
Amber accent dan timer menjadi elemen utama tanpa animasi agresif.

Tone:
> You're in a distraction zone.

### Cooldown
Indigo accent dan remaining time menjadi informasi utama.

Tone:
> Take a short break.

### Daily Locked
Muted red sebagai status, tetap tenang dan tidak menghukum.

Tone:
> Your daily limit has been reached.

Hindari bahasa seperti `You failed.` atau `You wasted your time.`

## 11. Home Screen

Home screen harus menjawab:
1. Apakah protection aktif?
2. Apa kondisi saya sekarang?
3. Apa yang perlu saya lakukan?

Prioritas:
```text
Protection Status
       ↓
Current State / Timer
       ↓
Protected Apps
       ↓
Today's Sessions
       ↓
Secondary Actions
```

Jangan memenuhi home screen dengan statistik yang tidak diperlukan.

## 12. Protection Status

Status protection harus selalu **jujur terhadap kondisi Android**.

`Protection Active` hanya boleh ditampilkan jika komponen yang diperlukan benar-benar aktif.

Jika ada masalah:
```text
Protection needs attention
[Fix protection]
```

Jangan mengatakan protection aktif jika enforcement sebenarnya tidak dapat berjalan.

## 13. Protected Apps

Pemilihan aplikasi harus sederhana.

Contoh:
```text
[App Icon] TikTok
           Protected
```

Gunakan switch/toggle untuk mengaktifkan perlindungan.

Prinsip inti:
> Global distraction timer, bukan timer terpisah untuk setiap aplikasi.

## 14. Global Distraction Timer

Timer menghitung total waktu selama pengguna berada di **distraction zone**.

Contoh:
```text
TikTok       3:00
Instagram    2:00
             -----
Total        5:00
```

Perpindahan antar protected apps tidak mereset timer. Keluar dari protected apps menghentikan akumulasi distraction time.

## 15. Warning Overlay

Flow:
```text
Protected App
     ↓
Trigger reached
     ↓
Warning Overlay
     ↓
5 seconds
     ↓
Intervention / exit
```

Overlay harus jelas, singkat, tenang, dan tidak membuat pengguna ingin berinteraksi lebih lama.

Contoh:
```text
REFOCUS

Distraction limit reached.

Take a short break.

Continuing in 5s...
```

Countdown harus sederhana dan tidak flashy.

## 16. Blocking Experience

Blocking bukan hukuman. Tujuannya memberikan **friction** agar pengguna menyadari kebiasaan otomatis.

```text
Awareness
   ↓
Pause
   ↓
Intervention
```

Bukan:
```text
Punishment
   ↓
Frustration
```

## 17. Cooldown Screen

Contoh:
```text
Cooldown

12:34

Protected apps are temporarily unavailable.

Take a break and return when you're ready.
```

Jika cooldown tidak dapat dilewati, jangan menyediakan tombol Skip/Continue/Disable palsu.

## 18. Daily Lock Screen

Contoh:
```text
Daily limit reached

5 / 5 sessions used

Protected apps will be available again tomorrow.
```

Fokus pada informasi dan waktu pemulihan, bukan rasa bersalah.

## 19. Settings

Kelompokkan berdasarkan tujuan:
```text
Protection
├── Protected Apps
├── Trigger Duration
├── Cooldown Duration
└── Daily Session Limit

Permissions
├── Usage Access
├── Accessibility
├── Notifications
└── Background Protection

Appearance
├── Theme
└── Reduce Motion

About
├── Version
├── Open Source
└── Privacy
```

## 20. Permission UX

Permission sensitif harus dijelaskan sebelum sistem meminta akses.

### Usage Access
> Why is this needed?
>
> Refocus uses app usage information to know when you enter or leave a protected app.
>
> Refocus does not need your messages or passwords.

### Accessibility
> Why is this needed?
>
> Refocus uses Android accessibility capabilities to detect protected-app usage and provide blocking interventions.
>
> Refocus does not read your messages, passwords, or personal content.

Penjelasan harus selalu sesuai dengan implementasi aktual.

## 21. Permission Health

Permission Center menampilkan status:
```text
Permission Center

✓ Usage Access
✓ Accessibility
✓ Notifications
✓ Background Protection
```

Jika bermasalah:
```text
⚠ Accessibility
   Protection may not work correctly

   [Fix]
```

Permission health diperiksa kembali ketika aplikasi resume.

## 22. Notifications

Notification digunakan hanya untuk:
- protection status;
- cooldown;
- daily lock;
- important permission issue.

Jangan menggunakan notification sebagai engagement mechanism. Hindari motivational spam, streak notifications, dan notifikasi yang tidak memiliki tujuan.

## 23. Animation & Motion

Animation hanya membantu memahami perubahan state.

Sesuai:
- fade;
- subtle scale;
- progress transition;
- countdown transition.

Durasi umum:
```text
100–150 ms → micro interaction
150–250 ms → component transition
250–350 ms → screen/state transition
```

Hindari infinite animation, bouncing UI, confetti, flashy transitions, dan particle effects berlebihan.

> **Refocus adalah aplikasi anti-distraction. Desainnya sendiri tidak boleh menjadi distraksi.**

## 24. Accessibility

Minimum requirements:
- kontras memadai;
- jangan bergantung hanya pada warna;
- touch target cukup besar;
- mendukung system font scaling;
- timer dapat dibaca screen reader;
- icon penting memiliki semantic label;
- animation bukan satu-satunya cara menyampaikan informasi.

Contoh, jangan gunakan `🟢` sebagai satu-satunya indikator. Gunakan `● Protection Active` dengan warna sebagai supporting signal.

## 25. Dark & Light Theme

Refocus dirancang **dark-first**.

Gunakan semantic color tokens sehingga light theme dapat ditambahkan tanpa mengubah setiap widget secara manual.

Jangan mendefinisikan warna langsung tersebar di widget.

## 26. Design Tokens

Komponen Flutter sebaiknya menggunakan semantic tokens:

```dart
colorScheme.surface
colorScheme.onSurface
colorScheme.primary
colorScheme.error
```

Untuk state Refocus:
```text
idle
distracting
cooldown
locked
```

Hindari hard-coded color seperti:
```dart
Color(0xFFFBBF24)
```
yang tersebar di banyak widget.

## 27. Component Principles

Komponen utama:
```text
AppShell
StatusCard
TimerDisplay
ProtectedAppTile
SessionCounter
CooldownCard
LockCard
PermissionStatusTile
PrimaryButton
SecondaryButton
WarningOverlay
```

Setiap component harus memiliki satu tanggung jawab, menggunakan design tokens, tidak mendefinisikan style global sendiri, dapat digunakan kembali, dan tetap sederhana.

## 28. UX Copywriting

Bahasa Refocus harus singkat, tenang, langsung, dan tidak menghakimi.

### Gunakan
> Take a break.

> Protection is active.

> Your daily limit has been reached.

> Protection needs attention.

> Distraction limit reached.

### Hindari
> You failed.

> You wasted your day.

> Stop wasting your time!

> You're addicted.

> Don't be lazy.

## 29. Anti-Distraction Design Rules

### DO
- tampilkan informasi yang relevan;
- gunakan whitespace;
- gunakan satu primary action;
- gunakan warna secara semantic;
- kurangi visual noise;
- buat interaction path pendek.

### DON'T
- jangan menggunakan infinite scroll;
- jangan membuat feed;
- jangan menambahkan social engagement;
- jangan menggunakan streak sebagai motivasi utama;
- jangan membuat reward loop yang membuat pengguna terus membuka Refocus;
- jangan menggunakan animasi berlebihan;
- jangan menambahkan notification tanpa tujuan.

## 30. Product Mode Extensions

Design system harus dapat digunakan oleh:
```text
Refocus Personal
Refocus Family
Refocus School
```

### Personal
Fokus pada individual control, distraction timer, cooldown, statistics, dan focus sessions.

### Family
Fokus pada parent/child clarity, schedule, limits, dan device status. Jangan membuat interface terasa seperti surveillance dashboard.

### School
Fokus pada class session, managed devices, teacher controls, dan focus session status. Bedakan perangkat yang dikelola sekolah dari perangkat pribadi.

## 31. Privacy Visual Language

Refocus adalah privacy-first.

UI dapat menggunakan bahasa:
```text
Local-first
No account required
No messages
No passwords
No personal content
Open source
```

Namun setiap klaim harus sesuai dengan implementasi aktual. Jika arsitektur berubah, dokumentasi privacy juga harus diperbarui.

## 32. Responsive & Device Considerations

Target utama adalah Android smartphone.

Prioritas:
1. small phones;
2. standard Android phones;
3. large phones;
4. tablets sebagai progressive enhancement.

Layout harus dapat beradaptasi terhadap system font scaling, screen width, orientation jika didukung, display cutouts, dan system navigation.

## 33. Design Quality Checklist

### Visual
- [ ] Menggunakan design tokens.
- [ ] Spacing konsisten.
- [ ] Typography hierarchy jelas.
- [ ] Tidak ada gradient yang tidak diperlukan.
- [ ] Tidak ada decorative element yang tidak memiliki fungsi.

### UX
- [ ] User tahu kondisi aplikasi.
- [ ] Primary action jelas.
- [ ] Tidak ada langkah yang tidak perlu.
- [ ] Copy tidak menghakimi.
- [ ] State dapat dipahami tanpa bergantung pada warna.

### Accessibility
- [ ] Contrast memadai.
- [ ] Touch target memadai.
- [ ] Text scaling diperhatikan.
- [ ] Screen reader semantics tersedia untuk elemen penting.

### Privacy
- [ ] Tidak meminta permission yang tidak diperlukan.
- [ ] Penjelasan permission sesuai implementasi.
- [ ] Tidak ada data pribadi yang ditampilkan tanpa kebutuhan.

### Anti-Distraction
- [ ] Tidak ada infinite engagement loop.
- [ ] Tidak ada notification spam.
- [ ] Animation minimal.
- [ ] Screen membantu user kembali ke aktivitas utama.

## 34. Design Decision Summary

Refocus menggunakan prinsip:
```text
CALM
  ↓
CLEAR
  ↓
MINIMAL
  ↓
PRIVATE
  ↓
FOCUS
```

Desain tidak bertujuan membuat Refocus menjadi aplikasi yang paling menarik untuk dibuka.

> **Refocus should help you use your phone less, not make you use Refocus more.**

## 35. Source of Truth

Dokumen ini merupakan referensi utama untuk keputusan UI/UX Refocus.

Jika terjadi konflik:
```text
Product requirements
        ↓
Security / Privacy requirements
        ↓
Design System
        ↓
Individual component styling
```

Perubahan visual besar harus diperbarui kembali di `DESIGN.md` agar implementasi Flutter tetap konsisten.

---

**Refocus**

*Take back your attention.*
