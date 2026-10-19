import Foundation

/// Remembers the last configuration so the Setup screen opens pre-filled.
final class LastSetupStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var playerNames: [String] {
        get { defaults.stringArray(forKey: "lastSetup.players") ?? [] }
        set { defaults.set(newValue, forKey: "lastSetup.players") }
    }

    var category: WordCategory {
        get { defaults.string(forKey: "lastSetup.category").flatMap(WordCategory.init) ?? .animals }
        set { defaults.set(newValue.rawValue, forKey: "lastSetup.category") }
    }

    var impostorCount: Int {
        get { max(1, defaults.integer(forKey: "lastSetup.impostors")) }
        set { defaults.set(newValue, forKey: "lastSetup.impostors") }
    }
}
