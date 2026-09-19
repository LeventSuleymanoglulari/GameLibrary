# Oyun kütüphanesi proje planı

Bu belge, kişisel oyun koleksiyonunu takip etmek için planlanan PC masaüstü
uygulamasının kapsamını tanımlar. Uygulama henüz geliştirilmemiştir.
Kullanıcının belirttiği gereksinimler ile aşağıdaki öneriler ayrı tutulmuştur.

[Görsel anlatım](oyun-kutuphanesi-gorsel.html) aynı planı sekmeler ve örnek oyun
kartlarıyla açıklar. HTML dosyasını indirip tarayıcıda açabilirsiniz.

## İstenen deneyim

Kullanıcı sahip olduğu, istediği, oynayacağı, oynadığı ve bitirdiği oyunları
tek yerde görür. Oyunlara kişisel puan verir. Oyunun altındaki küçük kutular,
o oyuna hangi durumların uygulandığını gösterir.

### Sekmeler

Uygulamada şu dört sekme bulunur.

| Sekme | İçerik | Kartı görünür yapan bilgi |
| --- | --- | --- |
| Tüm Oyunlar | Uygulamaya eklenen bütün oyunlar | Oyunun kayıtlı olması |
| Kütüphanem | Kullanıcının sahip olduğu oyunlar | Kütüphane |
| Wishlist | Kullanıcının istek listesindeki oyunlar | Wishlist |
| Oynanacak | Kullanıcının daha sonra oynamayı planladığı oyunlar | Oynanacak |

Tüm Oyunlar bir mağazadaki veya dünyadaki bütün oyunlar anlamına gelmez.
Sekmeler aynı kayıtlı oyunların farklı görünümleridir. Örneğin Kütüphane ve
Oynanacak olarak işaretlenen bir oyun, Tüm Oyunlar, Kütüphanem ve Oynanacak
sekmelerinde görünür. Her sekme için ayrı oyun kaydı oluşturulmaz.

### Oyun kartındaki kutular

| Kutu | Anlamı |
| --- | --- |
| Kütüphane | Bu oyuna sahibim. |
| Wishlist | Bu oyunu istek listeme ekledim. |
| Oynanacak | Bu oyunu daha sonra oynamak istiyorum. |
| Oynandı | Bu oyunu oynadım. Bitirmiş olmam gerekmiyor. |
| Bitti | Bu oyunu tamamladım. |
| Puan | Bu oyuna verdiğim kişisel değerlendirme. |

Oyunun adı kartta görünür. Yalnızca uygulanmış durumların kutuları adın altında
yer alır. Puan verilmemişse Puan kutusu görünmez. Hiçbir durumu seçilmemiş oyunda
yalnızca oyun adı görünür. Durum kutuları birden fazla seçimi gösterebilir.
Oynandı, Bitti ve Puan için ayrı sekme açılmaz.

Örnek kartlar şöyle görünür. Oyun adları ve puanlar yalnızca örnektir.

```text
Hades II
[Wishlist] [Oynanacak]

Hollow Knight
[Kütüphane] [Oynandı] [Bitti] [Puan: 9/10]
```

Hades II örneği Tüm Oyunlar, Wishlist ve Oynanacak sekmelerinde görünür.
Hollow Knight örneği Tüm Oyunlar ve Kütüphanem sekmelerinde görünür.

## İlk sürüm için önerilen çalışma kuralları

Bu bölümdeki kararlar planlama önerisidir. Kullanıcı tarafından kesinleştirilmiş
istekler değildir. Geliştirmeye başlamadan önce açık kararlarla birlikte netleştirilir.

- Açılışta Tüm Oyunlar sekmesi seçilir.
- Oyunlar ilk sürümde adları yazılarak elle eklenir. Boş oyun adı kabul edilmez.
- Kullanıcı bir oyunun durumlarını ekler veya kaldırır. Kart ve sekmeler aynı
  kayıt üzerinden güncellenir. Sekmeden çıkmak oyun kaydını silmez.
- Durumlar bağımsız seçilir. Bitti seçimi otomatik olarak Oynandı eklemez veya
  Oynanacak kaldırmaz. Kütüphane seçimi de Wishlist durumunu otomatik kaldırmaz.
  Böylece tekrar oynanacak bir oyunda Bitti ve Oynanacak birlikte bulunabilir.
- Puan isteğe bağlıdır. Başlangıç önerisi 1 ile 10 arasında tam sayıdır.
  Kullanıcı puanı değiştirebilir veya kaldırabilir. Puan için bitirme şartı önerilmez.
- Kayıtlar uygulama kapatılıp açıldığında korunur. Saklama yöntemi henüz seçilmemiştir.
  Kayıt başarısız olursa uygulama başarı göstermez ve kullanıcıya hata bildirir.
- Boş sekmede açıklayıcı bir mesaj görünür. Örneğin Wishlist boşsa
  "İstek listende henüz oyun yok" yazısı gösterilir.
- Sekmeler ve durum düzenleme kontrolleri klavyeyle kullanılabilir.
  Seçimler yalnızca renkle değil, yazıyla da anlaşılır.

Bu öneriler otomatik bir satın alma veya oynama sırası dayatmaz.
Kullanıcı bir oyunu doğrudan Kütüphane veya Oynandı olarak işaretleyebilir.

## Kullanım örneği

1. Kullanıcı Hades II adlı oyunu ekler. Oyun Tüm Oyunlar sekmesinde görünür.
2. Wishlist ve Oynanacak durumlarını seçer. Kartın altında iki kutu görünür.
3. Wishlist sekmesine geçtiğinde aynı oyunu görür.
4. Oyuna sahip olduğunda Kütüphane durumunu ekler. Oyun Kütüphanem'de de görünür.
5. İsterse Wishlist durumunu kaldırır. Diğer durumlar korunur.
6. Oyunu oynadıktan sonra Oynandı, tamamladıktan sonra Bitti durumunu seçer.
7. İsterse kişisel puanını verir. Kartta Puan kutusu görünür.

Bu örneğin adımları zorunlu bir sıra değildir. Bağımsız durum davranışı
ve puanlama, önceki bölümdeki önerilere dayanır.

## Uygulama geliştirilmeden önce verilecek kararlar

| Karar | Şu anki durum | Kararın etkisi |
| --- | --- | --- |
| İşletim sistemi | PC hedefi belli. Windows sürümleri, macOS ve Linux desteği açık. | Kurulum ve paketleme kapsamı |
| Masaüstü teknolojisi | Seçilmedi. | Geliştirme ve dağıtım araçları |
| Oyun ekleme | Elle ekleme önerildi. Katalog kaynağı istenmedi. | İnternet ve dış servis gereksinimi |
| Veri saklama | Kalıcılık önerildi. Yerel dosya, veritabanı veya bulut seçilmedi. | Çevrimdışı kullanım, yedekleme ve hesap ihtiyacı |
| Puan ölçeği | 1 ile 10 arasında tam sayı önerildi. | Puan girişi, doğrulama ve gösterim |
| Durum ilişkileri | Bağımsız seçim önerildi. | Bitti, Oynandı, Wishlist ve Kütüphane arasındaki otomatik değişiklikler |

İlk plan Steam veya Epic bağlantısı, mağaza kataloğu, arkadaş sistemi, herkese
açık profil, oyun başlatma ya da cihazlar arası eşitleme taahhüt etmez.
Bunlar ayrıca istenirse kapsam ve veri kullanımı değerlendirilir.

## Geliştirme sırası

| Adım | Teslim edilecek sonuç | Tamamlanma ölçütü |
| --- | --- | --- |
| 1. Kararları netleştir | Hedef sistem, puan ölçeği, durum kuralları ve saklama kararı | Açık kararlar kaydedilmiş olur. |
| 2. Oyun listesini hazırla | Oyun ekleme, dört sekme ve oyun kartları | Eklenen oyun doğru sekmelerde görünür. |
| 3. Durum ve puan düzenlemeyi ekle | Seçimleri yansıtan kutular ve kişisel puan | Değişiklikler bütün sekmelerde aynı kayda yansır. |
| 4. Kalıcılığı ve hataları doğrula | Kapatıp açınca korunan kayıtlar, boş durum ve hata mesajları | Veri kaybı ve başarısız kayıt senaryoları kontrol edilir. |
| 5. Masaüstü sürümünü hazırla | Seçilen sistemde kurulabilir uygulama | Kurulum ve aşağıdaki kabul senaryoları gerçek uygulamada geçer. |

Takvim ve efor, ilk adımdaki kararlar verilmeden tahmin edilmemiştir.

## Kabul senaryoları

Bu senaryolar gelecekteki uygulama içindir. Bu dokümantasyon değişikliğiyle
geçtikleri iddia edilmez. Öneriye bağlı senaryolar, ilgili karar kabul edilirse uygulanır.

| No | İşlem | Beklenen sonuç | Dayanak |
| --- | --- | --- | --- |
| K1 | Sekmeleri görüntüle. | Tam olarak Tüm Oyunlar, Kütüphanem, Wishlist ve Oynanacak görünür. | İstenen kapsam |
| K2 | Durumsuz bir oyun görüntüle. | Oyun Tüm Oyunlar'da görünür. Altında boş durum veya puan kutusu bulunmaz. | İstenen kapsam |
| K3 | Oyuna Wishlist ve Oynanacak ekle. | İki kutu görünür. Aynı oyun Tüm Oyunlar, Wishlist ve Oynanacak'ta listelenir. | İstenen kapsam |
| K4 | Oyuna Kütüphane ekle. | Kütüphanem'de görünür. Kart kutusunun adı Kütüphane olur. | İstenen kapsam |
| K5 | Oyuna Oynandı ve Bitti ekle. | Kartta iki kutu görünür. Yeni sekme oluşmaz. | İstenen kapsam |
| K6 | Puan ver, değiştir ve kaldır. | Kart güncel puanı gösterir. Puan kaldırılınca kutusu kaybolur. | Kapsam ve düzenleme önerisi |
| K7 | Wishlist durumunu kaldır. | Oyun Wishlist'ten çıkar. Tüm Oyunlar'da kalır ve diğer durumları korunur. | Düzenleme önerisi |
| K8 | Bitti ve Oynanacak durumlarını birlikte seç. | İkisi de korunur. Oynandı otomatik eklenmez. | Bağımsız durum önerisi |
| K9 | Boş ad veya ölçek dışı puan kaydetmeyi dene. | Geçersiz bilgi kaydedilmez. Kullanıcı neyi düzeltmesi gerektiğini görür. | Giriş doğrulama önerisi |
| K10 | Uygulamayı kapatıp yeniden aç. | Oyunlar, durumlar ve puanlar korunur. | Kalıcılık önerisi |
| K11 | Kaydetme başarısızlığını ve boş sekmeyi görüntüle. | Hata başarı gibi gösterilmez. Boş liste açıklanır. | Hata ve boş durum önerisi |
| K12 | Sekmeleri ve düzenleme kontrollerini klavyeyle kullan. | Odak görünür. İşlemler fare olmadan tamamlanır. | Erişilebilirlik önerisi |

## Görselin sınırları

Görsel, 1280 × 720 boyutunda bir akış şeması ve örnek kartlardan oluşur.
Teknik olmayan okuyucular için hazırlanmıştır. Nihai ekran tasarımı veya
çalışan uygulama değildir. Puan temsili, görseldeki oyunlar örnektir.

HTML dosyasında stil ve çizim birlikte bulunur. Yazı tipleri internet varsa
Google Fonts üzerinden yüklenir. Çevrimdışı durumda sistem yazı tipleri kullanılır.
Veri saklama ve teknoloji ayrıntıları görselin dışında, bu planda tutulmuştur.
