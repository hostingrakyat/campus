# Mahasigma Simulator — Godot project

## Struktur

```
data/            curriculum.json (3 prodi × 144 SKS), events.json (cerita), endings.json (10 ending)
scripts/core/    sim.gd — semua aturan game (murni, tanpa node, bisa dites headless)
                 minigames.gd — konten & bonus mini-game kegiatan
scripts/autoload Data (konten & angka balancing), Game (run aktif + save), Meta (diamond, koleksi, galeri),
                 Loc (dual subtitle), Ads (AdMob facade), Iap (Billing facade)
scripts/world/   campus_world.gd (diorama kampus prosedural), vinyl_character.gd (karakter), mat.gd,
                 director.gd + stages.gd (adegan & cutscene), explorer.gd (mode Jelajah: gerak, tabrakan, item)
scripts/ui/      main.gd (navigasi/modal) + semua layar & popup, kit.gd (theme & widget)
tests/           sim_bot (balancing headless), autoplay (main lewat UI asli)
tools/           gen_events.py (sumber cerita), shot.sh (screenshot), check_scripts.sh
```

Musik dibangkitkan dari kode (butuh `numpy` + `ffmpeg`): `python3 tools/gen_music.py`.
SFX di `assets/audio/sfx` berasal dari paket Kenney (CC0, lisensi disertakan).

Semua teks berbentuk pasangan `{"id": ..., "en": ...}`. Cerita ditulis di `tools/gen_events.py`
lalu dibangkitkan ke `data/events.json`:

```bash
python3 tools/gen_events.py
```

## Menjalankan

```bash
godot --path game                 # editor / run di desktop (window 432×768, viewport 720×1280)
godot --path game --headless --import   # wajib setelah menambah file class_name baru
```

## Tes

```bash
# Balancing: ratusan run otomatis per strategi × prodi, plus unit test aturan
godot --path game --headless res://tests/sim_bot.tscn

# Autoplay: memainkan UI asli dari UKT sampai ending (nangkap runtime error)
AUTOPLAY_SEED=3 godot --path game --headless -- --shot=autoplay

# Mode Jelajah: sentuhan sintetis (joystick, multitouch A), tembok, koin, kucing, gol, kembali
godot --path game --headless -- --shot=exploretest

# Video demo ±40 dtk dengan audio (Movie Maker Godot)
xvfb-run godot --path game --write-movie /tmp/demo.avi --fixed-fps 30 -- --shot=demo

# Screenshot satu layar (butuh xvfb): title create ukt ukt_phk krs war week weekrun settings event picker
# shop wardrobe jobs academic khs ending_<id> gallery note icon explore mg_<aksi>[:<job>] (mis. mg_ujian, mg_kerja:barista)
game/tools/shot.sh week /tmp/shots
```

## Build Android (APK & AAB)

Butuh: export templates Godot 4.7.2, Android SDK (build-tools 35+, platform 36), JDK 17+, internet saat build pertama
(Gradle mengunduh SDK AdMob & Billing). Atur `android_sdk_path` dan `java_sdk_path` di Editor Settings.
Kedua preset memakai **Gradle build** (wajib untuk plugin AdMob & Billing, lihat `docs/MONETIZATION.md`).

## Build AAB (Play Store)

Preset **"Android Play (AAB)"**: Gradle build, arm64-v8a + armeabi-v7a, target API 36, ditandatangani dengan
upload key. Keystore ada di `keystore/` di root repo (di-gitignore, **jangan di-commit, backup offline**):
`keystore/mahasigma-release.keystore` (PKCS12, alias `mahasigma`) dan `keystore/keystore.properties` (password).

Sekali per clone, pasang Gradle build template (Editor: Project > Install Android Build Template, atau manual):

```powershell
Expand-Archive "$env:APPDATA\Godot\export_templates\4.7.2.stable\android_source.zip" game\android\build -Force
Set-Content game\android\.build_version "4.7.2.stable" -NoNewline
New-Item game\android\build\.gdignore -ItemType File -Force
```

Lalu build AAB (Play Store) + APK (sideload), keduanya ditandatangani upload key
(naikkan `version/code` di kedua preset setiap upload):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build_android.ps1 -Godot "C:\path\Godot_v4.7.2-stable_win64.exe"
# hasil: build\MahasigmaSimulator-v<versi>.aab dan .apk
```

Di Play Console aktifkan **Play App Signing**; keystore ini jadi *upload key* (kalau hilang bisa minta reset ke Google,
tapi tetap simpan cadangannya).

Ikon UI: `python tools/gen_icons.py` mengunduh SVG Lucide (ISC) ke `data/icons.json`; tombol mendapat ikon otomatis
dari teksnya (`Kit.AUTO_ICONS`), `Kit.chip(..., icon)`, `Kit.icon_label`, `Kit.set_icon`, `Kit.plain` untuk tanpa ikon.

## Konten aktivitas & scene

`python3 tools/gen_activities.py` membangkitkan `data/activities.json` (kabar mingguan, varian aktivitas, arahan scene).
Set interior dibangun di `scripts/world/stages.gd`, perabot di `props.gd`, penataan aktor/kamera di `director.gd`,
UI cutscene event di `scripts/ui/cutscene.gd`. Render satu scene: `tools/shot.sh stage_kuliah:presentasi`,
satu cutscene: `SHOT_FRAMES=150 tools/shot.sh cutscene_ibu_telpon`. Tes scroll sentuh: `--shot=scrolltest`.
