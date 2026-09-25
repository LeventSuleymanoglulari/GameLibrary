# Tasarım

## Sahne

Mac üzerinde kişisel oyun rafı. Açık görünüm sıcak kâğıt, koyu görünüm aynı paletin koyu tonlarıdır. Vurgu rengi kehribardır.

## Düzen

[28 numaralı kayıttaki A çeşidi](https://github.com/LeventSuleymanoglulari/GameLibrary/issues/28) uygulanır. Sol ray, raf ve sağ panel korunur. Dört temel filtrenin yanında bağımsız Favoriler filtresi ve platform süzgeci bulunur. Liste ve Pencere aynı kayıtları gösterir; görünüm değişirken seçili oyun ve ayrıntı paneli korunur.

## Denetimler

Liste satırında kapak, ad, kaynak, durumlar, puan ve favori düğmesi bulunur. Pencere kapak ızgarasıdır. Eksik kapaklar oyun simgesiyle gösterilir. Durumlar bağımsız macOS onay kutularıdır. Platform ve puan menüdür. Favori durumları değiştirmez. Steam, Epic Games, GOG, PC, PlayStation, Xbox, Nintendo Switch, Android ve iOS seçimi RAWG katalog platformlarından ayrıdır. Ekleme ile ayrıntı aynı sağ paneli kullanır.

## Hareket ve erişilebilirlik

Kapak geometrisi görünüm değişiminde SwiftUI matchedGeometryEffect ile 320 ms boyunca eşleştirilir. Ayrıntı paneli 280 ms içinde 14 punto sağdan kayarak belirir. Favori işareti 140 ms içinde değişir. Reduce Motion ile geometrik hareket kaldırılır ve süre 120 ms olur. Sistem yazı tipleri, erişilebilir denetim adları ve Command–1…5 filtre kısayolları korunur.
