# Dock ikonu doğrulaması

26 Eylül 2026 tarihinde seçilen krem–kahverengi kumanda tasarımı uygulamanın `AppIcon` varlığına eklendi. 16, 32, 128, 256 ve 512 punto için 1x/2x kayıtlar yedi PNG dosyasını kullanır.

## macOS boyut düzeltmesi

Önceki PNG kendi yuvarlatılmış çerçevesini ve şeffaf dış boşluğunu içeriyordu. Çalışan uygulama için macOS'un döndürdüğü ikonda bu şekil ikinci bir sistem çerçevesinin içinde küçülmüş görünüyordu. [Güncel kaynak](assets/oyun-kutuphanesi-ikon-tam-kare.png) opak zemini tüm kareye yayar; macOS köşe maskesini ve dış boşluğu kendisi uygular.

## Kanıtlar

- Xcode 27 ile `xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' build`: **BUILD SUCCEEDED**.
- On macOS varlık kaydındaki PNG boyutları ve opaklıkları `sips` ile doğrulandı.
- Derlenen uygulamanın `Info.plist` dosyasında `CFBundleIconFile = AppIcon`; `Contents/Resources/AppIcon.icns` mevcut.
- İlk doğrulamada uygulama `--ui-testing` ile bellek deposu ve test anahtarı kullanılarak açıldı; ⌘2 ile **Kütüphanem** sekmesine geçiş doğrulandı.
- Boyut düzeltmesinden sonra uygulama ve Dock yeniden başlatıldı, Launch Services kaydı yenilendi. Çalışan uygulamanın `NSRunningApplication.icon` çıktısı PNG olarak kaydedilip incelendi: krem zemin sistem çerçevesini dolduruyor, ikinci iç çerçeve yok.
- `git diff --check`: başarılı.

Aşağıdaki görsel ekran görüntüsü değil, macOS'un çalışan uygulama için döndürdüğü ikon görüntüsüdür. Dock ekran görüntüsü aracı önceki denemelerde zaman aşımına uğradı.

![macOS tarafından işlenmiş uygulama ikonu](assets/oyun-kutuphanesi-ikon-macos.png)

Yalnızca uygulama simgesi değişti; SwiftData şeması, RAWG erişimi ve kullanıcı verileri etkilenmez. [Üretim istemi](assets/oyun-kutuphanesi-ikon-tam-kare-prompt.md).
