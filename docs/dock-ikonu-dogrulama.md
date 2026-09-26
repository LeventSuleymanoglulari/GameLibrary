# Dock ikonu doğrulaması

26 Eylül 2026 tarihinde seçilen [yumuşak krem–kahverengi ikon](assets/oyun-kutuphanesi-ikon-yumusak.png), uygulamanın `AppIcon` varlığına eklendi. 16, 32, 128, 256 ve 512 punto için 1x/2x kayıtlar yedi PNG dosyasını kullanır. Dış alan şeffaftır.

## Kanıtlar

- Xcode 27 ile `xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' build`: **BUILD SUCCEEDED**.
- On macOS varlık kaydındaki PNG boyutları ve alfa kanalları `sips` ile doğrulandı.
- Derlenen uygulamanın `Info.plist` dosyasında `CFBundleIconFile = AppIcon`; `Contents/Resources/AppIcon.icns` mevcut.
- 64 piksel önizleme görsel olarak incelendi; kumanda ve tuşlar ayırt ediliyor.
- Yerel uygulama `--ui-testing` ile bellek deposu ve test anahtarı kullanılarak açıldı. Pencere erişilebilirlik ağacı incelendi; ⌘2 ile **Kütüphanem** sekmesine geçiş doğrulandı. Ardından test oturumu kapatıldı.
- `git diff --check`: başarılı.

Dock ekran görüntüsü alma aracı zaman aşımına uğradığından Dock üzerindeki görünüm ekran görüntüsüyle doğrulanamadı. Aşağıdaki görsel kaynak ikon önizlemesidir.

![Seçilen uygulama ikonu](assets/oyun-kutuphanesi-ikon-yumusak.png)

Yalnızca uygulama simgesi değişti; SwiftData şeması, RAWG erişimi ve kullanıcı verileri etkilenmez. [Üretim istemi](assets/oyun-kutuphanesi-ikon-yumusak-prompt.md).
