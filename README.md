# Oyun Kütüphanesi

Oyunları, oynama durumlarını ve kişisel puanları tek yerde takip etmek için
planlanan bir masaüstü uygulaması.

## İlk sürümün kapsamı

- **Tüm Oyunlar:** Eklenen bütün oyunları gösterir.
- **Wishlist (İstek Listesi):** İlgilenilen oyunları listeler.
- **Oynanacak:** Daha sonra oynanması planlanan oyunları listeler.
- **Kütüphane:** Kullanıcının sahip olduğu oyunları listeler.
- **Oynandı:** Oynanmış oyunları listeler.
- **Bitti:** Tamamlanan oyunları listeler.
- **Puanlama:** Kullanıcı oyunlara kişisel puan verebilir ve puanını değiştirebilir.

Bu listeler uygulamada sekmeler olarak yer alır. Varsayılan sekme **Tüm Oyunlar** olur.
Bir oyun, ilgili olduğu birden fazla sekmede görünebilir.

## Oyun kartları

Her oyun kartında oyunun adı yer alır. Oyunun altında yalnızca o oyuna uygulanmış
durumlar ayrı kutular halinde gösterilir. Puan verilmişse puan da burada görünür;
uygulanmamış durumlar ve verilmemiş puan için boş kutu gösterilmez.

Örnek:

```text
Hollow Knight
[Kütüphane] [Oynandı] [Bitti] [Puan: 9/10]

Hades II
[Wishlist] [Oynanacak]
```

Örnekteki 10 üzerinden puanlama temsili olup nihai puan ölçeği henüz belirlenmemiştir.

## Projenin durumu

Bu depo şu anda yalnızca proje hazırlığını içerir. Henüz uygulama kodu,
bağımlılık dosyaları veya çalıştırma, test ve paketleme komutları bulunmaz.
Önceki Create React App açıklamaları mevcut bir uygulamayı temsil etmiyordu.

Hedef bir masaüstü uygulamasıdır. Desteklenecek işletim sistemleri, masaüstü
teknolojisi, verilerin saklanma yöntemi ve puan ölçeği uygulama geliştirilmeden
önce belirlenecektir. Teknoloji seçildikten sonra kurulum, geliştirme, test ve
masaüstü paketleme adımları bu belgeye eklenecektir.
