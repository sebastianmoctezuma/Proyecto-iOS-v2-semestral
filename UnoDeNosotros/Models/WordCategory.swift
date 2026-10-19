import Foundation

nonisolated enum WordCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case animals
    case food
    case movies
    case countries

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .animals: "Animal"
        case .food: "Comida"
        case .movies: "Cine"
        case .countries: "Países"
        }
    }

    var symbol: String {
        switch self {
        case .animals: "pawprint.fill"
        case .food: "takeoutbag.and.cup.and.straw.fill"
        case .movies: "film.fill"
        case .countries: "globe.americas.fill"
        }
    }

    /// Category description sent to the AI prompt (always in English for consistency).
    var promptDescription: String {
        switch self {
        case .animals: "animals"
        case .food: "food and drinks"
        case .movies: "famous movies or movie-related things (titles, characters, genres)"
        case .countries: "countries of the world"
        }
    }
}
