# Build-time RAWG Key Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A private macOS build can search RAWG on first launch when the builder has a gitignored key, and a Keychain value still replaces that key.

**Architecture:** `RAWGKeyResolver` is a pure function. A non-empty Keychain value wins. Otherwise the function returns the trimmed build secret. The app target reads that secret from the built `Info.plist` key `RAWGAPIKey`. Xcode fills the key from `RAWG_API_KEY` in `Game library/Config/Base.xcconfig`, which optionally includes gitignored `Secrets.xcconfig`. Tests pass the secret in as a string. Hosted tests force the secret to empty so a developer machine key never enters the test process.

**Tech Stack:** Swift 6, SwiftUI, XCTest, Xcode 27, macOS 26, xcconfig, generated Info.plist.

**This pull request:** Implementation of the plan. The plan-only draft landed separately.

---

## Locked behavior

Friends do not type a key on every launch when the app they open was built with `Secrets.xcconfig`. The key is still absent from git. A friend who builds without that file sees the current empty-key path and can type a key once. That typed key stays in Keychain and replaces the baked key on later launches.

One shared RAWG key spends one free-plan pool of 20,000 requests per month. The app does not add a quota counter.

Rejected shapes stay out:

- A committed `.env` or a key inside the repository. The key would stop being a secret, and every clone would share it.
- A new settings screen. **API Anahtarını Ayarla** already saves to Keychain.
- Reading `RAWG_API_KEY` from the process environment at launch. A double-clicked `.app` does not receive the builder's shell environment. The value has to be inside the built app.

## File map

- Create `Game library/Game library/RAWGKeyResolver.swift`. Pure resolution. No Keychain and no `Bundle`.
- Modify `Game library/Game library/ContentView.swift` around the `.task` that loads the key, and the footnote in `APIKeySheet`.
- Create `Game library/Game libraryTests/RAWGKeyResolverTests.swift`. XCTest picks this up through the synchronized test folder. Do not edit `project.pbxproj` for this file.
- Create `Game library/Config/Base.xcconfig`.
- Create `Game library/Config/Secrets.example.xcconfig`.
- Create `Game library/Config/RAWGSecrets.plist`. Additional Info.plist merged by the app target. Keep it outside `Game library/Game library/` so the synchronized app folder does not copy it as a resource.
- Modify `Game library/Game library.xcodeproj/project.pbxproj`.
- Modify `.gitignore`.
- Modify `README.md`, `docs/kurulum-macos.md`, `docs/ilk-surum-kararlari.md`, and `docs/proje-plani.md`.

`KeychainStore.swift` stays as it is. `RAWGService` still receives the resolved string and still throws `missingKey` for a blank key.

## Throughput checkpoint

- **Blocking first step.** Task 1. The resolver and its tests land before any Xcode setting.
- **Independent workstreams.** Task 3 (build settings) and Task 4 (Turkish docs) touch different files and can run after Task 2. Task 2 must follow Task 1 because it calls `RAWGKeyResolver`.
- **Shared mutable state.** `project.pbxproj` has one writer, Task 3. Nobody else edits it.
- **Smallest safe decomposition.** Four tasks. One worker can run them in order. The split exists so each commit stays reviewable.

---

### Task 1: Resolve the key in one function

**Files:**
- Create: `Game library/Game library/RAWGKeyResolver.swift`
- Test: `Game library/Game libraryTests/RAWGKeyResolverTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Game library/Game libraryTests/RAWGKeyResolverTests.swift`:

```swift
import XCTest
@testable import Game_library

final class RAWGKeyResolverTests: XCTestCase {
    func testKeychainValueReplacesBuildSecret() {
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: " stored ", buildSecret: "baked"),
            "stored"
        )
    }

    func testBlankKeychainUsesTrimmedBuildSecret() {
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: "   ", buildSecret: " baked "),
            "baked"
        )
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: nil, buildSecret: " baked "),
            "baked"
        )
    }

    func testBlankInputsStayEmpty() {
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: nil, buildSecret: "  "),
            ""
        )
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```sh
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' '-only-testing:Game libraryTests/RAWGKeyResolverTests' test
```

Expected: FAIL because `RAWGKeyResolver` does not exist.

- [ ] **Step 3: Write the minimal implementation**

Create `Game library/Game library/RAWGKeyResolver.swift`:

```swift
import Foundation

enum RAWGKeyResolver {
    static func resolve(keychainKey: String?, buildSecret: String) -> String {
        let stored = keychainKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !stored.isEmpty { return stored }
        return buildSecret.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run the same `xcodebuild` command from Step 2.

Expected: `RAWGKeyResolverTests` passes.

- [ ] **Step 5: Commit**

```bash
git add "Game library/Game library/RAWGKeyResolver.swift" "Game library/Game libraryTests/RAWGKeyResolverTests.swift"
git commit -m "$(cat <<'EOF'
test(rawg): resolve Keychain key ahead of build secret

EOF
)"
```

---

### Task 2: Load the resolved key at launch

**Files:**
- Modify: `Game library/Game library/ContentView.swift` (the `.task` near the key editor, and the footnote in `APIKeySheet`)

The synchronized app folder compiles the new Swift file without a `project.pbxproj` change.

- [ ] **Step 1: Confirm the current launch path**

`ContentView` today does this:

```swift
.task {
    do { apiKey = try KeychainStore.loadRAWGKey() ?? "" }
    catch { errorMessage = "Kaydedilmiş API anahtarı okunamadı. Elle ekleme kullanılabilir." }
}
```

`APIKeySheet` disables **Kaydet** when the field is empty, so this task does not add a clear-Keychain action. A saved Keychain value keeps winning until the user replaces it with another non-empty value.

- [ ] **Step 2: Replace the launch load**

Replace that `.task` body with:

```swift
.task {
    do {
        let stored = try KeychainStore.loadRAWGKey()
        let buildSecret = Self.launchBuildSecret()
        apiKey = RAWGKeyResolver.resolve(keychainKey: stored, buildSecret: buildSecret)
    } catch {
        errorMessage = "Kaydedilmiş API anahtarı okunamadı. Elle ekleme kullanılabilir."
    }
}
```

Add this method on the same view type that owns `apiKey` (the `AddGame` view, not `APIKeySheet`):

```swift
private static func launchBuildSecret() -> String {
    #if DEBUG
    if Game_libraryApp.usesTestStorage { return "" }
    #endif
    return Bundle.main.object(forInfoDictionaryKey: "RAWGAPIKey") as? String ?? ""
}
```

Hosted tests set `usesTestStorage`. They must not read a developer machine's baked key. Release builds always read `RAWGAPIKey`.

- [ ] **Step 3: Replace the sheet footnote**

Replace:

```swift
Text("Anahtar yalnızca bu Mac'in Keychain'inde saklanır; oyun kayıtlarına veya günlük kaydına yazılmaz.")
```

with:

```swift
Text("Kaydettiğiniz anahtar bu Mac'in Keychain'inde saklanır ve derleme sırasında konan anahtarın önüne geçer. Anahtar oyun kayıtlarına veya günlük kaydına yazılmaz.")
```

Leave the save path on `KeychainStore.saveRAWGKey`. Do not print the key in the label, the error text, or a log.

- [ ] **Step 4: Run the existing credential test**

Run:

```sh
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' '-only-testing:Game libraryTests' test
```

Expected: `testHostAndCredentialsUseOnlyMemoryStorage` still passes, and `RAWGKeyResolverTests` still passes. The UI test target is not part of this step.

- [ ] **Step 5: Commit**

```bash
git add "Game library/Game library/ContentView.swift"
git commit -m "$(cat <<'EOF'
feat(rawg): use the build secret when Keychain is empty

EOF
)"
```

---

### Task 3: Inject the secret at build time

**Files:**
- Create: `Game library/Config/Base.xcconfig`
- Create: `Game library/Config/Secrets.example.xcconfig`
- Create: `Game library/Config/RAWGSecrets.plist`
- Modify: `Game library/Game library.xcodeproj/project.pbxproj`
- Modify: `.gitignore`

Do not create `Secrets.xcconfig` in git. Do not put a real key in any committed file.

- [ ] **Step 1: Add the config files**

Create `Game library/Config/Base.xcconfig`:

```
RAWG_API_KEY =
#include? "Secrets.xcconfig"
```

The include stays last so a present secrets file replaces the empty assignment. `#include?` lets a clone build when `Secrets.xcconfig` is missing.

Create `Game library/Config/Secrets.example.xcconfig`:

```
// Copy this file to Secrets.xcconfig and set the key. Never commit Secrets.xcconfig.
RAWG_API_KEY =
```

Create `Game library/Config/RAWGSecrets.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>RAWGAPIKey</key>
	<string>$(RAWG_API_KEY)</string>
</dict>
</plist>
```

Append this line to `.gitignore`:

```
Game library/Config/Secrets.xcconfig
```

- [ ] **Step 2: Point the project at Base.xcconfig**

The app sources use a synchronized root group, so `RAWGKeyResolver.swift` needs no file reference. The xcconfig lives outside that folder, so add these objects.

In `PBXFileReference`, add:

```
A1B2C3D4E5F60718293A4B01 /* Base.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Base.xcconfig; sourceTree = "<group>"; };
```

In `PBXGroup`, add:

```
A1B2C3D4E5F60718293A4B02 /* Config */ = {
	isa = PBXGroup;
	children = (
		A1B2C3D4E5F60718293A4B01 /* Base.xcconfig */,
	);
	path = Config;
	sourceTree = "<group>";
};
```

Add `A1B2C3D4E5F60718293A4B02 /* Config */` to the children of group `C8962150305F4B5A00272685`.

On both project-level configurations, set the base configuration. These are `C896217A305F4B5C00272685 /* Debug */` and `C896217B305F4B5C00272685 /* Release */`. Each block currently starts with `isa = XCBuildConfiguration;` and then `buildSettings`. Insert this line immediately after `isa = XCBuildConfiguration;`:

```
baseConfigurationReference = A1B2C3D4E5F60718293A4B01 /* Base.xcconfig */;
```

Do not attach that base configuration to the test targets.

- [ ] **Step 3: Merge the plist into the app target only**

On app-target Debug `C896217D305F4B5C00272685` and Release `C896217E305F4B5C00272685`, keep `GENERATE_INFOPLIST_FILE = YES` and add:

```
INFOPLIST_FILE = Config/RAWGSecrets.plist;
```

Leave the test targets without `INFOPLIST_FILE`.

- [ ] **Step 4: Verify the setting without a real key**

Run:

```sh
git check-ignore -v "Game library/Config/Secrets.xcconfig"
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' -showBuildSettings | rg "RAWG_API_KEY|INFOPLIST_FILE"
xcodebuild -project "Game library/Game library.xcodeproj" -scheme "Game library" -destination 'platform=macOS' build
```

Expected:

- `git check-ignore` prints the new gitignore rule.
- `RAWG_API_KEY` is empty.
- `INFOPLIST_FILE` is `Config/RAWGSecrets.plist` for the app target.
- The build succeeds.

Then confirm the built Info.plist does not contain a literal `$(RAWG_API_KEY)` and does not contain a non-empty secret. Find the built app under DerivedData and run:

```sh
/usr/libexec/PlistBuddy -c 'Print :RAWGAPIKey' "$APP/Contents/Info.plist"
```

Expected: an empty string.

- [ ] **Step 5: Verify a stand-in secret on a copy, then delete the copy**

In a temporary directory outside the repo, copy `Secrets.example.xcconfig` to `Game library/Config/Secrets.xcconfig` and set one line:

```
RAWG_API_KEY = stand-in-not-a-real-key
```

Build again. `PlistBuddy` should print `stand-in-not-a-real-key`. Delete `Game library/Config/Secrets.xcconfig` before committing. Run `git status` and confirm that file is absent.

- [ ] **Step 6: Commit**

```bash
git add .gitignore "Game library/Config/Base.xcconfig" "Game library/Config/Secrets.example.xcconfig" "Game library/Config/RAWGSecrets.plist" "Game library/Game library.xcodeproj/project.pbxproj"
git commit -m "$(cat <<'EOF'
build(rawg): read the API key from a gitignored xcconfig

EOF
)"
```

---

### Task 4: Document the private-build key

**Files:**
- Modify: `README.md`
- Modify: `docs/kurulum-macos.md`
- Modify: `docs/ilk-surum-kararlari.md`
- Modify: `docs/proje-plani.md`

Keep these edits in Turkish. Do not mark a K1–K20 scenario newly verified. This task changes the written rule. It does not record acceptance evidence.

- [ ] **Step 1: Update the decision**

In `docs/ilk-surum-kararlari.md`, replace the paragraph that starts `Kullanıcı kendi RAWG API anahtarını ayarlara girer.` with:

```markdown
Kullanıcı kendi RAWG API anahtarını ayarlardan kaydedebilir. Kayıtlı anahtar macOS Keychain'de durur ve derleme anahtarının önüne geçer. İsteğe bağlı derleme anahtarı `Game library/Config/Secrets.xcconfig` dosyasından gelir. Bu dosya git'e girmez. Dosya varken yapılan derleme, anahtarı uygulama paketinin `Info.plist` alanına `RAWGAPIKey` olarak yazar. Dosya yokken yapılan derleme anahtar içermez. Anahtar SwiftData oyun kaydına veya günlük kayıtlarına yazılmaz. İstek adreslerindeki `key` parametresi de günlüklerden çıkarılır. Anahtar yoksa katalog kurulumu açıklanır ve **Elle ekle** kullanılabilir.
```

Leave the following sentences about the app server and the RAWG account in place.

- [ ] **Step 2: Update setup and the package sentence**

In `docs/kurulum-macos.md`, replace step 4's RAWG sentence:

```markdown
4. **Oyun Ekle** ile elle kayıt yapabilirsiniz. Derleme `Secrets.xcconfig` ile yapıldıysa RAWG araması ilk açılışta anahtar istemez. Aksi halde anahtarı uygulamadaki güvenli anahtar formuna bir kez girin; terminale veya hata raporuna yazmayın. Keychain'deki anahtar derleme anahtarının önüne geçer. Katalog sonuçları onayla eklenir.
```

Replace:

```markdown
Paket koleksiyon veritabanı veya hazır API anahtarı içermez.
```

with:

```markdown
Paket koleksiyon veritabanı içermez. `Secrets.xcconfig` olmadan üretilen paket API anahtarı içermez. Bu dosyayla üretilen paket anahtarı `Info.plist` içinde taşır. Aynı anahtarı paylaşan arkadaşlar RAWG ücretsiz planının aylık 20.000 istek kotasını birlikte harcar.
```

- [ ] **Step 3: Update the README steps**

In `README.md`, replace the catalog bullet under **Oyun ekleme adımları**:

```markdown
1. Araç çubuğundan **Oyun Ekle**'yi açın. Derleme anahtarı varsa katalog araması hazırdır. Yoksa kendi RAWG anahtarınızı ayarlardan bir kez kaydedin. Kaydettiğiniz anahtar Keychain'de durur ve derleme anahtarının önüne geçer.
```

Replace the first sentence of **Otomatik katalog aktarımı**:

```markdown
**Oyun Ekle** panelinde RAWG anahtarı hazır olmalıdır. Derleme anahtarı yoksa kendi anahtarınızı ayarlayın. Panelin altındaki
```

Keep the rest of that paragraph, starting at `**Kataloğu Aktar**`.

- [ ] **Step 4: Update the K20 wording without claiming new evidence**

In `docs/proje-plani.md`, replace the K20 expected-result cell:

```markdown
Anahtar önce Keychain'den alınır. Keychain boşsa ve derleme `Secrets.xcconfig` kullandıysa anahtar paket içindeki `RAWGAPIKey` değerinden alınır. Bu dosya git'te yoktur. Düz metin tercihlerde, SwiftData'da veya günlüklerde anahtar bulunmaz. Yerel koleksiyon, durumlar ve kişisel puanlar RAWG'ye gönderilmez.
```

- [ ] **Step 5: Check the docs and commit**

Run:

```sh
git diff --check
```

Expected: no whitespace errors. Confirm `Secrets.xcconfig` is not tracked:

```sh
git status --short
git ls-files "Game library/Config/Secrets.xcconfig"
```

Expected: `git ls-files` prints nothing.

```bash
git add README.md docs/kurulum-macos.md docs/ilk-surum-kararlari.md docs/proje-plani.md
git commit -m "$(cat <<'EOF'
docs(rawg): describe the gitignored build-time API key

EOF
)"
```

---

## Self-review

Spec coverage:

- First launch without typing, when the builder had the gitignored file. Task 3 bakes `RAWGAPIKey`. Task 2 reads it only when Keychain is empty.
- Keychain override. Task 1 test `testKeychainValueReplacesBuildSecret`. Task 2 wires that function.
- Secret stays out of git. Task 3 gitignore, example file, and the stand-in cleanup.
- Tests do not use a live key or the user's library. Task 2 returns `""` when `usesTestStorage` is set.
- Shared quota is stated in `docs/kurulum-macos.md`. No new quota UI.
- Manual add still works with an empty resolved key. `RAWGService` already throws `missingKey`. No change there.

Placeholder scan: every code step includes the file body or the exact `project.pbxproj` lines. No deferred validation step.

Type consistency: the function is `RAWGKeyResolver.resolve(keychainKey:buildSecret:) -> String` in Tasks 1 and 2. The plist key is `RAWGAPIKey`. The build setting is `RAWG_API_KEY`.

## Out of scope

- Publishing, notarization, or a shared backend that hides the key.
- Clearing Keychain from the sheet. **Kaydet** stays disabled for an empty field.
- Changing `scripts/package-macos.py`. A package build on a machine that has `Secrets.xcconfig` will embed the key. Task 4 says so.
- Live RAWG calls in tests.
