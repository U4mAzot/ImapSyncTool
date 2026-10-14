@echo off
rem ==========================================================================
rem  ImapSync - kopiowanie poczty z jednej skrzynki IMAP do drugiej
rem
rem  Skrypt pyta o serwer, login i haslo obu skrzynek, a nastepnie uruchamia
rem  imapsync w wybranym trybie: test logowania, symulacja lub migracja.
rem
rem  Hasla:
rem   - sa wpisywane jako ukryte (gwiazdki),
rem   - trafiaja do imapsync przez tymczasowe pliki (--passfile1/2), a nie
rem     przez linie polecen, gdzie bylyby widoczne na liscie procesow,
rem   - pliki tymczasowe sa usuwane po zakonczeniu pracy skryptu.
rem
rem  Wymaga: imapsync.exe w tym samym folderze lub w zmiennej PATH
rem          (do pobrania: https://imapsync.lamiral.info/)
rem ==========================================================================
setlocal EnableExtensions DisableDelayedExpansion
title ImapSync - migracja poczty

rem --- Szukanie imapsync.exe ---------------------------------------------------
set "IMAPSYNC=%~dp0imapsync.exe"
if not exist "%IMAPSYNC%" (
    for %%I in (imapsync.exe) do set "IMAPSYNC=%%~$PATH:I"
)
if not defined IMAPSYNC (
    echo [BLAD] Nie znaleziono imapsync.exe.
    echo        Pobierz go ze strony https://imapsync.lamiral.info/ i umiesc
    echo        w folderze: %~dp0
    echo.
    pause
    exit /b 1
)

set "LOGDIR=%~dp0logs"
set "PASSFILE1=%TEMP%\imapsync_%RANDOM%%RANDOM%_1.tmp"
set "PASSFILE2=%TEMP%\imapsync_%RANDOM%%RANDOM%_2.tmp"

echo ===========================================================
echo    MIGRACJA POCZTY IMAP  (imapsync)
echo ===========================================================
echo.
echo --- SKRZYNKA ZRODLOWA (z ktorej kopiujemy) ---------------
call :ask HOST1 "Serwer IMAP (np. imap.stara-firma.pl)"
call :ask USER1 "Login (zwykle pelny adres e-mail)"
call :askport PORT1 SEC1 1
call :askpass "%PASSFILE1%"
echo.
echo --- SKRZYNKA DOCELOWA (do ktorej kopiujemy) --------------
call :ask HOST2 "Serwer IMAP (np. imap.nowa-firma.pl)"
call :ask USER2 "Login (zwykle pelny adres e-mail)"
call :askport PORT2 SEC2 2
call :askpass "%PASSFILE2%"

rem znacznik czasu niezalezny od ustawien regionalnych systemu
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"

:menu
echo.
echo ===========================================================
echo  Z:  %USER1%  (%HOST1%:%PORT1%)
echo  Do: %USER2%  (%HOST2%:%PORT2%)
echo ===========================================================
echo  1 - Test logowania  (sprawdza tylko polaczenie i hasla)
echo  2 - Symulacja       (pokazuje, co zostanie skopiowane - nic nie zmienia)
echo  3 - MIGRACJA        (kopiuje poczte do skrzynki docelowej)
echo  4 - Zakoncz
echo.
choice /c 1234 /n /m "Wybierz opcje [1-4]: "
set "MODE=%errorlevel%"

if "%MODE%"=="4" goto finish
if "%MODE%"=="1" set "MODEOPT=--justlogin" & set "MODENAME=test"
if "%MODE%"=="2" set "MODEOPT=--dry"       & set "MODENAME=symulacja"
if "%MODE%"=="3" set "MODEOPT="            & set "MODENAME=migracja"

if "%MODE%"=="3" (
    echo.
    echo Poczta zostanie skopiowana do skrzynki %USER2%.
    echo Skrzynka zrodlowa NIE zostanie zmieniona.
    choice /c TN /m "Czy rozpoczac migracje"
    if errorlevel 2 goto menu
)

set "LOGFILE=%MODENAME%_%USER1%_%STAMP%_%RANDOM%.txt"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

echo.
echo Uruchamianie imapsync (%MODENAME%)...
echo.

rem --automap         - dopasowuje foldery specjalne (np. Sent <-> Wyslane, Trash <-> Kosz)
rem --syncinternaldates - zachowuje oryginalne daty wiadomosci
"%IMAPSYNC%" ^
    --host1 "%HOST1%" --port1 %PORT1% %SEC1% --user1 "%USER1%" --passfile1 "%PASSFILE1%" ^
    --host2 "%HOST2%" --port2 %PORT2% %SEC2% --user2 "%USER2%" --passfile2 "%PASSFILE2%" ^
    --automap --syncinternaldates ^
    --logdir "%LOGDIR%" --logfile "%LOGFILE%" ^
    %MODEOPT%
set "RESULT=%errorlevel%"

echo.
echo ===========================================================
if "%RESULT%"=="0" (
    echo  [OK] Zakonczono pomyslnie: %MODENAME%
) else (
    echo  [BLAD] imapsync zakonczyl sie kodem %RESULT%.
    echo         Szczegoly w logu - wyszukaj w nim slowo "Err".
)
echo  Log: %LOGDIR%\%LOGFILE%
echo ===========================================================
goto menu

:finish
rem usuniecie plikow z haslami
del /f /q "%PASSFILE1%" "%PASSFILE2%" >nul 2>&1
echo.
echo Pliki tymczasowe z haslami zostaly usuniete. Do zobaczenia!
endlocal
exit /b 0


rem ==========================================================================
rem  Funkcje pomocnicze
rem ==========================================================================

rem :ask ZMIENNA "Opis" - pyta o wartosc, dopoki nie zostanie podana
:ask
set "%~1="
set /p "%~1=  %~2: "
if not defined %~1 (
    echo   To pole jest wymagane.
    goto ask
)
exit /b 0

rem :askport ZMIENNA_PORT ZMIENNA_SZYFROWANIE NR_SKRZYNKI
rem   port 993 = SSL (--ssl1/--ssl2), port 143 = STARTTLS (--tls1/--tls2)
:askport
set "%~1=993"
set /p "%~1=  Port [Enter = 993 SSL, 143 = STARTTLS]: "
call set "PORTVALUE=%%%~1%%"
if "%PORTVALUE%"=="143" (
    set "%~2=--tls%~3"
) else (
    set "%~2=--ssl%~3"
)
exit /b 0

rem :askpass PLIK - ukryte wpisanie hasla i zapis do pliku tymczasowego
:askpass
set "PASSFILE_TARGET=%~1"
powershell -NoProfile -Command ^
    "$s = Read-Host '  Haslo (niewidoczne)' -AsSecureString;" ^
    "if ($s.Length -eq 0) { exit 1 };" ^
    "$b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s);" ^
    "try { [IO.File]::WriteAllText($env:PASSFILE_TARGET, [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)) }" ^
    "finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }"
if errorlevel 1 (
    echo   Haslo nie moze byc puste.
    goto askpass
)
set "PASSFILE_TARGET="
exit /b 0
