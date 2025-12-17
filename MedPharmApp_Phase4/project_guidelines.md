Dokument Projektowy Architektury Systemu: Aplikacja Pacjenta (Clinical Study App)
1. Przegląd i Cele Systemu
Aplikacja mobilna służy do zbierania danych w ramach badań klinicznych. Kluczowym celem jest umożliwienie pacjentom wypełniania codziennych ankiet zdrowotnych w sposób bezpieczny, niezawodny i zgodny z regulacjami HIPAA/GDPR, z pełnym wsparciem dla trybu offline.
2. Architektura Systemu
Zastosowano architekturę z podziałem na warstwy prezentacji, domeny (Use Cases) i danych, co zapewnia testowalność i separację odpowiedzialności.
2.1 Warstwy Aplikacji
Warstwa Prezentacji (UI Layer):
Zbudowana w oparciu o wzorzec MVVM? (Model-View-ViewModel).
Ekrany: Rejestracja, Zgody (Consent), Lista Ankiet, Wypełnianie Ankiety, Profil, Podsumowanie.
State Management: flutter_bloc lub Riverpod do zarządzania stanem widoków i obsługi logiki prezentacyjnej.
Warstwa Domeny (Use Cases):
Zawiera czystą logikę biznesową niezależną od UI i infrastruktury.
Przykłady: RegisterUseCase, SubmitQuestionnaireUseCase, PushNotificationUseCase.
Warstwa Danych (Data Access Layer):
Odpowiada za decyzję o źródle danych (lokalne vs zdalne).
Repozytoria zarządzają synchronizacją i buforowaniem.
3. Stack Technologiczny
Komponent
Technologia/Biblioteka
Uzasadnienie
Framework
Flutter
Cross-platform, wysoka wydajność UI
Baza Danych
SQLite
relacyjna struktura danych
Szyfrowanie DB
SQLCipher
Szyfrowanie całej bazy danych w spoczynku (wymóg HIPAA)
Secure Storage
flutter_secure_storage
Przechowywanie kluczy szyfrujących, tokenów JWT i kluczy biometrii
Dependency Injection
get_it + injectable
Zarządzanie singletonami i wstrzykiwaniem zależności
Analityka/Logi
Matomo
Telemetria zgodna z RODO/GDPR
Push Notifications
Firebase Cloud Messaging (FCM)
Standard przemysłowy, integracja z backendem

4. Bezpieczeństwo i Zgodność z HIPAA
4.1 Bezpieczeństwo Danych (Data at Rest)
Szyfrowanie Bazy: Lokalna baza SQLite jest zaszyfrowana kluczem AES-256 (SQLCipher). Klucz do bazy jest przechowywany w bezpiecznym magazynie sprzętowym (Keychain/Keystore).
Dane Wrażliwe: Tokeny JWT (Access + Refresh) są przechowywane wyłącznie w Secure Storage.
Czyszczenie Danych: Automatyczne czyszczenie danych lokalnych po zakończeniu badania lub wycofaniu zgody.
4.2 Bezpieczeństwo Sieciowe (Data in Transit)
Szyfrowanie: TLS 1.3 dla całej komunikacji.
Certificate Pinning: Zapobieganie atakom Man-in-the-Middle (MITM).
Obsługa Tokenów:
Automatyczne odświeżanie tokena przy błędzie 401 Unauthorized przy użyciu Refresh Token.
Wylogowanie użytkownika w przypadku wygaśnięcia obu tokenów.
4.3 Uwierzytelnianie i Autoryzacja
Rejestracja: Kod zapisu (enrollment_code) walidowany przez API /auth/register.
Biometria: Opcjonalne zabezpieczenie dostępu do aplikacji (FaceID/Fingerprint) przy użyciu biblioteki local_auth.
Wygaszanie Sesji: Auto-wylogowanie po okresie bezczynności.
5. Strategia Danych i Synchronizacji (Offline-First)
Aplikacja musi działać w miejscach bez zasięgu. Strategia oparta na Sync Service i Sync Queue.
5.1 Model Danych
Odwzorowanie modeli API w lokalnej bazie danych:
Questionnaires: Tabela z definicjami ankiet (JSON blobs dla pytań dynamicznych).
Responses: Tabela odpowiedzi ze statusem (draft, pending_sync, synced).
AuditLogs: Tabela zdarzeń do audytu.
5.2 Proces Synchronizacji
Zapis Lokalny: Użytkownik wypełnia ankietę -> dane zapisywane są w lokalnym DB ze statusem pending_sync.
Trigger: SyncService jest wywoływany:
Po zakończeniu ankiety.
Cyklicznie w tle (co 15 min).
Przy odzyskaniu połączenia internetowego.
Upload: Wysyłka endpointem POST /sync/upload.
Konflikty: Zgodnie z API, serwer implementuje zasadę "Last-Write-Wins". Aplikacja nadpisuje stan lokalny odpowiedzią z serwera po udanym uploadzie.
6. Interfejs Użytkownika i Przepływ (UX)
6.1 Dynamiczne Ankiety
System renderuje interfejs na podstawie JSON pobranego z endpointu /questionnaires/available. Obsługiwane typy:
Closed: Radio buttons / Checkboxy.
Scale: Suwaki (Sliders) lub przyciski numeryczne (1-10).
Open: Pola tekstowe z walidacją długości.
6.2 Nawigacja
Wykorzystanie Navigation Block (np. go_router) do zarządzania ścieżkami.
Guards: Blokada dostępu do ankiet bez aktywnej sesji lub braku zgody.

7. Powiadomienia (Push Notifications)
Remote (FCM): Informacja o nowej ankiecie ("questionnaire_available") wysyłana przez backend -> Firebase -> App.
Local: Przypomnienia generowane przez aplikację ("Przypomnij mi za godzinę"), jeśli użytkownik nie wypełnił ankiety, a termin mija. Obsługiwane przez Push Notification Service.
8. Obsługa Błędów i Niezawodność
Kolejka (Queue): Gwarancja, że żadna ankieta nie zginie – pozostaje w Sync Queue do momentu otrzymania 200 OK od serwera.
Global Error Handling: Centralna obsługa wyjątków mapująca błędy techniczne na komunikaty przyjazne dla pacjenta (np. "Brak internetu. Zapisano wyniki lokalnie.").
9. Audyt i Logowanie (Audit Trail)
Audit Trail Service: Rejestrowanie każdego działania użytkownika (otwarcie ankiety, zmiana odpowiedzi, wysyłka) w bezpiecznym lokalnym logu.
Synchronizacja Logów: Logi są wysyłane na serwer osobnym kanałem synchronizacji dla celów compliance (wymóg FDA/HIPAA).
10. Testowanie
Unit Tests: Testowanie logiki biznesowej (UseCases, ViewModels) i mapperów danych.
Widget Tests: Testowanie renderowania dynamicznych ankiet.
Integration Tests: Testowanie przepływu Rejestracja -> Ankieta -> Sync w izolowanym środowisku (mock server).

