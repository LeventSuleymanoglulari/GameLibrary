# macOS paketleme ve kurulum

## Yerel önizleme

macOS 26 veya sonrası gerekir. Paket Apple Silicon ve Intel kodu içerir.
Intel ve macOS 26 üzerinde ayrıca kabul testi yapılmadan bu hedeflerde
doğrulandığı iddia edilmez. Üretmek için Xcode 27 ve Python 3 gerekir:

```sh
python3 scripts/package-macos.py
```

Betik yeni `dist/preview-<UTC zamanı>/` dizininde Release DMG ve ZIP,
`SHA256SUMS`, `manifest.json` ve derleme günlüğü oluşturur. Eski çıktıları
ezmez. DMG'yi salt okunur bağlar, uygulamayı geçici kurulum konumuna kopyalar,
ZIP'i ayrı çıkarır ve ikisinin imzasını, mimarilerini, minimum işletim sistemi
sürümünü ve sandbox/ağ yetkilerini kontrol eder. Uygulamayı başlatmaz;
kullanıcının koleksiyonunu ve Keychain kaydını değiştirmez.

Paket **ad-hoc imzalı yerel önizlemedir**, Developer ID imzalı/notarize edilmiş
genel dağıtım değildir. Uzak bir makineye indirildiğinde Gatekeeper tarafından
engellenebilir. Gatekeeper'ı kapatmayın veya karantina niteliğini silmeyin.
Güvenilir dağıtım hazır değilse kaynak projeyi Xcode'da derleyin.

## Kurulum ve çalıştırma

1. Paket dizininde `shasum -a 256 -c SHA256SUMS` ile bütünlüğü doğrulayın.
2. DMG'yi açın, `Game library.app` dosyasını Applications kısayoluna sürükleyin.
   Mevcut kurulum varsa önce uygulamayı kapatın; değiştirme kararını kendiniz verin.
3. Disk imajını çıkarın; uygulamayı Applications içinden açın.
4. **Oyun Ekle** ile elle kayıt yapabilirsiniz. RAWG araması için kendi
   anahtarınızı uygulamadaki güvenli anahtar formuna girin; terminale veya
   hata raporuna yazmayın. Katalog sonuçları onayla eklenir.
5. Dört filtre arasında geçiş için ⌘1–⌘4 kullanın. Oyunu seçerek bağımsız
   durumları ve isteğe bağlı 1–10 puanı düzenleyin. Kapatıp açınca kayıtları
   doğrulayın; önceden eklenmiş oyunlar internet olmadan kullanılabilir.

ZIP alternatifi yalnızca uygulamayı içerir; çıkarıp Applications'a kopyalayın.
Güncelleme aynı uygulama kimliğini (`Game.Game-library`) korur. Paket koleksiyon
veritabanı veya hazır API anahtarı içermez. Uygulamayı Çöp'e taşımak koleksiyonu
ve Keychain anahtarını otomatik silmez. Veri temizleme/göç betiği çalıştırılmaz.

## Genel dağıtıma geçiş

Bu betik yayınlama yapmaz. Önce Phase 6 ve sürüm notlarındaki kabul kapıları
tamamlanmalı, dağıtım yetkisi alınmalıdır. Ardından Xcode Organizer ile
Developer ID imzalı, hardened runtime etkin bir archive dışa aktarılmalı;
Apple notarization tamamlanıp bilet eklenmeli ve son paket temiz bir Mac'te
Gatekeeper ile doğrulanmalıdır. Bu işlem Apple Developer hesabı ve ilgili
imzalama yetkisi gerektirir. Kimlik bilgilerini depoya koymayın.

Kaynaklar: [Apple Developer ID](https://developer.apple.com/developer-id/) ve
[Xcode dağıtım kılavuzu](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases).
