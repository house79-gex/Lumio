# Lumio — PhotoAI Catalog

App Android (Flutter) per la **catalogazione intelligente delle foto** tramite IA: analisi con Gemini, cartelle fisiche, backup cloud multi-provider e sistema professioni.

## Avvio rapido

1. **Requisiti**: Flutter 3.x, Dart 3.x, Android Studio (JDK 17).
2. **Dipendenze**:
   ```bash
   flutter pub get
   ```
3. **Esecuzione**:
   ```bash
   flutter run
   ```
   (Seleziona un device Android o emulatore.)

## Primo avvio

1. **Onboarding**: alla prima apertura scegli la **professione** (es. Falegname, Fotografo, Chef) dal catalogo. Verrà creato un profilo con le categorie predefinite.
2. **Chiave API Gemini**: in **Impostazioni** inserisci la chiave API da [Google AI Studio](https://aistudio.google.com/apikey) per abilitare l’analisi delle foto. Senza chiave l’app funziona ma la scansione non invierà le foto a Gemini.
3. **Scansione**: dalla Home avvia una **Nuova scansione**. L’app chiederà il permesso alla galleria, leggerà le foto (fino al numero scelto), le invierà a Gemini per la categorizzazione e creerà **album** e **cartelle fisiche** in base al risultato.

## Struttura progetto

- **`lib/core/`** — costanti, database SQLite, utility (immagini, EXIF).
- **`lib/models/`** — Photo, Album, Person, Profession, UserProfile, ScanResult.
- **`lib/services/`** — GalleryService, AIService (Gemini), FolderService, ScanService, ProfessionCatalogService; **`cloud/`** — CloudSyncService e provider (Google Drive stub).
- **`lib/repositories/`** — AlbumRepository, SettingsRepository.
- **`lib/providers/`** — Riverpod: profilo, album, scan, professioni, AI.
- **`lib/screens/`** — Onboarding (welcome, profession_picker), Home, Scan, Album (lista/dettaglio), Impostazioni, Cloud, Persone.
- **`assets/professions/`** — `professions_catalog.json` con settori e professioni predefinite.

## Funzionalità implementate

- ✅ Onboarding e scelta professione con catalogo JSON.
- ✅ Scansione galleria (photo_manager), permessi Android.
- ✅ Analisi IA con **Gemini 2.0 Flash** (prompt per categorie del profilo).
- ✅ Creazione cartelle fisiche e copia foto per categoria / “Da revisionare”.
- ✅ Database SQLite (foto, album, profili, categorie, persone, log sync).
- ✅ State management con Riverpod (profilo attivo, album, stato scansione).
- ✅ UI: Home, Album (lista/dettaglio), Scansione, Impostazioni (chiave API, profilo), schermate stub Cloud e Persone.

## Da completare / estendere

- **Cloud sync reale**: OAuth e upload per Google Drive, Dropbox, OneDrive, Mega (attualmente solo interfaccia e stub).
- **ML Kit Face Detection**: riconoscimento volti e album per persona.
- **Scansione incrementale**: solo foto nuove dall’ultima run.
- **Workmanager**: sync e scansione in background.

## Documentazione

Vedi **PhotoAI_App_Documentazione_v2.md** per architettura, schema DB, flussi e roadmap.
