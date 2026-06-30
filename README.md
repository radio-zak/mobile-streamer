# ŻAK Streamer

Aplikacja mobilna do streamingu Studenckiego Radia ŻAK Politechniki Łódzkiej. Dostępna na Android i iOS.

Zbudowana w Flutter z wykorzystaniem `just_audio` i `audio_service`.

---

## Funkcje

- Odtwarzanie strumienia radia ŻAK na żywo
- Ramówka tygodniowa z automatycznym podświetleniem aktualnej audycji
- Informacja o aktualnie granej audycji (Now Playing)
- Powiadomienia o błędach połączenia z możliwością wznowienia
- Obsługa sterowania z poziomu powiadomień i ekranu blokady (MediaSession)
- Obsługa Android Auto

---

## Wymagania

- Flutter SDK ≥ 3.x ([instrukcja instalacji](https://docs.flutter.dev/install/manual))
- Android: Android Studio + Android SDK API 21+
- iOS: Xcode 14+ (wymagany Mac)
- Ruby + Bundler (tylko dla Fastlane / CI)

---

## Uruchomienie lokalne

```bash
# Pobierz zależności
flutter pub get

# Sprawdź dostępne urządzenia/emulatory
flutter devices
flutter emulators

# Uruchom emulator Android
flutter emulators --launch Medium_Phone

# Uruchom aplikację w trybie debug
flutter run -d <device-id>

# Statyczna analiza kodu
flutter analyze

# Testy jednostkowe
flutter test
```

> **Uwaga:** Budowanie release wymaga pliku `android/key.properties` z kluczem podpisywania.
> Lokalnie aplikacja buduje się poprawnie w trybie debug bez tego pliku.

---

## Struktura projektu

```
lib/
├── main.dart                  # Punkt wejścia, konfiguracja motywu
├── page_manager.dart          # Zarządzanie stanem odtwarzacza
├── streamer.dart              # AudioHandler (just_audio + audio_service)
├── now_playing.dart           # Logika "teraz gramy"
├── schedule_service.dart      # Pobieranie i parsowanie ramówki z zak.lodz.pl
├── service_locator.dart       # Dependency injection (get_it)
├── notifications.dart         # Powiadomienia lokalne
├── pages/
│   ├── home_page.dart         # Strona główna z przyciskiem play
│   └── schedule_page.dart     # Strona ramówki tygodniowej
└── widgets/
    ├── play_button.dart       # Przycisk play/pause z animacją
    ├── now_playing_widget.dart
    └── schedule_list_entry.dart

android/fastlane/              # Konfiguracja Fastlane dla Androida
ios/fastlane/                  # Konfiguracja Fastlane dla iOS
.github/workflows/             # Pipelines CI/CD GitHub Actions
```

---

## CI/CD

| Workflow | Trigger | Opis |
|----------|---------|------|
| `pr-analyze.yaml` | PR do `main` | Lint, analyze, testy jednostkowe |
| `test-build.yaml` | PR do `main` | Testowy build Android |
| `build-alpha.yaml` | Push do `main` | Build + upload do TestFlight / Play Internal |
| `release.yml` | Ręczny / tag | Promocja do Production |

### Wymagane GitHub Secrets

| Secret | Opis |
|--------|------|
| `ANDROID_SIGNING_KEY` | Keystore Base64 do podpisywania APK/AAB |
| `ANDROID_KEY_ALIAS` | Alias klucza w keystorze |
| `ANDROID_KEY_PASSWORD` | Hasło klucza |
| `ANDROID_STORE_PASSWORD` | Hasło keystora |
| `FIREBASE_SERVICE_ACCOUNT` | Konto serwisowe Google Play |
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_KEY_P8` | App Store Connect klucz prywatny (Base64) |
| `MATCH_PASSWORD` | Hasło do szyfrowania certyfikatów Match |
| `MATCH_GIT_PRIVATE_KEY` | Klucz SSH do repozytorium Match |
| `APPLE_ID` | Apple ID dewelopera |

---

## Bezpieczeństwo

- Wszystkie połączenia uzywają HTTPS.
- Znalezione i naprawione podatności opisane są w historii commitów (`security: fix multiple vulnerabilities`, `chore: switch endpoint to https and disable cleartext traffic`).

Zgłaszanie podatności: utwórz prywatne [Security Advisory](https://github.com/radio-zak/mobile-streamer/security/advisories/new) na GitHubie.

---

## Licencja

Kod projektu jest objęty licencją **AGPLv3**.

Zasoby graficzne (logo „88,8MHz" i jego warianty) są własnością Studenckiego Radia ŻAK Politechniki Łódzkiej. Ich użycie w projektach pochodnych wymaga pisemnej zgody opiekuna projektu.

---

## Kontakt

- Opiekun projektu: Kacper Zieliński — <kacper.zielinski@zak.lodz.pl>
- Studenckie Radio ŻAK PŁ: <https://www.zak.lodz.pl>
