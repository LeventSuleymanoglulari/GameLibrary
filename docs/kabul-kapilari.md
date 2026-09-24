# Kabul kapıları

23 Eylül 2026, macOS 27.0 (26A428), Xcode 27.0, Apple Silicon. Bu kayıt üç açık kapının
bu makinede nereye kadar geldiğini tutar. Kapı, kanıtı yazılmadan kapanmış sayılmaz.

## Canlı RAWG ve gerçek kota

`docs/checks/verify-live-rawg.py` tek `GET /api/games` araması yapar. Anahtarı
`RAWG_API_KEY` ortamından okur. İstek adresini, anahtarı ve sonuç adını dosyaya yazmaz.
Kota başlığı olarak yalnızca `x-ratelimit-limit`, `x-ratelimit-remaining`,
`x-ratelimit-reset` ve `retry-after` saklanır.

Bu oturumda `RAWG_API_KEY` yoktu. Betik çıktısı `docs/evidence/live-rawg.json` içindedir
ve `accepted` alanı false. Canlı arama yapılmadı. Gerçek kalan kota ölçülmedi.
Kullanıcı Keychain kaydı bu kontrol için okunmadı.

Kapı açık kalır. Anahtar verilince aynı betik yeniden çalıştırılır.

## Tam erişilebilirlik

Katalog araması, sonuç seçimi ve kaynak bağlantısı için arayüz testi
`testKeyboardCatalogSelectionReachesSourceLink` geçti. `Command-N` ekleme bölmesini açar.
Arama alanına yazılan ad Return ile aranır. Seçilen sonuç Return ile kayda geçer.
Ayrıntıda `gameSourceLink` etiketi `RAWG kaynağında görüntüle` olarak okunur.
RAWG kaydının erişilebilirlik değeri `RAWG kataloğundan eklendi` içerir.
Sonuç düğmesinin görünür adı `Seç` kalır. Oyun adı erişilebilirlik ipucundadır.

VoiceOver konuşma imleci bu oturumda açılmadı. Bu yüzden tam VoiceOver kabulü
yazılmadı. Intel ve macOS 26 oturumu da yok.

## Kurulu Release uygulaması

`python3 scripts/package-macos.py` universal DMG ve ZIP üretti, imza ve yetki
kontrolünden geçti. Paket ad-hoc imzalıdır ve notarize değildir.
Çıkarılan `Game library.app`, `GAME_LIBRARY_ACCEPTANCE_ID` ile başlatıldı ve
çalışır kaldı. SwiftData dosyası kullanıcının kalıcı kütüphanesi yerine
uygulama kabının geçici dizininde `game-library-acceptance-<uuid>.store` olarak açıldı.

XCTest, paketdeki uygulamaya süreç kimliği alamadan bağlanamadı. Paket hata ayıklama
görevine izin vermez. Ayrı erişilebilirlik sürücüsü `docs/checks/verify-installed-release.swift`
bu süreçte güvenilir erişilebilirlik izni bulamadı ve kabul turunu başlatmadı.
Kurulu pencerede K1–K20 tıklama turu bu yüzden tamamlanmadı.

Kapı açık kalır. Sürücü, erişilebilirlik izni olan bir oturumda yeniden çalıştırılır.
