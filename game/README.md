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

## Build APK

Butuh: export templates Godot 4.7.2, Android SDK (platform-tools, build-tools 35, platform 35), JDK 17+.
Atur `export/android/android_sdk_path`, `java_sdk_path`, dan debug keystore di Editor Settings.

```bash
# Debug
godot --path game --headless --export-debug "Android" ../build/MahasigmaSimulator-debug.apk

# Release (keystore lewat env, jangan commit keystore)
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/path/release.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=alias \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=*** \
godot --path game --headless --export-release "Android" ../build/MahasigmaSimulator.apk
```

APK sampel v0.1.0 ditandatangani dengan **debug keystore**, hanya untuk dicoba (sideload).
Untuk Play Store: buat upload keystore sendiri, aktifkan Gradle build (wajib untuk plugin AdMob/Billing),
dan ekspor sebagai **AAB** (Play memecah per-ABI sehingga unduhan jauh lebih kecil dari APK 53 MB).

## Konten aktivitas & scene

`python3 tools/gen_activities.py` membangkitkan `data/activities.json` (kabar mingguan, varian aktivitas, arahan scene).
Set interior dibangun di `scripts/world/stages.gd`, perabot di `props.gd`, penataan aktor/kamera di `director.gd`,
UI cutscene event di `scripts/ui/cutscene.gd`. Render satu scene: `tools/shot.sh stage_kuliah:presentasi`,
satu cutscene: `SHOT_FRAMES=150 tools/shot.sh cutscene_ibu_telpon`. Tes scroll sentuh: `--shot=scrolltest`.
