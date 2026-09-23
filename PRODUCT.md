# Product

<!-- impeccable:product-schema 1 -->

## Platform

macos

The schema's usual values are web, ios, android, or adaptive. This product is a macOS-only SwiftUI app. Visual work follows the Mac desktop, not a phone layout.

## Users

One person on their own Mac, keeping a private list of games they own, want, or mean to play.

## Product Purpose

Oyun Kütüphanesi stores that person's games on the Mac. Success is finding a game, seeing its real statuses, and changing a status or rating without losing the list.

## Positioning

Statuses are independent. Marking a game finished does not clear wishlist, library, or to-play. The catalog search imports a chosen RAWG record. It never writes community scores into the personal rating.

## Operating Context

A local macOS window. The library works offline after a game is saved. Catalog search needs the user's own RAWG key, kept in Keychain.

## Capabilities and Constraints

- macOS 26 or later. SwiftUI and SwiftData. No cloud sync and no account.
- Four filters: Tüm Oyunlar, Kütüphanem, Wishlist, Oynanacak. Oynandı, Bitti, and rating are not filters.
- Add by RAWG search, explicit resumable catalog import, or manual title. Empty titles are rejected. The same RAWG id opens the existing record in single import and is skipped in bulk import. Single import asks before adding a same-name game; the explicit bulk command adds separate catalog records without merging manual entries.
- Rating is an optional integer from 1 to 10.
- UI copy stays Turkish. Keyboard access and visible focus stay.
- Cover art is out of scope.

## Brand Commitments

The product name is Oyun Kütüphanesi. Labels already in the app stay, including Wishlist.

## Evidence on Hand

Product rules live in `docs/ilk-surum-kararlari.md`. The throwaway layout study is `work/poteto/oyun-arayuz-prototip/index.html`. No testimonials or usage metrics exist. Do not invent them.

## Product Principles

- The list stays visible while a game is edited or added.
- A status change never rewrites another status.
- Catalog data and personal data stay separate.
- Offline editing is the normal case, not a fallback mode.

## Accessibility & Inclusion

Keyboard shortcuts select the four filters. Controls keep visible focus. Motion respects Reduce Motion.
