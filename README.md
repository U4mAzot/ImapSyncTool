# ImapSyncTool - migracja poczty między skrzynkami IMAP

Skrypt wsadowy (`.bat`) dla Windows, który prowadzi technika krok po kroku przez
kopiowanie poczty z jednej skrzynki do drugiej przy użyciu narzędzia
[imapsync](https://imapsync.lamiral.info/). Typowe zastosowania:

- przeniesienie poczty pracownika do nowego dostawcy (np. z hostingu na Microsoft 365),
- zmiana domeny firmy,
- połączenie dwóch skrzynek w jedną,
- kopia zapasowa skrzynki na inny serwer.

## Funkcje

- Interaktywne pytania o **serwer, login, port i hasło** obu skrzynek
- **Ukryte wpisywanie haseł** (gwiazdki zamiast znaków)
- Hasła przekazywane do imapsync przez tymczasowe pliki `--passfile`, a nie w linii poleceń,
  gdzie byłyby widoczne dla innych procesów. Pliki są usuwane po zakończeniu pracy.
- Poprawna obsługa haseł ze znakami specjalnymi (`& ! % ^ "`)
- Obsługa szyfrowania: port **993 → SSL**, port **143 → STARTTLS**
- Trzy tryby pracy:

| Tryb | Opcja imapsync | Co robi |
|------|----------------|---------|
| 1. Test logowania | `--justlogin` | sprawdza tylko, czy dane logowania są poprawne |
| 2. Symulacja | `--dry` | pokazuje, co zostanie skopiowane, niczego nie zmienia |
| 3. Migracja | - | kopiuje pocztę (z potwierdzeniem) |

- Menu w pętli: po teście i symulacji można od razu uruchomić migrację bez ponownego wpisywania danych
- `--automap`: automatyczne dopasowanie folderów specjalnych (np. `Sent` ↔ `Wysłane`, `Trash` ↔ `Kosz`)
- `--syncinternaldates`: zachowanie oryginalnych dat wiadomości
- Osobny log dla każdego uruchomienia w folderze `logs\`

## Instalacja

1. Pobierz `imapsync.exe` ze strony https://imapsync.lamiral.info/ (sekcja Windows).
2. Umieść `imapsync.exe` w tym samym folderze co `imapsync_migracja.bat` (albo dodaj go do `PATH`).
3. Uruchom `imapsync_migracja.bat` dwuklikiem.

## Przykładowy przebieg

```
===========================================================
   MIGRACJA POCZTY IMAP  (imapsync)
===========================================================

--- SKRZYNKA ZRODLOWA (z ktorej kopiujemy) ---------------
  Serwer IMAP (np. imap.stara-firma.pl): mail.stary-hosting.pl
  Login (zwykle pelny adres e-mail): jan.kowalski@firma.pl
  Port [Enter = 993 SSL, 143 = STARTTLS]:
  Haslo (niewidoczne): ************

--- SKRZYNKA DOCELOWA (do ktorej kopiujemy) --------------
  Serwer IMAP (np. imap.nowa-firma.pl): outlook.office365.com
  Login (zwykle pelny adres e-mail): jan.kowalski@firma.pl
  Port [Enter = 993 SSL, 143 = STARTTLS]:
  Haslo (niewidoczne): ************

===========================================================
 Z:  jan.kowalski@firma.pl  (mail.stary-hosting.pl:993)
 Do: jan.kowalski@firma.pl  (outlook.office365.com:993)
===========================================================
 1 - Test logowania  (sprawdza tylko polaczenie i hasla)
 2 - Symulacja       (pokazuje, co zostanie skopiowane - nic nie zmienia)
 3 - MIGRACJA        (kopiuje poczte do skrzynki docelowej)
 4 - Zakoncz
```

## Zalecana procedura migracji

1. **Test logowania**, żeby sprawdzić, czy dane obu skrzynek są poprawne.
2. **Symulacja**, żeby zobaczyć, ile wiadomości i folderów zostanie skopiowanych.
3. **Migracja**. Można ją uruchomić ponownie, bo imapsync nie kopiuje drugi raz wiadomości, które już są w skrzynce docelowej.
4. Po przełączeniu rekordów MX na nowy serwer wykonaj migrację jeszcze raz, żeby skopiować wiadomości, które przyszły w międzyczasie.

## Uwagi

- Skrzynka źródłowa **nie jest modyfikowana**, bo imapsync tylko z niej czyta.
- **Gmail / Microsoft 365** z włączonym MFA wymagają *hasła aplikacji* zamiast zwykłego hasła.
- Popularne serwery IMAP: Gmail `imap.gmail.com`, Microsoft 365 `outlook.office365.com`,
  home.pl `imap.home.pl`, OVH `ssl0.ovh.net`, Onet `imap.poczta.onet.pl`, WP `imap.wp.pl`.
- Jeśli przerwiesz skrypt przez `Ctrl+C`, pliki z hasłami mogą zostać w `%TEMP%`
  (`imapsync_*.tmp`). Wtedy usuń je ręcznie.

## Wykorzystane umiejętności

- Migracja poczty i protokół IMAP (SSL/TLS, porty 993/143, foldery specjalne)
- Skrypty wsadowe Windows (`set /p`, `choice`, podprogramy `call :etykieta`)
- Bezpieczne obchodzenie się z hasłami (ukryte wpisywanie, pliki tymczasowe zamiast parametrów)
- Integracja `cmd` z PowerShell
