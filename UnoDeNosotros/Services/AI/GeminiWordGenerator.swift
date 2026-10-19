import Foundation

/// Uses the Gemini API to create a fresh word + decoy for every round.
nonisolated struct GeminiWordGenerator: WordGenerating {
    var apiKey: String?
    var model: String
    var session: URLSession = .shared
    var maxAttempts = 3

    init(apiKey: String? = AppConfig.geminiAPIKey, model: String = AppConfig.geminiModel) {
        self.apiKey = apiKey
        self.model = model
    }

    func generateWords(
        for category: WordCategory,
        languageName: String,
        avoiding usedWords: [String]
    ) async throws -> SecretWords {
        guard let apiKey else { throw WordGenerationError.missingAPIKey }

        let avoided = Set(usedWords.map(Self.normalize))
        var lastError: Error = WordGenerationError.invalidContent

        for _ in 0..<maxAttempts {
            do {
                let words = try await requestWords(category: category, language: languageName, avoiding: usedWords, apiKey: apiKey)
                if Self.isValid(words, avoiding: avoided) {
                    return SecretWords(word: Self.clean(words.word), hint: Self.clean(words.hint))
                }
                lastError = WordGenerationError.invalidContent
            } catch let error as WordGenerationError {
                if case .badResponse(let code) = error, (400..<500).contains(code), code != 429 { throw error }
                lastError = error
            } catch {
                lastError = WordGenerationError.network(error.localizedDescription)
            }
        }
        throw lastError
    }

    // MARK: - Request

    private func requestWords(category: WordCategory, language: String, avoiding: [String], apiKey: String) async throws -> SecretWords {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(makeBody(category: category, language: language, avoiding: avoiding))

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WordGenerationError.badResponse(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(GeminiDTO.Response.self, from: data)
        guard let text = decoded.candidates?.first?.content?.parts.compactMap(\.text).joined(),
              let json = text.data(using: .utf8),
              let words = try? JSONDecoder().decode(SecretWords.self, from: json) else {
            throw WordGenerationError.invalidContent
        }
        return words
    }

    private func makeBody(category: WordCategory, language: String, avoiding: [String]) -> GeminiDTO.Request {
        let system = """
        You create content for "Uno de Nosotros", a party deduction game. All players receive the same \
        secret word except the impostor, who receives a decoy word ("hint") that is related or similar \
        enough to help them blend in, but clearly different from the secret word.
        Rules:
        - Both words belong to the requested category and are written in \(language).
        - Each one is a common, family-friendly noun of 1 to 3 words that most people know.
        - The hint must never be the same word, a translation, or a plural of the secret word.
        - Pick surprising, varied words; never repeat the words listed to avoid.
        - Return only JSON matching the schema.
        """

        let avoidLine = avoiding.isEmpty ? "" : "\nWords to avoid: \(avoiding.suffix(60).joined(separator: ", "))."
        let user = "Category: \(category.promptDescription).\(avoidLine)\nRandom seed: \(UUID().uuidString.prefix(8))"

        let schema = GeminiDTO.Schema(
            type: "OBJECT",
            properties: [
                "word": .init(type: "STRING", description: "Secret word shared by the crew"),
                "hint": .init(type: "STRING", description: "Related decoy word for the impostor")
            ],
            required: ["word", "hint"]
        )

        return GeminiDTO.Request(
            systemInstruction: .init(parts: [.init(text: system)]),
            contents: [.init(role: "user", parts: [.init(text: user)])],
            generationConfig: .init(
                temperature: 1.1,
                responseMimeType: "application/json",
                responseSchema: schema,
                thinkingConfig: .init(thinkingBudget: 0)
            )
        )
    }

    // MARK: - Validation

    static func normalize(_ text: String) -> String {
        clean(text).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }

    static func isValid(_ words: SecretWords, avoiding avoided: Set<String>) -> Bool {
        let word = normalize(words.word)
        let hint = normalize(words.hint)
        return !word.isEmpty && !hint.isEmpty && word != hint && word.count <= 40 && hint.count <= 40
            && !avoided.contains(word)
    }
}
