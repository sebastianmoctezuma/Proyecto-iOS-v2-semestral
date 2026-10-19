import Foundation

/// Remembers the words already played per category/language so the AI never repeats them.
final class UsedWordsStore {
    private let defaults: UserDefaults
    private let limit = 80

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func words(for category: WordCategory, language: String) -> [String] {
        defaults.stringArray(forKey: key(category, language)) ?? []
    }

    func remember(_ words: SecretWords, for category: WordCategory, language: String) {
        var list = self.words(for: category, language: language)
        list.append(contentsOf: [words.word, words.hint])
        defaults.set(Array(list.suffix(limit)), forKey: key(category, language))
    }

    private func key(_ category: WordCategory, _ language: String) -> String {
        "usedWords.\(language).\(category.rawValue)"
    }
}
