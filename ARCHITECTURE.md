# Architektura aplikacji

Dokument opisuje strukturę i przepływ danych w aplikacji ŻAK Streamer.

---

## Stos technologiczny

| Warstwa | Technologia |
|---------|-------------|
| Framework | Flutter (Dart) |
| Audio playback | `just_audio` + `audio_service` |
| Dependency injection | `get_it` |
| HTTP | `http` (dart) |
| HTML parsing | `html` |
| Animacje | `simple_animations` |
| Powiadomienia | `flutter_local_notifications` |
| Fonts | `google_fonts` (Sora) |

---

## Dependency Injection

Aplikacja używa `get_it` jako service locator. Rejestracja zależności w `service_locator.dart`:

```
get_it
├── AudioHandler     (singleton — Streamer)
├── PageManager      (singleton)
├── ScheduleService  (singleton)
└── NowPlaying       (singleton)
```

Dostęp: `getIt<AudioHandler>()`, `getIt<PageManager>()` itd.

---

## Przepływ danych odtwarzacza

```
PageManager
    │
    ├─▶ AudioHandler (Streamer)
    │       │
    │       └─▶ AudioPlayer (just_audio)
    │               │
    │               └─▶ Strumień HTTP: ra.man.lodz.pl:8000/radiozak6.mp3
    │
    ├─▶ playButtonNotifier (ValueNotifier<ButtonState>)
    │       └─▶ PlayButton widget
    │
    └─▶ NowPlaying
            │
            ├─▶ ScheduleService ──▶ zak.lodz.pl (HTML scraping)
            ├─▶ nowPlayingNotifier (ValueNotifier<NowPlayingState>)
            └─▶ nowPlayingContents (ValueNotifier<ScheduleEntry?>)
                    └─▶ NowPlayingWidget
```

---

## AudioHandler (Streamer)

`Streamer` dziedziczy po `BaseAudioHandler` z `audio_service`. Jest to warstwa pomiędzy UI a `AudioPlayer`.

Odpowiada za:
- Zarządzanie stanem odtwarzacza (`playbackState`)
- Wykrywanie i obsługę błędów (timeout połączenia, buffering error)
- Aktualizację metadanych MediaSession (tytuł, artysta)
- Walidację URI przed odtworzeniem (`playFromMediaId`)

Ważne: `AudioService` jest zarejestrowany z `android:exported="true"` — wymagane przez Android Auto i sterowanie z poziomu systemu. Z tego powodu `playFromMediaId` waliduje host i schemat URL przed odtworzeniem.

---

## Ramówka i Now Playing

`ScheduleService` pobiera ramówkę przez HTTP scraping strony `https://www.zak.lodz.pl/ramowka/plan/{1-7}/...`. Parsowanie odbywa się po stronie klienta z użyciem biblioteki `html`.

`NowPlaying` uruchamia timer co minutę i porównuje aktualny czas z harmonogramem audycji. Aktualizuje:
- `nowPlayingContents` — aktualna audycja (`ScheduleEntry?`)
- `nowPlayingNotifier` — stan (inactive / loading / active)
- Metadane w AudioHandler (widoczne w powiadomieniu i Android Auto)

**Znane ograniczenie:** `SchedulePage` i `NowPlaying` wykonują osobne requesty do `ScheduleService`. Brak wspólnego cache — do poprawy w przyszłości.

---

## Powiadomienia

`Notifications` (singleton) używa `flutter_local_notifications`. Wyświetla powiadomienia o błędach połączenia z payloadem `reconnect`. Kliknięcie powiadomienia wznawia odtwarzanie przez `PageManager.play()`.

---

## CI/CD (GitHub Actions)

```
PR do main
    ├── pr-analyze.yaml    → flutter analyze + flutter test
    └── test-build.yaml    → gradle assembleDebug

Merge do main
    └── build-alpha.yaml
            ├── flutter build apk --release
            ├── flutter build ipa --release
            ├── fastlane android internal  → Google Play Internal
            └── fastlane ios alpha_upload  → TestFlight

Ręczny trigger / tag
    └── release.yml
            ├── fastlane android alpha/production
            └── fastlane ios production
```

Podpisywanie Android: keystore generowany dynamicznie z Base64 w GitHub Secrets (`ANDROID_SIGNING_KEY`).
Podpisywanie iOS: certyfikaty zarządzane przez Fastlane Match.

---

## Bezpieczeństwo sieci

Komunikacja z serwersem strumieniującym występuje z uzyciem HTTPS.
