# Uno de Nosotros — v2 (UI nativa)

Versión 2 del proyecto: misma lógica de juego, mismo cliente de Gemini y mismas reglas que la v1, pero la interfaz
se rehízo con componentes nativos de SwiftUI (`NavigationStack`, `Form`, `List`, `Stepper`, `Picker`,
`ContentUnavailableView`, SF Symbols, tipografía del sistema y modo oscuro). Bundle id: `mx.iest.UnoDeNosotrosV2`.

Juego social de deducción para jugar en grupo con un solo iPhone (modo *pasa el celular*).
Todos reciben la misma palabra secreta excepto uno o dos impostores, que reciben una palabra señuelo
(**hint**) generada por IA (Gemini). Cada jugador da una pista en voz alta y al final el grupo vota.

Proyecto semestral de iOS — Andrea Vega Fong, Edgar Emiliano Jaime Romero, Americo Gudini Granados
y Sebastian Moctezuma Toral.

## Pantallas

| # | Pantalla | Qué hace |
|---|----------|----------|
| 1 | Inicio | Logo, ilustración y botón **Comenzar a jugar** (más acceso al historial). |
| 2 | Configuración | Número y nombres de jugadores, categoría (Animal, Comida, Cine, Países) y 1 o 2 impostores. **Iniciar ronda** llama a Gemini. |
| 3 | Ronda de palabra | Un jugador a la vez: toca la tarjeta para ver su palabra, o *¡ERES EL IMPOSTOR!* con su hint. |
| 4 | Votación | Cada jugador elige a quién cree impostor (sin poder votarse a sí mismo). |
| 5 | Resultados | Revela impostores, palabra real vs. hint, quién ganó, desglose de votos y puntos de la ronda. |
| 6 | Historial | Jugadores guardados y sus estadísticas: partidas, veces impostor, veces descubierto, votos acertados, racha actual y mejor racha. |

### Reglas de puntaje

- Un impostor queda **descubierto** si recibe al menos un voto y ningún tripulante recibe más votos que él (los empates cuentan como descubierto).
- Los tripulantes ganan si descubren a **todos** los impostores.
- +1 punto a cada tripulante que votó por un impostor.
- +2 puntos al impostor que no fue descubierto.

## Requisitos

- Xcode 26 o más reciente, iOS 17+.
- Una API key de Gemini.

## Configuración de la API key

La key **no** se sube al repo. Copia la plantilla y pega tu key:

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
# edita Config/Secrets.xcconfig → GEMINI_API_KEY = tu_key
```

El modelo se cambia en `Config/Base.xcconfig` (`GEMINI_MODEL`, por defecto `gemini-flash-latest`).

## Estructura

```
UnoDeNosotros/
├── App/                 Entrada de la app, navegación (AppRouter) y RootView
├── Models/              Player, WordCategory, SecretWords, Round, PlayerStats
├── Game/                GameEngine (reglas puras) y GameSession (estado de la partida)
├── Services/
│   ├── AI/              Cliente de Gemini (WordGenerating → GeminiWordGenerator)
│   └── Persistence/     Historial, palabras usadas y última configuración (UserDefaults)
├── Features/            Una carpeta por pantalla (Home, Setup, WordRound, Voting, Results, Profiles) + Shared
└── Resources/           Assets (ícono y color de acento) y Localizable.xcstrings
UnoDeNosotrosTests/      Pruebas de las reglas del juego (Swift Testing)
Config/                  xcconfig, Info.plist y secretos
```

- **Persistencia:** `PlayerStatsStore` guarda el historial de cada jugador en `UserDefaults` (JSON). Los jugadores se identifican por nombre (sin distinguir mayúsculas ni acentos).
- **Sin repetir palabras:** `UsedWordsStore` recuerda las palabras ya jugadas por categoría e idioma y se las manda a Gemini para que no las repita.
- **Localización:** español (base), inglés y coreano en `Localizable.xcstrings`. Las palabras de Gemini se generan en el idioma activo de la app.

## Desarrollo

```bash
xcodebuild -project UnoDeNosotros.xcodeproj -scheme UnoDeNosotros \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

En Debug se puede abrir una pantalla con datos de ejemplo usando el argumento de lanzamiento
`-demoScreen <setup|wordRound|impostor|voting|results|profiles>` (Scheme → Run → Arguments).
