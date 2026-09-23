import Foundation
import Observation

struct CatalogArtwork: Equatable, Hashable {
    let url: URL

    static func parse(_ raw: String?) -> CatalogArtwork? {
        guard let raw, let url = URL(string: raw),
              url.scheme == "https", url.host?.lowercased() == "media.rawg.io",
              url.user == nil, url.password == nil, url.port == nil else { return nil }
        return CatalogArtwork(url: url)
    }
}

struct RAWGGame: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let released: String?
    let slug: String?
    let platformNames: [String]
    let artwork: CatalogArtwork?

    private enum CodingKeys: String, CodingKey { case id, name, released, slug, platforms, backgroundImage = "background_image" }
    private struct PlatformContainer: Decodable {
        struct Platform: Decodable { let name: String? }
        let platform: Platform?
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            platform = try? container.decode(Platform.self, forKey: .platform)
        }
        private enum Keys: String, CodingKey { case platform }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name).trimmingCharacters(in: .whitespacesAndNewlines)
        guard id > 0, !name.isEmpty else { throw RAWGServiceError.invalidResponse }
        released = try? container.decode(String.self, forKey: .released)
        slug = try? container.decode(String.self, forKey: .slug)
        let platforms = (try? container.decode([PlatformContainer].self, forKey: .platforms)) ?? []
        platformNames = Array(Set(platforms.compactMap { $0.platform?.name }.filter { !$0.isEmpty })).sorted()
        artwork = CatalogArtwork.parse(try? container.decode(String.self, forKey: .backgroundImage))
    }

    var sourceURL: URL {
        guard let slug, !slug.isEmpty,
              slug.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" }) else {
            return RAWGService.attributionURL
        }
        return RAWGService.attributionURL.appendingPathComponent("games").appendingPathComponent(slug)
    }
}

struct RAWGSearchResponse: Decodable {
    let next: String?
    let results: [RAWGGame]
}

enum RAWGServiceError: LocalizedError {
    case missingKey, invalidResponse, unauthorized, rateLimited, serverError, offline, timedOut

    var errorDescription: String? {
        switch self {
        case .missingKey: "RAWG API anahtarı gerekli. Ayarlardan ekleyebilir veya elle oyun ekleyebilirsiniz."
        case .invalidResponse: "RAWG'den geçerli bir yanıt alınamadı. Elle ekleme kullanılabilir."
        case .unauthorized: "RAWG API anahtarı veya erişim izni geçersiz."
        case .rateLimited: "RAWG istek kotası doldu. Lütfen daha sonra tekrar deneyin veya elle ekleyin."
        case .serverError: "RAWG şu anda yanıt veremiyor. Lütfen tekrar deneyin veya elle ekleyin."
        case .offline: "Ağ bağlantısı kurulamadı. Tekrar deneyebilir veya elle ekleyebilirsiniz."
        case .timedOut: "RAWG isteği zaman aşımına uğradı. Tekrar deneyebilir veya elle ekleyebilirsiniz."
        }
    }
}

struct RAWGService {
    static let attributionURL = URL(string: "https://rawg.io/")!
    private let session: URLSession

    init(session: URLSession = URLSession(configuration: .ephemeral)) { self.session = session }

    static func safeSourceURL(_ value: String?) -> URL {
        guard let value, let url = URL(string: value), url.scheme == "https",
              url.host == "rawg.io", url.user == nil, url.password == nil,
              url.port == nil, url.query == nil, url.fragment == nil else { return attributionURL }
        return url
    }

    func search(query: String, page: Int, apiKey: String) async throws -> RAWGSearchResponse {
        try await games(query: query, page: page, apiKey: apiKey)
    }

    func catalogPage(_ page: Int, apiKey: String) async throws -> RAWGSearchResponse {
        try await games(query: nil, page: page, apiKey: apiKey)
    }

    private func games(query: String?, page: Int, apiKey: String) async throws -> RAWGSearchResponse {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw RAWGServiceError.missingKey }
        guard page > 0 else { throw RAWGServiceError.invalidResponse }
        var components = URLComponents(string: "https://api.rawg.io/api/games")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: "20"), URLQueryItem(name: "key", value: apiKey)
        ]
        if let query { components.queryItems?.append(URLQueryItem(name: "search", value: query)) }
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 30
        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            // URLSession hataları anahtarlı adresi taşıyabilir; dışarı yalnızca sınıflandırılmış hata çıkar.
            throw error.code == .timedOut ? RAWGServiceError.timedOut : RAWGServiceError.offline
        }
        catch is CancellationError { throw CancellationError() }
        catch { throw RAWGServiceError.offline }
        guard let response = response as? HTTPURLResponse else { throw RAWGServiceError.invalidResponse }
        switch response.statusCode {
        case 200...299: break
        case 401, 403: throw RAWGServiceError.unauthorized
        case 429: throw RAWGServiceError.rateLimited
        case 500...599: throw RAWGServiceError.serverError
        default: throw RAWGServiceError.invalidResponse
        }
        do { return try JSONDecoder().decode(RAWGSearchResponse.self, from: data) }
        catch { throw RAWGServiceError.invalidResponse }
    }
}

@MainActor @Observable final class CatalogSearchSession {
    private(set) var query = ""
    private(set) var results: [RAWGGame] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    private(set) var hasNextPage = false
    private(set) var hasSearched = false
    private var page = 0
    private var failedPage: Int?
    private let fetch: (String, Int, String) async throws -> RAWGSearchResponse

    init(fetch: @escaping (String, Int, String) async throws -> RAWGSearchResponse = { query, page, key in
        #if DEBUG
        if Game_libraryApp.usesTestStorage && ProcessInfo.processInfo.arguments.contains("--ui-testing-offline") {
            throw RAWGServiceError.offline
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-catalog") {
            let rows = (1...20).map { ["id": $0, "name": "Katalog Oyunu \($0)"] as [String: Any] }
            let data = try JSONSerialization.data(withJSONObject: ["results": rows])
            return try JSONDecoder().decode(RAWGSearchResponse.self, from: data)
        }
        #endif
        return try await RAWGService().search(query: query, page: page, apiKey: key)
    }) { self.fetch = fetch }

    func search(_ text: String, apiKey: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isSearching, !text.isEmpty else { return }
        query = text
        page = 0
        results = []
        hasNextPage = false
        await request(page: 1, apiKey: apiKey)
    }

    func loadNext(apiKey: String) async {
        guard !isSearching, hasNextPage else { return }
        await request(page: page + 1, apiKey: apiKey)
    }

    func retry(apiKey: String) async {
        guard !isSearching, let failedPage else { return }
        await request(page: failedPage, apiKey: apiKey)
    }

    private func request(page target: Int, apiKey: String) async {
        isSearching = true
        errorMessage = nil
        failedPage = nil
        defer { isSearching = false }
        do {
            let response = try await fetch(query, target, apiKey)
            try Task.checkCancellation()
            var ids = Set(results.map(\.id))
            results += response.results.filter { ids.insert($0.id).inserted }
            page = target
            hasNextPage = response.next != nil
            hasSearched = true
        } catch is CancellationError {
        } catch {
            failedPage = target
            errorMessage = (error as? RAWGServiceError)?.errorDescription
                ?? "Ağ bağlantısı kurulamadı veya istek zaman aşımına uğradı. Tekrar deneyebilir veya elle ekleyebilirsiniz."
        }
    }
}
