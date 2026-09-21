# Oyun Kütüphanesi

Oyunları, oynama durumlarını ve kişisel puanları tek yerde takip etmek için
geliştirilen yerel bir macOS masaüstü uygulaması.

İlk sürüm macOS 26 ve sonrası için SwiftUI ve SwiftData ile geliştirilecektir.
Ürün ve davranış seçimleri [ilk sürüm kararlarında](docs/ilk-surum-kararlari.md)
ayrıntılı olarak kayıtlıdır.

Oyun ekleme akışı, ücretsiz RAWG API'sinde arama yapıp seçilen oyunu
içe aktarmaktır. Katalogda bulunamayan oyunlar ve bağlantı sorunları için
**Elle ekle** her zaman kullanılabilir. Kaydedilmiş oyunlar çevrimdışı çalışır.
RAWG'nin ücretsiz kişisel kullanım planı API anahtarı, istek kotası ve kaynak
bağlantısı gerektirir. [Erişim ve yedek yol kuralları](docs/ilk-surum-kararlari.md#ücretsiz-katalog-ve-erişim)
ilk sürüm kararlarında açıklanmıştır.

## Geliştirme ortamı

Xcode 27 veya sonrası ve macOS 26 SDK'sı gerekir. Projeyi Xcode ile açmak için
`Game library/Game library.xcodeproj` dosyasını açın; **Game library** şemasını
ve **My Mac** hedefini seçip çalıştırın.

Komut satırından derleme:

```sh
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' build
```

Odaklı otomatik kontrolleri çalıştırmak için:

```sh
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' '-only-testing:Game libraryTests' test
```

Tüm testleri, native arayüz kontrolleriyle birlikte çalıştırmak için aynı
komuttan `-only-testing` seçeneğini kaldırın. Arayüz testleri açık bir macOS
oturumu gerektirir.

## Oyun ekle

1. Araç çubuğundan **Oyun Ekle**'yi açın. Katalog kullanmak için kendi RAWG
   anahtarınızı ayarlardan kaydedin. Anahtar yalnızca Keychain'de saklanır.
2. Oyun adını yazıp **Ara**'yı seçin. Arama sonuçları henüz yerel kayıt değildir.
3. Doğru sonucu seçip **Ekle** ile onaylayın. Sonraki sayfa yalnızca kullanıcı
   istediğinde yüklenir.
4. Katalog kullanılamıyorsa **Elle ekle** bölümündeki adı doğrulayıp kaydedin.
   Bu yol anahtar ve internet gerektirmez.

Aynı RAWG kimliği mevcut kaydı açar. Aynı adlı farklı bir oyun için ayrı kayıt
onayı gerekir. Yerel kayıt başarısızsa form açık kalır ve yeniden denenebilir.

## Proje belgeleri

- [Yol haritası](ROADMAP.md) ilk sürüme kadar izlenecek aşamaları ve
  tamamlanma ölçütlerini içerir.
- [Proje planı](docs/proje-plani.md) kapsamı, kullanım kurallarını, geliştirme
  adımlarını ve kabul ölçütlerini içerir.
- [Görsel anlatım](docs/oyun-kutuphanesi-gorsel.html) API'den içe aktarmayı,
  elle ekleme yedek yolunu, dört sekmeyi ve oyun kartlarını açıklar. HTML dosyasını indirip
  tarayıcıda açın. GitHub dosya sayfası HTML'yi uygulama gibi çalıştırmaz.

![API'den oyun içe aktarma ve elle ekleme yedek yolu](docs/assets/oyun-kutuphanesi-onizleme.png)

## Dört sekme

| Sekme | Gösterdiği oyunlar |
| --- | --- |
| Tüm Oyunlar | Uygulamaya eklenen bütün oyunlar |
| Kütüphanem | Kütüphane olarak işaretlenen, sahip olunan oyunlar |
| Wishlist | İstek listesine eklenen oyunlar |
| Oynanacak | Daha sonra oynanması planlanan oyunlar |

Bir oyun, ilgili olduğu birden fazla sekmede görünebilir.
**Oynandı**, **Bitti** ve **Puan** oyun kartındaki bilgilerdir; ayrı sekmeler değildir.

## Oyun kartları

Oyunun altında yalnızca uygulanmış durumlar ayrı kutular halinde gösterilir.
Puan verilmişse puan da görünür. Uygulanmamış durumlar için boş kutu gösterilmez.

```text
Hollow Knight
[Kütüphane] [Oynandı] [Bitti] [Puan: 9/10]

Hades II
[Wishlist] [Oynanacak]
```

Puan isteğe bağlıdır ve 1 ile 10 arasında tam sayıdır. Örnekteki puan temsilidir.

## Projenin durumu

Native macOS uygulamasında katalogdan veya elle oyun eklenebilir. **Tüm Oyunlar**,
**Kütüphanem**, **Wishlist** ve **Oynanacak** aynı oyun kayıtlarının dört
görünümüdür. Bir oyun açılarak beş bağımsız durum düzenlenebilir; uygulanan
durumlar ve isteğe bağlı 1–10 kişisel puan kartta görünür. Görsel anlatım bir
taslaktır; çalışan uygulama değildir.

2. aşamanın doğrulama sonuçları ve sınırları
[doğrulama kaydında](docs/asama-2-dogrulama.md) bulunur.
