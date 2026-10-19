import Foundation

/// Request/response bodies for `models/{model}:generateContent`.
nonisolated enum GeminiDTO {
    struct Request: Encodable {
        let systemInstruction: Content
        let contents: [Content]
        let generationConfig: GenerationConfig
    }

    struct Content: Codable {
        var role: String?
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String?
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
        let responseMimeType: String
        let responseSchema: Schema
        let thinkingConfig: ThinkingConfig
    }

    struct ThinkingConfig: Encodable {
        let thinkingBudget: Int
    }

    final class Schema: Encodable {
        let type: String
        let properties: [String: Schema]?
        let required: [String]?
        let description: String?

        init(type: String, properties: [String: Schema]? = nil, required: [String]? = nil, description: String? = nil) {
            self.type = type
            self.properties = properties
            self.required = required
            self.description = description
        }
    }

    struct Response: Decodable {
        struct Candidate: Decodable {
            let content: Content?
        }
        let candidates: [Candidate]?
    }
}
