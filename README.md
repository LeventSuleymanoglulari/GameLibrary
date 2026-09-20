# Oyun Kütüphanesi

Oyunları, oynama durumlarını ve kişisel puanları tek yerde takip etmek için
planlanan bir PC masaüstü uygulaması.

## Proje belgeleri

- [Yol haritası](ROADMAP.md) ilk sürüme kadar izlenecek aşamaları ve
  tamamlanma ölçütlerini içerir.
- [Proje planı](docs/proje-plani.md) kapsamı, kullanım kurallarını, geliştirme
  adımlarını ve kabul ölçütlerini içerir.
- [Görsel anlatım](docs/oyun-kutuphanesi-gorsel.html) dört sekmeyi ve oyun
  kartlarını teknik olmayan kullanıcılar için açıklar. HTML dosyasını indirip
  tarayıcıda açın. GitHub dosya sayfası HTML'yi uygulama gibi çalıştırmaz.

![Dört sekme ve oyunların altındaki durum kutuları](docs/assets/oyun-kutuphanesi-onizleme.png)

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

Örnekteki 10 üzerinden puanlama temsilidir. Kesin puan ölçeği henüz seçilmemiştir.

## Projenin durumu

Depo proje planını içerir. Henüz uygulama kodu, bağımlılık dosyaları veya
çalıştırma, test ve paketleme komutları bulunmaz. Görsel anlatım bir taslaktır.

İşletim sistemi, masaüstü teknolojisi, veri saklama yöntemi ve puan ölçeği
[planın açık kararları](docs/proje-plani.md#uygulama-geliştirilmeden-önce-verilecek-kararlar)
arasındadır. Bunlar seçildiğinde kurulum ve geliştirme adımları eklenecektir.
