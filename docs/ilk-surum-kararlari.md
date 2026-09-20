# İlk sürüm kararları

Bu belge, Oyun Kütüphanesi'nin ilk masaüstü sürümü için verilmiş ürün ve
teknik kararların kaynağıdır. Bu kararlar yalnızca ilk sürümün kapsamını
belirler; ileride başka platformların veya çevrimiçi özelliklerin eklenmesini
engellemez.

| Konu | Karar |
| --- | --- |
| Hedef işletim sistemi | macOS 26 ve sonraki sürümler. İlk sürüm yalnızca macOS için dağıtılacak. |
| Masaüstü teknolojisi | Swift 6, SwiftUI ve SwiftData; geliştirme ve paketleme için Xcode 27. |
| Oyun ekleme | Kullanıcı oyun adını elle girerek kayıt oluşturur. Katalog, mağaza hesabı veya internet bağlantısı gerekmez. |
| Veri saklama | SwiftData'nın uygulamaya ait yerel, kalıcı deposu kullanılır. Kayıtlar uygulama yeniden açıldığında korunur; bulut eşitlemesi yapılmaz. |
| Puan ölçeği | Puan isteğe bağlıdır; 1–10 arasında tam sayıdır. Kullanıcı puanı değiştirebilir veya kaldırabilir. |
| Durum kuralları | Kütüphane, Wishlist, Oynanacak, Oynandı ve Bitti birbirinden bağımsızdır. Bir durumun seçilmesi veya kaldırılması başka bir durumu otomatik değiştirmez. |

## İlk sürüm kapsamı

- Açılışta **Tüm Oyunlar** sekmesi seçilir.
- Boş ya da yalnızca boşluklardan oluşan oyun adı kaydedilmez.
- Yalnızca uygulanmış durumlar ve verilmiş puan kartta gösterilir.
- Dört görünüm tam olarak Tüm Oyunlar, Kütüphanem, Wishlist ve Oynanacak'tır.
  Bunlar aynı oyun kayıtlarını filtreler; Oynandı, Bitti ve Puan ayrı sekme
  değildir.
- Kaydetme hatası kullanıcıya açıkça bildirilir; işlem başarılı gibi
  gösterilmez.
- Sekmeler ve düzenleme kontrolleri klavyeyle kullanılabilir ve görünür odağa
  sahiptir.

## Kapsam dışı

Windows, Linux, Steam/Epic bağlantısı, çevrimiçi oyun kataloğu, bulut
eşitlemesi, kullanıcı hesabı, arkadaş sistemi, herkese açık profil ve oyunu
uygulamadan başlatma ilk sürüm kapsamı dışındadır.
