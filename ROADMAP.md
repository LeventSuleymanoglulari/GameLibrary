# Oyun Kütüphanesi — Yol Haritası

Amaç, oyunları, oynama durumlarını ve kişisel puanları tek yerde takip eden
bir PC masaüstü uygulamasının ilk kullanılabilir sürümünü hazırlamak.

Depo şu anda yalnızca belgeleri ve görsel taslağı içerir; uygulama geliştirmesi
başlamamıştır. Bu yol haritası [proje planındaki](docs/proje-plani.md) geliştirme
sırasını takip eder. Ayrıntılı kullanım kuralları ve K1–K12 kabul senaryoları
için kaynak proje planıdır. Önerilen davranışlar, aşağıdaki ilk aşamada
kararlaştırılmadan kesin gereksinim sayılmaz.

## Tamamlanan hazırlık

- [x] Dört sekmenin ve oyun kartlarının kapsamını belgelemek.
- [x] Önerilen çalışma kurallarını ve açık kararları kaydetmek.
- [x] Kabul senaryolarını ve görsel anlatımı hazırlamak.

Bu maddeler belge hazırlığını gösterir; uygulama kabul senaryoları henüz
çalıştırılmamıştır.

## 1. İlk sürüm kararlarını netleştir

- [ ] Hedef işletim sistemini ve desteklenecek sürümlerini belirle.
- [ ] Masaüstü teknolojisini ve geliştirme araçlarını seç.
- [ ] Elle oyun ekleme önerisini karara bağla.
- [ ] Veri saklama yöntemini ve yeniden açılışta kayıtların korunması kuralını belirle.
- [ ] Puan ölçeğini belirle; mevcut öneri isteğe bağlı, 1–10 arasında tam sayıdır.
- [ ] Durumların bağımsız seçilmesi ve otomatik durum değişikliği yapılmaması
  önerisini karara bağla.
- [ ] Sonuçları proje planına işle; öneriye bağlı kabul senaryolarını güncelle.

**Tamamlanma ölçütü:** Teknoloji, platform ve davranış kararları kayıtlıdır;
ilk sürümün kapsamı ve geçmesi gereken kabul senaryoları bellidir.

## 2. Oyun listesini ve dört sekmeyi hazırla

Ön koşul: 1. aşamadaki kararların tamamlanması.

- [ ] Seçilen teknolojiyle çalıştırılabilir masaüstü uygulamasını oluştur;
  kurulum ve geliştirme komutlarını README'ye ekle.
- [ ] Kararlaştırılan yöntemle oyun eklemeyi ve oyun adını kartta göstermeyi sağla.
- [ ] Tüm Oyunlar, Kütüphanem, Wishlist ve Oynanacak sekmelerini oluştur.
- [ ] Sekmeleri aynı oyun kayıtlarının görünümleri olarak kur; sekme başına
  ayrı oyun kaydı oluşturma.
- [ ] Durumsuz ve puansız kartta yalnızca oyun adını göster.

**Tamamlanma ölçütü:** Uygulama açılır, eklenen oyun Tüm Oyunlar'da görünür,
tam olarak dört sekme vardır ve boş durum kutuları görünmez (K1–K2).

## 3. Durum ve puan düzenlemeyi ekle

Ön koşul: 2. aşamadaki oyun listesi ve kartların çalışması.

- [ ] Kütüphane, Wishlist, Oynanacak, Oynandı ve Bitti durumlarını seçilen
  kurallara göre düzenlemeyi sağla.
- [ ] Yalnızca uygulanmış durumları kartın altında ayrı kutularda göster.
- [ ] Durum değişikliklerini aynı kaydın göründüğü bütün sekmelere yansıt.
- [ ] İsteğe bağlı puan verme, değiştirme ve kaldırma işlemlerini ekle.
- [ ] Boş oyun adı ve geçersiz puan için kararlaştırılan doğrulamayı uygula.
- [ ] Sekmeleri ve düzenleme kontrollerini klavyeyle kullanılabilir yap;
  görünür odak ve metinle anlaşılır seçimler sağla.

**Tamamlanma ölçütü:** Durumlar doğru kart kutularını ve sekme üyeliklerini
belirler; Oynandı, Bitti ve Puan ayrı sekme oluşturmaz. K3–K9 ve K12'nin
kararlaştırılan davranışlara uygun sürümleri geçer.

## 4. Kalıcılığı ve hata durumlarını doğrula

Ön koşul: 3. aşamadaki düzenleme akışlarının çalışması.

- [ ] Kararlaştırılan saklama yöntemiyle oyunları, durumları ve puanları kaydet.
- [ ] Uygulama kapatılıp açıldığında kayıtların korunduğunu doğrula.
- [ ] Kaydetme başarısız olduğunda başarı gösterme; kullanıcıya hata bildir.
- [ ] Boş sekmeler için açıklayıcı mesajlar ekle.
- [ ] Durumların sekmelere yansımasını, puan doğrulamasını ve kayıt davranışını
  kapsayan odaklı otomatik kontrolleri ekle; test komutunu README'ye yaz.

**Tamamlanma ölçütü:** K10–K11'in kararlaştırılan sürümleri geçer; yeniden
açılış ve başarısız kayıt senaryolarının sonuçları kaydedilir.

## 5. İlk masaüstü sürümünü hazırla

Ön koşul: 4. aşamadaki kalıcılık ve hata kontrollerinin geçmesi.

- [ ] Uygulamayı seçilen işletim sistemi için kurulabilir paket haline getir.
- [ ] Paketleme, kurulum ve çalıştırma adımlarını README'de belgele.
- [ ] Kurulan uygulamada geçerli K1–K12 senaryolarını doğrula; test ve
  varsa lint komutlarını çalıştır.
- [ ] Doğrulanan uygulama sürümünü, işletim sistemini, sonuçları ve bilinen
  sınırlamaları sürüm notlarına kaydet.

**Tamamlanma ölçütü:** Uygulama hedef sistemde kurulup açılır; kabul
senaryoları geçer ve ilk sürümün kullanım adımları belgelenmiştir.

## İlk sürüm dışında

Steam/Epic bağlantısı, mağaza kataloğu, arkadaş sistemi, herkese açık profil,
oyun başlatma ve cihazlar arası eşitleme mevcut kapsamda taahhüt edilmez.
Ayrıca istenirse kapsam ve veri kullanımı değerlendirilir.

Takvim ve efor, 1. aşamadaki kararlar verilmeden tahmin edilmez. Bir görev
yalnızca ilgili sonuç doğrulandığında tamamlandı olarak işaretlenir.
