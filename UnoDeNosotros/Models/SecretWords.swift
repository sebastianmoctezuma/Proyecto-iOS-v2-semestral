import Foundation

/// The pair generated for every round: the real word and the impostor's decoy ("hint").
nonisolated struct SecretWords: Codable, Equatable, Sendable {
    let word: String
    let hint: String
}
