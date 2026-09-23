# 1.0 (1) — Yerel macOS önizlemesi

Tarih: 23 Eylül 2026. Bu paket ilk sürümün genel dağıtım onayı değildir.
Phase 6 otomatik katalog içe aktarma henüz tamamlanmadı.

## Kapsam

Dört filtreli tek raf penceresi, RAWG aramasıyla seçerek veya elle ekleme,
beş bağımsız durum, isteğe bağlı kişisel puan, yerel SwiftData kalıcılığı,
Keychain anahtarı ve çevrimdışı düzenleme. Toplu otomatik aktarım yoktur.
Şema veya kullanıcı verisi değişikliği yoktur. Yeni paketleme betiği kişisel
verileri içermez, genel yayın yapmaz ve Developer ID anahtarına erişmez.

## Doğrulama kaydı

Paketin kesin sürümü, commit'i, kirli çalışma ağacı bilgisi, Xcode/macOS
sürümleri, mimarileri ve SHA-256 değerleri yanındaki `manifest.json` içindedir.
İmza ad-hoc'tur; notarization yapılmamıştır. Ayrı lint yapılandırması yoktur;
`git diff --check` kullanılır.

23 Eylül koşusu: macOS 27.0, Xcode 27.0, Apple Silicon. 13 birim testi geçti.
Tam test komutu UI otomasyon modu başlatılırken zaman aşımına uğradı; sekiz
arayüz testi bu koşuda çalışmadı, başarılı sayılmadı. Önceki aşamanın arayüz
kanıtı yeni raf arayüzünün kabulü yerine geçmez. Kurulu Release uygulaması
kişisel veriye dokunmamak için başlatılmadı; ayrı test macOS hesabında kabul
gerekiyor. Paket kontrolü yalnızca çıkarma/kopyalama, imza ve metadata kanıtıdır.

Universal Release derlemesi, DMG bütünlüğü, DMG'den geçici kurulum kopyası ve
ZIP'ten çıkarılan uygulamanın imza/yetki/mimari kontrolleri geçti. Sandbox ve
giden ağ yetkileri açık, debugger erişimi kapalıdır. Eski şema geçişi ve
sentetik Keychain süreçler arası kontrolü geçti. `git diff --check` temizdir.
macOS 27 `hdiutil` için kullanımdan kaldırma uyarıları verdi; işlemler başarılı
tamamlandı. Paketleme Xcode 27'nin komut satırı araçlarını kullanır.

## RAWG koşulları — 23 Eylül 2026 incelemesi

[API sayfasındaki](https://rawg.io/apidocs) Free plan, kişisel/hobi ve ticari
olmayan kullanım, ayda 20.000 isteğe kadar kota ve verinin kullanıldığı
görünümlerden RAWG'ye bağlantı şartını bildiriyor. Aynı sayfanın altındaki
özet ve [API kullanım şartları](https://rawg.io/tos_api) ticari kullanım için
farklı bir ifade içeriyor. Ticari dağıtım izni varsayılmamalı; RAWG'den teyit
alınmalı. Veri yeniden dağıtımı yasakları nedeniyle paket katalog verisi
içermez. Her kullanıcı kendi anahtarıyla istek yapar.

Arama sonuçları, seçilen oyun, ithal oyun kartı ve ayrıntılardaki RAWG bağlantıları
korunur. Ücretsiz plan kullanımı sınırsız veya kesintisiz servis garantisi değildir.
Phase 6'nın toplu aktarımı için ayrıca kota ve kullanım uygunluğu değerlendirilmelidir.

## Dağıtım öncesi açık kapılar

- Phase 6; ilk sürüm tamamlanma ölçütü.
- Kurulan Release uygulamasında, ayrı test macOS hesabıyla K1–K20'nin tamamı.
  Debug testlerinin geçmesi kurulu Release kabulü sayılmaz.
- Gerçek RAWG anahtarıyla servis kabulü; gerçek kullanıcı anahtarı ve sistem
  günlükleri üzerinde gizlilik incelemesi.
- Tam klavye/VoiceOver kabulü; Intel ve minimum macOS 26 kontrolü.
- Developer ID imzası, notarization ve indirilen paketin Gatekeeper kabulü.

Testler kullanıcının gerçek kitaplığı veya anahtarıyla çalıştırılmamalıdır.
