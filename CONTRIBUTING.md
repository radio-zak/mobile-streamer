# Jak współtworzyć projekt

Dziękujemy za zainteresowanie rozwojem aplikacji ŻAK Streamer!

---

## Zanim zaczniesz

1. Przeczytaj [README.md](README.md) — konfiguracja środowiska i uruchomienie lokalne.
2. Sprawdź [otwarte Issues](https://github.com/radio-zak/mobile-streamer/issues) — być może ktoś już pracuje nad tym samym.
3. Dla większych zmian — otwórz najpierw Issue z opisem planowanej zmiany, żeby omówić podejście.

---

## Workflow

1. Forkuj repozytorium
2. Utwórz branch od `main`:
   ```bash
   git checkout -b feature/nazwa-funkcji
   # lub
   git checkout -b fix/opis-buga
   # lub
   git checkout -b security/opis-podatnosci
   ```
3. Wprowadź zmiany, upewnij się że:
   - `flutter analyze` nie zgłasza błędów
   - `flutter test` przechodzi
4. Wypchnij branch i otwórz Pull Request do `main`

Branch `main` jest chroniony — każdy PR wymaga:
- przejścia `pr-analyze.yaml` (lint + analyze + testy)
- przejścia `test-build.yaml` (build Android)
- przeglądu kodu przez maintainera

---

## Konwencje commitów

Projekt stosuje [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: dodaj sleep timer
fix: popraw crash przy braku sieci
security: walidacja URL w playFromMediaId
chore: aktualizacja zależności
docs: rozszerz README o sekcję CI/CD
refactor: wyodrębnij cache ramówki do osobnego serwisu
test: dodaj testy dla ScheduleService
```

---

## Standardy kodu

- Dart: zgodność z `analysis_options.yaml` w root projektu
- Nazewnictwo: snake_case dla plików, camelCase dla zmiennych, PascalCase dla klas
- Nie commituj plików generowanych (`build/`, `*.g.dart`, `*.freezed.dart`)
- Nie commituj sekretów — wszystkie klucze przez GitHub Secrets lub zmienne środowiskowe

---

## Testy

```bash
flutter test                    # wszystkie testy
flutter test test/streamer_test.dart   # konkretny plik
```

Nowy kod powinien być pokryty testami jednostkowymi. Testy integracyjne mile widziane.

---

## Zgłaszanie podatności bezpieczeństwa

**Nie otwieraj publicznego Issue dla podatności.**

Użyj [GitHub Security Advisory](https://github.com/radio-zak/mobile-streamer/security/advisories/new) — pozwala na prywatne zgłoszenie i skoordynowane ujawnienie.

---

## Pytania

Otwórz [Discussion](https://github.com/radio-zak/mobile-streamer/discussions) lub napisz na <kacper.zielinski@zak.lodz.pl>.
