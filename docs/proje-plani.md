# Oyun kütüphanesi proje planı

Bu belge, kişisel oyun koleksiyonunu takip etmek için planlanan macOS masaüstü
uygulamasının kapsamını tanımlar. İlk sürüm kararları
[ayrı belgede](ilk-surum-kararlari.md) kayıtlıdır.

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

## İlk sürüm çalışma kuralları

Bu bölümdeki kurallar ilk sürüm için kesinleştirilmiştir.

- Açılışta Tüm Oyunlar sekmesi seçilir.
- Oyun eklemenin öncelikli yolu ücretsiz RAWG API'sinde arama yapıp seçilen
  oyunu içe aktarmaktır. Sonuç yalnızca kullanıcı onayı ve başarılı yerel
  kayıt sonrasında Tüm Oyunlar'a eklenir.
- Otomatik katalog, kullanıcının başlattığı ayrı bir içe aktarmadır. Oyunlar
  tek tek onaylanmadan Tüm Oyunlar'a kaydedilir. Arama ve elle ekleme kullanılabilir kalır.
  Arka planda kendiliğinden katalog indirme yapılmaz.
- **Elle ekle** her zaman görünür. Sonuç bulunamaması, anahtar eksikliği,
  çevrimdışı kullanım ve API hatalarında yedek yoldur. Aranan ad forma taşınır;
  boş veya yalnızca boşluk içeren ad kabul edilmez.
- API araması kişisel durumları ve puanı doldurmaz. Aynı kaynak ve dış kimlik
  yeniden içe aktarılırsa mevcut kayıt açılır; durumlar ve puan korunur.
- Kaydedilmiş oyunlar, durum ve puan düzenleme ile elle ekleme çevrimdışı
  çalışır. API araması internet ve Keychain'de ya da derlemede sağlanan RAWG
  anahtarını gerektirir.
- Kullanıcı bir oyunun durumlarını ekler veya kaldırır. Kart ve sekmeler aynı
  kayıt üzerinden güncellenir. Sekmeden çıkmak oyun kaydını silmez.
- Durumlar bağımsız seçilir. Bitti seçimi otomatik olarak Oynandı eklemez veya
  Oynanacak kaldırmaz. Kütüphane seçimi de Wishlist durumunu otomatik kaldırmaz.
  Böylece tekrar oynanacak bir oyunda Bitti ve Oynanacak birlikte bulunabilir.
- Puan isteğe bağlıdır ve 1 ile 10 arasında tam sayıdır.
  Kullanıcı puanı değiştirebilir veya kaldırabilir. Puan için bitirme şartı önerilmez.
- Kayıtlar uygulama kapatılıp açıldığında SwiftData'nın yerel deposunda korunur.
  Kayıt başarısız olursa uygulama başarı göstermez ve kullanıcıya hata bildirir.
- Boş sekmede açıklayıcı bir mesaj görünür. Örneğin Wishlist boşsa
  "İstek listende henüz oyun yok" yazısı gösterilir.
- Sekmeler ve durum düzenleme kontrolleri klavyeyle kullanılabilir.
  Seçimler yalnızca renkle değil, yazıyla da anlaşılır.

Bu kurallar otomatik bir satın alma veya oynama sırası dayatmaz.
Kullanıcı bir oyunu doğrudan Kütüphane veya Oynandı olarak işaretleyebilir.

Sağlayıcı koşulları, anahtar saklama, veri alanları, aynı adlı oyunlar ve hata
davranışı [içe aktarma sözleşmesinde](ilk-surum-kararlari.md#içe-aktarma-ve-elle-ekleme-sözleşmesi)
tanımlanmıştır. RAWG arama kataloğu yerel koleksiyondan ayrıdır; **Tüm Oyunlar**
yalnızca kullanıcının kaydettiği oyunları gösterir.

## Kullanım örneği

1. Kullanıcı Hades II'yi katalogda arar, doğru sonucu seçer ve Ekle ile onaylar.
   Yerel kayıt başarılı olunca oyun Tüm Oyunlar'da görünür. Arama kullanılamazsa
   aynı adı Elle ekle formunda doğrulayıp kaydeder.
2. Wishlist ve Oynanacak durumlarını seçer. Kartın altında iki kutu görünür.
3. Wishlist sekmesine geçtiğinde aynı oyunu görür.
4. Oyuna sahip olduğunda Kütüphane durumunu ekler. Oyun Kütüphanem'de de görünür.
5. İsterse Wishlist durumunu kaldırır. Diğer durumlar korunur.
6. Oyunu oynadıktan sonra Oynandı, tamamladıktan sonra Bitti durumunu seçer.
7. İsterse kişisel puanını verir. Kartta Puan kutusu görünür.

Bu örneğin adımları zorunlu bir sıra değildir. Bağımsız durum davranışı
ve puanlama, önceki bölümdeki kurallara dayanır.

## İlk sürüm kararları

| Karar | Seçim | Etkisi |
| --- | --- | --- |
| İşletim sistemi | macOS 26 ve sonrası | Kurulum ve paketleme macOS ile sınırlıdır. |
| Masaüstü teknolojisi | Swift 6, SwiftUI, SwiftData ve Xcode 27 | Yerel macOS geliştirme ve dağıtım araçları |
| Oyun ekleme | RAWG ücretsiz API'sinden arama, kullanıcının başlattığı otomatik katalog aktarımı ve yedek olarak elle ad girişi | Katalog için internet ve API anahtarı gerekir; elle ekleme çevrimdışıdır. |
| Veri saklama | Yerel, kalıcı SwiftData deposu | Çevrimdışı kullanım; bulut eşitlemesi yoktur. |
| Puan ölçeği | 1–10 tam sayı, isteğe bağlı | Puan girişi doğrulanır. |
| Durum ilişkileri | Bağımsız seçim | Otomatik durum değişikliği yoktur. |

İlk plan Steam veya Epic hesap bağlantısı, arkadaş sistemi, herkese
açık profil, oyun başlatma ya da cihazlar arası eşitleme taahhüt etmez.
Bunlar ayrıca istenirse kapsam ve veri kullanımı değerlendirilir.

## Geliştirme sırası

| Adım | Teslim edilecek sonuç | Tamamlanma ölçütü |
| --- | --- | --- |
| 1. Kararları netleştir | Hedef sistem, puan ölçeği, durum kuralları ve saklama kararı | Açık kararlar kaydedilmiş olur. |
| 2. Oyun listesini hazırla | API araması, seçilen oyunu içe aktarma, elle ekleme ve dört sekme | Her iki ekleme yolu aynı yerel listeyi besler; yeniden içe aktarma kayıt çoğaltmaz. |
| 3. Durum ve puan düzenlemeyi ekle | Seçimleri yansıtan kutular ve kişisel puan | Değişiklikler bütün sekmelerde aynı kayda yansır. |
| 4. Kalıcılığı ve hataları doğrula | Kapatıp açınca korunan kayıtlar, boş durum ve hata mesajları | Veri kaybı ve başarısız kayıt senaryoları kontrol edilir. |
| 6. Otomatik katalog | Kullanıcı komutuyla RAWG kataloğunu yerel listeye aktarma | Aktarılan oyunlar Tüm Oyunlar'da görünür; kota veya bağlantı hatasında aktarım durur ve sürdürülebilir. |
| 5. Masaüstü sürümünü hazırla | Seçilen sistemde kurulabilir uygulama | 6. adımdan sonra kurulum ve aşağıdaki kabul senaryoları gerçek uygulamada geçer. |

Takvim ve efor, ilk adımdaki kararlar temel alınarak sonraki aşamalarda tahmin edilir.

## Kabul senaryoları

Bu senaryolar gelecekteki uygulama içindir. Bu dokümantasyon değişikliğiyle
geçtikleri iddia edilmez. Aşağıdaki kurallar ilk sürüm için kesinleştirilmiştir.

| No | İşlem | Beklenen sonuç | Dayanak |
| --- | --- | --- | --- |
| K1 | Sekmeleri görüntüle. | Tam olarak Tüm Oyunlar, Kütüphanem, Wishlist ve Oynanacak görünür. | İstenen kapsam |
| K2 | Durumsuz bir oyun görüntüle. | Oyun Tüm Oyunlar'da görünür. Altında boş durum veya puan kutusu bulunmaz. | İstenen kapsam |
| K3 | Oyuna Wishlist ve Oynanacak ekle. | İki kutu görünür. Aynı oyun Tüm Oyunlar, Wishlist ve Oynanacak'ta listelenir. | İstenen kapsam |
| K4 | Oyuna Kütüphane ekle. | Kütüphanem'de görünür. Kart kutusunun adı Kütüphane olur. | İstenen kapsam |
| K5 | Oyuna Oynandı ve Bitti ekle. | Kartta iki kutu görünür. Yeni sekme oluşmaz. | İstenen kapsam |
| K6 | Puan ver, değiştir ve kaldır. | Kart güncel puanı gösterir. Puan kaldırılınca kutusu kaybolur. | İlk sürüm kararı |
| K7 | Wishlist durumunu kaldır. | Oyun Wishlist'ten çıkar. Tüm Oyunlar'da kalır ve diğer durumları korunur. | İlk sürüm kararı |
| K8 | Bitti ve Oynanacak durumlarını birlikte seç. | İkisi de korunur. Oynandı otomatik eklenmez. | İlk sürüm kararı |
| K9 | Boş ad veya ölçek dışı puan kaydetmeyi dene. | Geçersiz bilgi kaydedilmez. Kullanıcı neyi düzeltmesi gerektiğini görür. | İlk sürüm kararı |
| K10 | Uygulamayı kapatıp yeniden aç. | Oyunlar, durumlar ve puanlar korunur. | İlk sürüm kararı |
| K11 | Kaydetme başarısızlığını ve boş sekmeyi görüntüle. | Hata başarı gibi gösterilmez. Boş liste açıklanır. | İlk sürüm kararı |
| K12 | Sekmeleri ve düzenleme kontrollerini klavyeyle kullan. | Odak görünür. İşlemler fare olmadan tamamlanır. | İlk sürüm kararı |
| K13 | Katalogda ara, sonucu seç ve Ekle ile onayla. | Arama tek başına kayıt oluşturmaz. Onaylanan oyun başarılı yerel kayıt sonrası Tüm Oyunlar'da görünür; durumları ve kişisel puanı boştur. | İçe aktarma kararı |
| K14 | Arama sonuçsuzken veya ağ kapalıyken Elle ekle'ye geç. | Aranan ad korunur; kullanıcı düzeltip onaylayınca tek kayıt oluşur. Boş ad reddedilir. | Yedek yol |
| K15 | Anahtar yokken, 401, 403, 429, zaman aşımı ve sunucu hatasında ekleme akışını aç. | Hata veya kurulum gereği açıklanır, elle ekleme kullanılabilir; otomatik istek döngüsü ve yanlış başarı bildirimi yoktur. | API hataları |
| K16 | Aynı RAWG kimliğini yeniden ekle; ayrıca aynı adlı elle kaydı olan bir sonuç seç. | Aynı dış kimlik mevcut kaydı açar ve kişisel verileri korur. Yalnızca ad eşleşmesi otomatik birleştirme yapmaz; ayrı kayıt için kullanıcı onayı gerekir. | Kayıt kimliği |
| K17 | İçe aktarılan oyunu kaydet, interneti kapat ve uygulamayı yeniden aç. | Oyun ve kaynak bilgisi korunur. Durum, puan ve elle ekleme çevrimdışı kullanılabilir. | Yerel kalıcılık |
| K18 | Eksik tarih/platform, boş API adı, geçersiz dış kimlik ve yerel kayıt hatasını dene. | İsteğe bağlı alanların eksikliği engel olmaz. Geçersiz zorunlu alanlar kaydedilmez; yerel kayıt hatası başarı göstermez ve yeniden denenebilir. | Veri doğrulama |
| K19 | Arama, seçim, elle ekleme ve kaynak bağlantısını klavyeyle kullan. | Odak görünür; bütün akış erişilebilirdir. RAWG verisi gösterilen görünümlerde kaynak bağlantısı bulunur. | Erişilebilirlik ve atıf |
| K20 | Anahtarı kaydet ve uygulamayı yeniden aç; saklama alanlarını, API isteklerini ve günlükleri incele. | Anahtar önce Keychain'den alınır. Keychain boşsa ve derleme `Secrets.xcconfig` kullandıysa anahtar paket içindeki `RAWGAPIKey` değerinden alınır. Bu dosya git'te yoktur. Düz metin tercihlerde, SwiftData'da veya günlüklerde anahtar bulunmaz. Yerel koleksiyon, durumlar ve kişisel puanlar RAWG'ye gönderilmez. | Gizlilik |

## Görselin sınırları

Görsel, 1280 × 720 boyutunda iki şemadan oluşur. İlk şema API'den içe aktarmayı
ve elle ekleme yedek yolunu, ikincisi dört sekmeyi ve örnek kartları gösterir.
Teknik olmayan okuyucular için hazırlanmıştır. Nihai ekran tasarımı veya
çalışan uygulama değildir. Puan temsili, görseldeki oyunlar örnektir.

HTML dosyasında stil ve çizim birlikte bulunur. Yazı tipleri internet varsa
Google Fonts üzerinden yüklenir. Çevrimdışı durumda sistem yazı tipleri kullanılır.
Veri saklama ve teknoloji ayrıntıları görselin dışında, bu planda tutulmuştur.
