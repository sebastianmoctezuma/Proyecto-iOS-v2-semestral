import Foundation

/// Generates the secret word and the impostor's decoy for a category.
nonisolated protocol WordGenerating: Sendable {
    func generateWords(
        for category: WordCategory,
        languageName: String,
        avoiding usedWords: [String]
    ) async throws -> SecretWords
}

nonisolated enum WordGenerationError: LocalizedError, Equatable {
    case missingAPIKey
    case network(String)
    case badResponse(Int)
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            String(localized: "Falta la API key de Gemini. Revisa Config/Secrets.xcconfig.")
        case .network:
            String(localized: "No hay conexión. Revisa tu internet e inténtalo de nuevo.")
        case .badResponse(let code):
            String(localized: "El servicio de IA respondió con un error (\(code)).")
        case .invalidContent:
            String(localized: "La IA no generó una palabra válida. Inténtalo de nuevo.")
        }
    }
}
