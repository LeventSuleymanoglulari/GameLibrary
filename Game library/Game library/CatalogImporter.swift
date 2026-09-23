import Foundation
import Observation
import SwiftData

@MainActor @Observable final class CatalogImporter {
    private(set) var isRunning = false
    private(set) var message: String?
    private(set) var errorMessage: String?
    private var stopRequested = false
    private var task: Task<Void, Never>?
    private let fetch: (Int, String) async throws -> RAWGSearchResponse
    private let pause: () async throws -> Void
    private let save: (ModelContext) throws -> Void
    let pageLimit: Int

    init(
        pageLimit: Int = 100,
        fetch: @escaping (Int, String) async throws -> RAWGSearchResponse = { page, key in
            #if DEBUG
            if Game_libraryApp.usesTestStorage && ProcessInfo.processInfo.arguments.contains("--ui-testing-bulk") {
                if page == 2 && ProcessInfo.processInfo.arguments.contains("--ui-testing-bulk-quota") {
                    throw RAWGServiceError.rateLimited
                }
                let data = Data("{\"results\":[{\"id\":\(page),\"name\":\"Toplu Oyun \(page)\",\"rating\":4.8}]}".utf8)
                let response = try JSONDecoder().decode(RAWGSearchResponse.self, from: data)
                return RAWGSearchResponse(next: page < 2 ? "fixture-next" : nil, results: response.results)
            }
            #endif
            return try await RAWGService().catalogPage(page, apiKey: key)
        },
        pause: @escaping () async throws -> Void = { try await Task.sleep(for: .seconds(1)) },
        save: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.pageLimit = max(1, pageLimit)
        self.fetch = fetch
        self.pause = pause
        self.save = save
    }

    func start(container: ModelContainer, apiKey: String, restart: Bool = false) {
        guard task == nil, !isRunning else { return }
        task = Task {
            await run(container: container, apiKey: apiKey, restart: restart)
            task = nil
        }
    }

    func stop() {
        stopRequested = true
        task?.cancel()
    }

    func run(container: ModelContainer, apiKey: String, restart: Bool = false) async {
        guard !isRunning else { return }
        isRunning = true
        stopRequested = false
        errorMessage = nil
        message = nil
        defer { isRunning = false }
        // Ayrı bağlam: hata geri alması elle ekleme/düzenlemeyi geri alamaz.
        let context = ModelContext(container)
        context.autosaveEnabled = false
        do {
            let progress: CatalogImportProgress
            if let existing = try context.fetch(FetchDescriptor<CatalogImportProgress>()).first {
                progress = existing
            } else {
                progress = CatalogImportProgress()
                context.insert(progress)
            }
            guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RAWGServiceError.missingKey
            }
            if restart {
                progress.nextPage = 1
                progress.isComplete = false
                try save(context)
            }
            if progress.isComplete { message = "Katalog aktarımı tamamlandı."; return }
            for index in 0..<pageLimit {
                try checkStopped()
                let page = progress.nextPage
                guard page > 0 && page < Int.max else { throw RAWGServiceError.invalidResponse }
                message = "Sayfa \(page) alınıyor…"
                let response = try await fetch(page, apiKey)
                try checkStopped()
                // Boş ama devamı olduğunu iddia eden yanıt sonsuz döngüye dönüşmesin.
                guard response.next == nil || !response.results.isEmpty else { throw RAWGServiceError.invalidResponse }
                var seen = Set<Int>()
                var inserted = 0
                do {
                    for row in response.results where seen.insert(row.id).inserted {
                        let draft = try GameDraft.rawg(row)
                        let id = row.id
                        var descriptor = FetchDescriptor<Game>(predicate: #Predicate {
                            $0.source == "rawg" && $0.externalID == id
                        })
                        descriptor.fetchLimit = 1
                        guard try context.fetch(descriptor).isEmpty else { continue }
                        // Aynı adlı elle kayıtlar birleştirilmez. Kişisel alanlar varsayılan boş kalır.
                        let game = Game(title: draft.title, source: "rawg", externalID: id,
                                        sourceURL: row.sourceURL.absoluteString,
                                        releaseDate: row.released, platforms: row.platformNames)
                        game.artworkURL = row.artwork?.url.absoluteString
                        context.insert(game)
                        inserted += 1
                    }
                    progress.nextPage = page + 1
                    progress.isComplete = response.next == nil
                    progress.importedCount += inserted
                    // Oyunlar ve işaretçi tek işlemde: hata halinde ikisi de geri alınır.
                    try save(context)
                } catch {
                    context.rollback()
                    errorMessage = "Sayfa kaydedilemedi. Önceki kayıtlar korundu; aynı sayfadan sürdürebilirsiniz."
                    message = nil
                    return
                }
                if progress.isComplete { message = "Katalog aktarımı tamamlandı."; return }
                message = "Sayfa \(page) kaydedildi."
                if index + 1 < pageLimit { try await pause() }
            }
            message = "\(pageLimit) sayfalık sınırda duraklatıldı. Devam etmek için Sürdür'ü seçin."
        } catch is CancellationError {
            message = "Aktarım durduruldu. Son kaydedilen sayfadan sürdürebilirsiniz."
        } catch {
            message = nil
            errorMessage = (error as? RAWGServiceError)?.errorDescription
                ?? "Aktarım tamamlanamadı. Kayıtlar korundu; yeniden sürdürebilirsiniz."
        }
    }

    private func checkStopped() throws {
        try Task.checkCancellation()
        if stopRequested { throw CancellationError() }
    }
}
