#!/usr/bin/env python3
"""Eski SwiftData deposunu gerçek güncel modelle açarak veri geçişini doğrular."""

from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
BASELINE = "e98c9b6636e172f178dcc3c42839270a2bc9473b"
MODEL = "Game library/Game library/Game.swift"
SERVICE = "Game library/Game library/RAWGService.swift"

COMMON = r'''
import Foundation
import SwiftData

@main struct MigrationCheck {
    @MainActor static func main() throws {
        let storeURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let identityURL = URL(fileURLWithPath: CommandLine.arguments[2])
        let configuration = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: Game.self, configurations: configuration)
        let context = ModelContext(container)
'''

BEFORE = COMMON + r'''
        let game = Game(title: "Eski oyun kaydı", addedDate: Date(timeIntervalSince1970: 123456789))
        game.isInLibrary = true
        game.isWishlisted = false
        game.isToPlay = true
        context.insert(game)
        try context.save()
        try JSONEncoder().encode(game.persistentModelID).write(to: identityURL)
        print("Eski şema ile kayıt oluşturuldu.")
    }
}
'''

AFTER = COMMON + r'''
        let games = try context.fetch(FetchDescriptor<Game>())
        precondition(games.count == 1, "Kayıt sayısı değişti")
        let game = games[0]
        let oldID = try JSONDecoder().decode(PersistentIdentifier.self, from: Data(contentsOf: identityURL))
        precondition(game.persistentModelID == oldID, "Kalıcı kimlik değişti")
        precondition(game.title == "Eski oyun kaydı", "Oyun adı değişti")
        precondition(game.addedDate == Date(timeIntervalSince1970: 123456789), "Eklenme tarihi değişti")
        precondition(game.isInLibrary && !game.isWishlisted && game.isToPlay, "Durumlar değişti")
        precondition(game.source == "manual", "Elle ekleme kaynağı atanmadı")
        precondition(game.platforms.isEmpty, "Platformlar boş değil")
        precondition(game.externalID == nil, "Dış kimlik boş değil")
        precondition(game.sourceURL == nil, "Kaynak bağlantısı boş değil")
        precondition(game.releaseDate == nil, "Çıkış tarihi boş değil")
        precondition(!game.isPlayed && !game.isCompleted && game.rating == nil, "Yeni kişisel alanlar boş değil")
        print("PASS: Kalıcı kimlik, ad, tarih ve üç durum korundu; yeni kaynak ve kişisel alanlar doğru.")
    }
}
'''


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def main():
    legacy = subprocess.check_output(
        ["git", "show", f"{BASELINE}:{MODEL}"], cwd=ROOT, text=True
    )
    with tempfile.TemporaryDirectory(prefix="game-library-migration-") as directory:
        work = Path(directory)
        old_model = work / "LegacyGame.swift"
        old_model.write_text(legacy, encoding="utf-8")
        runner = work / "MigrationCheck.swift"
        executable = work / "migration-check"
        store = work / "legacy.store"
        identity = work / "identity.json"
        compiler = [
            "xcrun", "swiftc", "-swift-version", "6", "-default-isolation", "MainActor",
            "-module-name", "Game_library", "-o", str(executable),
        ]
        runner.write_text(BEFORE, encoding="utf-8")
        run(*compiler, str(old_model), str(runner))
        run(str(executable), str(store), str(identity))
        runner.write_text(AFTER, encoding="utf-8")
        run(*compiler, str(ROOT / MODEL), str(ROOT / SERVICE), str(runner))
        run(str(executable), str(store), str(identity))


if __name__ == "__main__":
    main()
