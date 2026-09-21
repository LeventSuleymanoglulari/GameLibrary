//
//  RAWGService.swift
//  Game library
//

import Foundation

struct RAWGGame: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let released: String?
    let slug: String?
    let platforms: [PlatformContainer]?

    struct PlatformContainer: Decodable, Hashable {
        let platform: Platform
    }

    struct Platform: Decodable, Hashable {
        let name: String
    }

    var sourceURL: URL? {
        guard let slug, !slug.isEmpty else { return nil }
        return URL(string: "https://rawg.io/games/\(slug)")
    }

    var platformNames: [String] {
        Array(Set(platforms?.map(\.platform.name) ?? [])).sorted()
    }
}

struct RAWGSearchResponse: Decodable {
    let next: URL?
    let results: [RAWGGame]
}

enum RAWGServiceError: LocalizedError {
    case missingKey
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError

    var errorDescription: String? {
        switch self {
        case .missingKey: "RAWG API anahtarı gerekli. Ayarlardan ekleyebilir veya elle oyun ekleyebilirsiniz."
        case .invalidResponse: "RAWG'den geçerli bir yanıt alınamadı."
        case .unauthorized: "RAWG API anahtarı veya erişim izni geçersiz."
        case .rateLimited: "RAWG istek kotası doldu. Lütfen daha sonra tekrar deneyin veya elle ekleyin."
        case .serverError: "RAWG şu anda yanıt veremiyor. Lütfen tekrar deneyin veya elle ekleyin."
        }
    }
}

struct RAWGService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func search(query: String, page: Int, apiKey: String) async throws -> RAWGSearchResponse {
        guard !apiKey.isEmpty else { throw RAWGServiceError.missingKey }
        var components = URLComponents(string: "https://api.rawg.io/api/games")!
        components.queryItems = [
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        let (data, response) = try await session.data(from: components.url!)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RAWGServiceError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299: break
        case 401, 403: throw RAWGServiceError.unauthorized
        case 429: throw RAWGServiceError.rateLimited
        case 500...599: throw RAWGServiceError.serverError
        default: throw RAWGServiceError.invalidResponse
        }
        return try JSONDecoder().decode(RAWGSearchResponse.self, from: data)
    }
}
