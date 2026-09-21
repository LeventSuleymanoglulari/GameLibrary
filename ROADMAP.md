# Oyun Kütüphanesi — Yol Haritası

Amaç, oyunları, oynama durumlarını ve kişisel puanları tek yerde takip eden
bir PC masaüstü uygulamasının ilk kullanılabilir sürümünü hazırlamak.

Depoda native macOS uygulaması, belgeler ve görsel taslak bulunur.
Bu yol haritası [proje planındaki](docs/proje-plani.md) geliştirme sırasını takip
eder. Ayrıntılı kullanım kuralları ve K1–K20 kabul senaryoları için kaynak
proje planıdır. 2. aşamanın kanıtları [doğrulama kaydında](docs/asama-2-dogrulama.md) tutulur.

## Tamamlanan hazırlık

- [x] Dört sekmenin ve oyun kartlarının kapsamını belgelemek.
- [x] Önerilen çalışma kurallarını ve açık kararları kaydetmek.
- [x] Kabul senaryolarını ve görsel anlatımı hazırlamak.

Bu maddeler belge hazırlığını gösterir; uygulama kontrolleri ilgili aşamalarda
ayrı doğrulanır.

## 1. İlk sürüm kararlarını netleştir

- [x] Hedef işletim sistemi ve desteklenen sürümleri belirle: macOS 26 ve sonrası.
- [x] Masaüstü teknolojisini ve geliştirme araçlarını seç: SwiftUI, SwiftData ve Xcode 27.
- [x] Ücretsiz RAWG API'sinden içe aktarmayı öncelikli yol, elle eklemeyi sürekli kullanılabilir yedek yol olarak belirle.
- [x] Yerel SwiftData kalıcılığını ve yeniden açılışta kayıtların korunmasını belirle.
- [x] İsteğe bağlı 1–10 tam sayı puan ölçeğini belirle.
- [x] Durumların bağımsız seçilmesini ve otomatik durum değişikliği yapılmamasını karara bağla.
- [x] Sonuçları [ilk sürüm kararlarına](docs/ilk-surum-kararlari.md) ve proje planına işle; kabul senaryolarını güncelle.

**Tamamlanma ölçütü:** Tamamlandı. Teknoloji, platform ve davranış kararları
kayıtlıdır; ilk sürümün kapsamı ve geçmesi gereken kabul senaryoları bellidir.

## 2. Oyun listesini ve dört sekmeyi hazırla

Ön koşul: 1. aşamadaki kararların tamamlanması.

- [x] Seçilen teknolojiyle çalıştırılabilir masaüstü uygulamasını oluştur;
  kurulum ve geliştirme komutlarını README'ye ekle.
- [x] RAWG anahtarını kullanıcı ayarlarından alıp Keychain'de sakla; eksik anahtarda elle ekleme sun.
- [x] Kullanıcı komutuyla katalog araması, sayfalama, sonuç seçimi ve onayla içe aktarma akışını ekle.
- [x] Kaynak kimliğini ve isteğe bağlı katalog alanlarını yerel kayda ekle; mevcut elle kayıtları koruyan veri geçişini doğrula.
- [x] Aynı dış kimliği yeniden eklemeyi kayıt çoğaltmadan işle; aynı adlı oyunları otomatik birleştirme.
- [x] Elle eklemeyi her zaman erişilebilir tut; başarısız aramadaki adı forma taşı.
- [x] RAWG kaynak bağlantısını verinin gösterildiği görünümlere ekle.
- [x] Tüm Oyunlar, Kütüphanem, Wishlist ve Oynanacak sekmelerini oluştur.
- [x] Sekmeleri aynı oyun kayıtlarının görünümleri olarak kur; sekme başına
  ayrı oyun kaydı oluşturma.
- [x] Durumsuz ve puansız kartta yalnızca oyun adını göster.

**Tamamlanma ölçütü:** Uygulama açılır, eklenen oyun Tüm Oyunlar'da görünür,
tam olarak dört sekme vardır ve boş durum kutuları görünmez (K1–K2).
Katalogdan ve elle ekleme yolları ile tekrar içe aktarma doğrulanır (K13–K16).

Uygulama ve otomatik kontroller tamamlandı. Katalog testleri yerel yanıtlarla
çalışır; geçerli RAWG anahtarıyla canlı servis kabulü henüz yapılmadı.
[Kanıtlar ve kalan sınırlar](docs/asama-2-dogrulama.md) ayrı kayıtlıdır.

## 3. Durum ve puan düzenlemeyi ekle

Ön koşul: 2. aşamadaki oyun listesi ve kartların çalışması.

- [x] Kütüphane, Wishlist, Oynanacak, Oynandı ve Bitti durumlarını seçilen
  kurallara göre düzenlemeyi sağla.
- [x] Yalnızca uygulanmış durumları kartın altında ayrı kutularda göster.
- [x] Durum değişikliklerini aynı kaydın göründüğü bütün sekmelere yansıt.
- [x] İsteğe bağlı puan verme, değiştirme ve kaldırma işlemlerini ekle.
- [x] Boş oyun adı ve geçersiz puan için kararlaştırılan doğrulamayı uygula.
- [x] Sekmeleri ve düzenleme kontrollerini klavyeyle kullanılabilir yap;
  görünür odak ve metinle anlaşılır seçimler sağla.

**Tamamlanma ölçütü:** Tamamlandı. Durumlar doğru kart kutularını ve sekme üyeliklerini
belirler; Oynandı, Bitti ve Puan ayrı sekme oluşturmaz. K3–K9 ve K12'nin
kararlaştırılan davranışlara uygun sürümleri geçer.

## 4. Kalıcılığı ve hata durumlarını doğrula

Ön koşul: 3. aşamadaki düzenleme akışlarının çalışması.

- [ ] Kararlaştırılan saklama yöntemiyle oyunları, durumları ve puanları kaydet.
- [ ] Uygulama kapatılıp açıldığında kayıtların korunduğunu doğrula.
- [ ] Kaydetme başarısız olduğunda başarı gösterme; kullanıcıya hata bildir.
- [ ] Boş sekmeler için açıklayıcı mesajlar ekle.
- [ ] API anahtarı, kota, ağ, zaman aşımı ve eksik veri hatalarını doğrula.
- [ ] İçe aktarılan kayıtların çevrimdışı açılmasını, düzenlenmesini ve mevcut elle kayıtların korunmasını doğrula.
- [ ] Anahtarın günlüklerde görünmediğini ve kişisel verilerin API'ye gönderilmediğini doğrula.
- [ ] Durumların sekmelere yansımasını, puan doğrulamasını ve kayıt davranışını
  kapsayan odaklı otomatik kontrolleri ekle; test komutunu README'ye yaz.

**Tamamlanma ölçütü:** K10–K11'in kararlaştırılan sürümleri geçer; yeniden
açılış ve başarısız kayıt senaryolarının sonuçları kaydedilir. K17–K20 geçer.

## 5. İlk masaüstü sürümünü hazırla

Ön koşul: 4. aşamadaki kalıcılık ve hata kontrollerinin geçmesi.

- [ ] Uygulamayı seçilen işletim sistemi için kurulabilir paket haline getir.
- [ ] Paketleme, kurulum ve çalıştırma adımlarını README'de belgele.
- [ ] Dağıtım öncesi RAWG ücretsiz kullanım koşullarını ve atıf bağlantılarını yeniden kontrol et.
- [ ] Kurulan uygulamada geçerli K1–K20 senaryolarını doğrula; test ve
  varsa lint komutlarını çalıştır.
- [ ] Doğrulanan uygulama sürümünü, işletim sistemini, sonuçları ve bilinen
  sınırlamaları sürüm notlarına kaydet.

**Tamamlanma ölçütü:** Uygulama hedef sistemde kurulup açılır; kabul
senaryoları geçer ve ilk sürümün kullanım adımları belgelenmiştir.

## İlk sürüm dışında

Steam/Epic hesap bağlantısı, toplu katalog indirme, arkadaş sistemi, herkese açık profil,
oyun başlatma ve cihazlar arası eşitleme mevcut kapsamda taahhüt edilmez.
Ayrıca istenirse kapsam ve veri kullanımı değerlendirilir.

Takvim ve efor, 1. aşamadaki kararlar verilmeden tahmin edilmez. Bir görev
yalnızca ilgili sonuç doğrulandığında tamamlandı olarak işaretlenir.
