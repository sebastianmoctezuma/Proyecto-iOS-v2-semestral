import Foundation

/// Values injected at build time from `Config/*.xcconfig` through `Config/Info.plist`.
nonisolated enum AppConfig {
    static var geminiAPIKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String,
              !key.isEmpty, !key.hasPrefix("$("), key != "YOUR_GEMINI_API_KEY" else {
            return nil
        }
        return key
    }

    static var geminiModel: String {
        let model = Bundle.main.object(forInfoDictionaryKey: "GeminiModel") as? String
        guard let model, !model.isEmpty, !model.hasPrefix("$(") else { return "gemini-flash-latest" }
        return model
    }

    /// Name of the language the app is currently displayed in, for the AI prompt.
    static var contentLanguageName: String {
        switch Bundle.main.preferredLocalizations.first ?? "es" {
        case let code where code.hasPrefix("en"): "English"
        case let code where code.hasPrefix("ko"): "Korean"
        default: "Mexican Spanish"
        }
    }

    static var contentLanguageCode: String {
        String((Bundle.main.preferredLocalizations.first ?? "es").prefix(2))
    }
}
