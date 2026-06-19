# Zadania po stronie serwera

Poniższe kroki są wymagane po stronie infrastruktury radia, aby w pełni usunąć podatności zidentyfikowane w audycie bezpieczeństwa aplikacji.

---

## 1. Włączenie HTTPS na serwerze strumieniowym (PRIORYTET KRYTYCZNY)

**Serwer:** `ra.man.lodz.pl:8000` (Icecast / Shoutcast)

Aplikacja mobilna została zaktualizowana tak, aby łączyć się przez `https://ra.man.lodz.pl:8000/radiozak6.mp3`. Jeżeli serwer nie obsługuje TLS na tym porcie, strumień przestanie działać.

**Co należy zrobić:**

1. Uzyskać certyfikat TLS dla domeny `ra.man.lodz.pl`:
   - **Bezpłatnie:** Let's Encrypt (via `certbot`)
   - **Alternatywnie:** certyfikat od uczelnianego CA (HARICA — już zaufany w aplikacji)

2. Skonfigurować TLS w Icecast2 (`/etc/icecast2/icecast.xml`):
   ```xml
   <listen-socket>
       <port>8443</port>
       <ssl>1</ssl>
   </listen-socket>
   <ssl>
       <certificate>/etc/letsencrypt/live/ra.man.lodz.pl/fullchain.pem</certificate>
       <key>/etc/letsencrypt/live/ra.man.lodz.pl/privkey.pem</key>
   </ssl>
   ```
   > Uwaga: Icecast2 obsługuje TLS natywnie od wersji 2.4. Alternatywnie można użyć reverse proxy (nginx/caddy) z SSL termination przed Icecastem.

3. Zaktualizować port strumienia w aplikacji mobilnej (`lib/streamer.dart`) po zmianie portu:
   ```dart
   id: "https://ra.man.lodz.pl:8443/radiozak6.mp3",
   ```
   lub jeśli skonfigurujesz reverse proxy na standardowym porcie 443:
   ```dart
   id: "https://ra.man.lodz.pl/radiozak6.mp3",
   ```

4. Przetestować połączenie:
   ```bash
   curl -v https://ra.man.lodz.pl:8443/radiozak6.mp3 --max-time 5
   ```

---

## 2. Tymczasowe obejście (do czasu wdrożenia HTTPS)

Jeżeli migracja na HTTPS nie jest możliwa natychmiast, należy cofnąć zmianę URL w aplikacji do `http://`:

```dart
// lib/streamer.dart
id: "http://ra.man.lodz.pl:8000/radiozak6.mp3",
```

Wyjątek domenowy w `AndroidManifest` (`network_security_config.xml`) i `Info.plist` dla `ra.man.lodz.pl` już jest skonfigurowany i umożliwia ruch HTTP wyłącznie do tego hosta — nie jest to więc podatność globalna, lecz celowy wyjątek.

---

## 3. Ustawienie sekretu APPLE_ID w GitHub

Plik `ios/fastlane/Appfile` odczytuje teraz `apple_id` ze zmiennej środowiskowej:

```ruby
apple_id(ENV["APPLE_ID"])
```

**Co należy zrobić:**

W ustawieniach repozytorium GitHub → **Settings → Secrets and variables → Actions** dodać sekret:

| Nazwa       | Wartość                     |
|-------------|-----------------------------|
| `APPLE_ID`  | `kml.zielin@gmail.com`      |

---

## Status

| Zadanie | Status |
|---------|--------|
| HTTPS na serwerze strumieniowym | ⏳ Oczekuje na wdrożenie |
| Sekret `APPLE_ID` w GitHub Actions | ⏳ Oczekuje na dodanie |
