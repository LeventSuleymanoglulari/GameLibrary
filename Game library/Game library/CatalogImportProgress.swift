import SwiftData

// Anahtar, sorgu, API next adresi veya kişisel durumlar burada saklanmaz.
@Model final class CatalogImportProgress {
    var nextPage: Int = 1
    var isComplete: Bool = false
    var importedCount: Int = 0

    init() {}
}
