# 📱 PhotoAI Catalog — Documentazione Completa v2.0

> App Android basata su Flutter per la catalogazione intelligente delle foto tramite Intelligenza Artificiale
> con gestione cartelle fisiche, backup cloud multi-provider e sistema professioni predefinite ed espandibili

---

## Indice

1. [Panoramica generale](#1-panoramica-generale)
2. [Obiettivi e casi d'uso](#2-obiettivi-e-casi-duso)
3. [Tecnologie utilizzate](#3-tecnologie-utilizzate)
4. [Architettura dell'app](#4-architettura-dellapp)
5. [Funzionalità dettagliate](#5-funzionalità-dettagliate)
6. [Sistema Professioni e Categorie](#6-sistema-professioni-e-categorie)
7. [Gestione Cartelle Fisiche](#7-gestione-cartelle-fisiche)
8. [Backup Cloud Multi-Provider](#8-backup-cloud-multi-provider)
9. [Interfaccia utente (UI/UX)](#9-interfaccia-utente-uiux)
10. [Scheletro del codice Flutter](#10-scheletro-del-codice-flutter)
11. [Flusso di catalogazione](#11-flusso-di-catalogazione)
12. [Gestione della privacy](#12-gestione-della-privacy)
13. [Struttura del database SQLite](#13-struttura-del-database-sqlite)
14. [Roadmap e versioni](#14-roadmap-e-versioni)
15. [Requisiti di sistema](#15-requisiti-di-sistema)

---

## 1. Panoramica Generale

**PhotoAI Catalog** è un'applicazione Android sviluppata con Flutter che sfrutta l'Intelligenza Artificiale per analizzare, riconoscere e catalogare automaticamente tutte le foto presenti sulla galleria del dispositivo.

L'app crea **cartelle fisiche reali** sul dispositivo corrispondenti agli album generati, mantiene tutto sincronizzato con i provider cloud preferiti dall'utente e offre un sistema di **profili professionali predefiniti** (falegname, fotografo, medico, chef, architetto e decine di altri) subito pronti all'uso e completamente personalizzabili.

### Concetto chiave

```
GALLERIA DEL DISPOSITIVO
         │
         ▼
   ANALISI AI (Gemini 2.0 Flash)
         │
         ├──► Contenuto foto → Categoria/Professione
         ├──► Volti riconosciuti → Persone associate
         └──► Metadati EXIF → Data / Anno / Luogo
         │
         ▼
   ALBUM VIRTUALI (database)
         │
         ▼
   CARTELLE FISICHE (storage dispositivo)
         │
         ▼
   BACKUP CLOUD (Google Drive / Mega / Dropbox / OneDrive)
```

---

## 2. Obiettivi e Casi d'Uso

### Caso d'uso 1 — Professionisti (qualsiasi settore)
L'utente seleziona la sua professione dal catalogo predefinito. L'app carica automaticamente tutte le categorie rilevanti per quel mestiere, crea gli album e le cartelle corrispondenti, e avvia la catalogazione.

### Caso d'uso 2 — Foto di Famiglia e Amici
Riconoscimento facciale con ML Kit per catalogare automaticamente le foto per persona, con album e cartelle dedicate a ogni componente della famiglia o gruppo di amici.

### Caso d'uso 3 — Eventi Ricorrenti per Anno
Carnevale, Natale, compleanni, vacanze: l'AI riconosce il tipo di evento, i metadati EXIF forniscono l'anno, e le foto finiscono in cartelle come `/PhotoAI/Carnevale/2023/` e `/PhotoAI/Carnevale/2024/`.

### Caso d'uso 4 — Backup Automatico Organizzato
Le cartelle fisiche create dall'app vengono sincronizzate automaticamente sul cloud scelto dall'utente, mantenendo la stessa struttura di cartelle anche sul provider remoto.

---

## 3. Tecnologie Utilizzate

### Frontend
| Tecnologia | Versione | Scopo |
|---|---|---|
| Flutter | 3.x | Framework UI |
| Dart | 3.x | Linguaggio |

### AI e Machine Learning
| Tecnologia | Costo | Scopo |
|---|---|---|
| Google Gemini 2.0 Flash | ✅ Gratuito | Analisi contenuto foto |
| Google ML Kit Face Detection | ✅ Gratuito, on-device | Rilevamento e riconoscimento volti |

### Pacchetti Flutter — Completo
| Pacchetto | Scopo |
|---|---|
| `photo_manager` | Accesso galleria Android |
| `google_generative_ai` | SDK Gemini API |
| `google_mlkit_face_detection` | Face recognition |
| `sqflite` | Database SQLite locale |
| `shared_preferences` | Preferenze utente |
| `permission_handler` | Permessi Android |
| `flutter_image_compress` | Compressione pre-invio API |
| `workmanager` | Task in background |
| `flutter_riverpod` | State management |
| `exif` | Metadati EXIF foto |
| `path_provider` | Percorsi file sistema |
| `googleapis` | Google Drive API |
| `googleapis_auth` | Autenticazione Google OAuth2 |
| `google_sign_in` | Login Google per Drive |
| `dropbox_client` | Dropbox API |
| `onedrive_api` | OneDrive/Microsoft API |
| `dio` | HTTP client per Mega e API REST |
| `background_downloader` | Upload/download in background |
| `flutter_secure_storage` | Storage sicuro token OAuth |
| `connectivity_plus` | Monitoraggio connessione (sync solo su Wi-Fi) |
| `file_picker` | Selezione cartella destinazione |

---

## 4. Architettura dell'App

```
┌──────────────────────────────────────────────────────────────────┐
│                          FLUTTER APP                             │
│                                                                  │
│  ┌──────────────┐   ┌───────────────┐   ┌────────────────────┐  │
│  │   UI Layer   │◄─►│ State Manager │◄─►│    Repository      │  │
│  │  (Screens)   │   │  (Riverpod)   │   │    (Data)          │  │
│  └──────────────┘   └───────────────┘   └─────────┬──────────┘  │
│                                                    │             │
│  ┌─────────────────────────────────────────────────▼──────────┐  │
│  │                       SERVICE LAYER                        │  │
│  │                                                            │  │
│  │ ┌────────────┐ ┌──────────┐ ┌──────────┐ ┌─────────────┐ │  │
│  │ │GalleryServ.│ │AIService │ │FaceServ. │ │FolderService│ │  │
│  │ │(foto)      │ │(Gemini)  │ │(ML Kit)  │ │(cartelle)   │ │  │
│  │ └──────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬──────┘ │  │
│  │        │             │            │               │         │  │
│  │ ┌──────▼─────────────▼────────────▼───────────────▼──────┐ │  │
│  │ │                  CloudSyncService                       │ │  │
│  │ │   GoogleDrive │ Mega │ Dropbox │ OneDrive │ Manuale     │ │  │
│  │ └─────────────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
         │               │               │               │
         ▼               ▼               ▼               ▼
  ┌────────────┐  ┌────────────┐  ┌───────────┐  ┌───────────────┐
  │  GALLERIA  │  │ GEMINI API │  │  ML KIT   │  │ CLOUD STORAGE │
  │  ANDROID   │  │  (cloud)   │  │(on-device)│  │ (scelto dall' │
  │            │  │            │  │           │  │  utente)      │
  └────────────┘  └────────────┘  └───────────┘  └───────────────┘
         │
         ▼
  ┌────────────────────────────────┐
  │     STORAGE LOCALE             │
  │  /storage/emulated/0/PhotoAI/ │
  │  ├── Porte/                   │
  │  ├── Cucine/                  │
  │  ├── Carnevale/               │
  │  │   ├── 2022/                │
  │  │   ├── 2023/                │
  │  │   └── 2024/                │
  │  └── Famiglia/                │
  │      ├── Mario/               │
  │      └── Sara/                │
  └────────────────────────────────┘
```

---

## 5. Funzionalità Dettagliate

### 5.1 Scansione Galleria
- Accede a tutte le foto del dispositivo tramite `photo_manager`
- Legge metadati EXIF: data, ora, coordinate GPS, modello fotocamera
- Supporta: JPG, PNG, HEIC, WebP, RAW (dove supportato)
- Scansione incrementale: solo le foto nuove dall'ultima sessione
- Esclusione di cartelle specifiche (screenshot, WhatsApp, ecc.)

### 5.2 Analisi AI — Gemini 2.0 Flash
- Foto compressa (max 800px) inviata con prompt personalizzato
- Il prompt include le categorie del profilo professionale attivo
- Risposta JSON strutturata con categoria + confidenza + descrizione
- Cache locale: foto già analizzate non vengono reinviate
- Rate limit: 14 richieste/minuto (margine di sicurezza sul limite di 15)
- Retry automatico con backoff esponenziale in caso di errore

### 5.3 Riconoscimento Persone — ML Kit
- Fase di registrazione: 3-5 foto per persona → embedding facciale locale
- Riconoscimento in tempo reale durante la scansione
- Soglia di confidenza regolabile dall'utente
- Una foto può apparire in più album (più persone riconosciute)
- Tutto on-device: i volti non lascono mai il dispositivo

### 5.4 Lettura Metadati EXIF
- Data e ora scatto → suddivisione per anno degli eventi ricorrenti
- Coordinate GPS → possibile tag "luogo" e raggruppamento geografico
- Modello fotocamera → distingue foto professionali da snapshot

---

## 6. Sistema Professioni e Categorie

### 6.1 Architettura del sistema professioni

Il sistema è organizzato su tre livelli:

```
LIVELLO 1 — SETTORE
    │
    ├── LIVELLO 2 — PROFESSIONE
    │       │
    │       └── LIVELLO 3 — CATEGORIE (con keywords AI)
    │
    └── Completamente personalizzabile
```

Ogni professione ha un set di categorie predefinite con le relative **keyword** che vengono inserite nel prompt di Gemini per massimizzare la precisione del riconoscimento.

---

### 6.2 Catalogo completo professioni predefinite

---

#### 🏗️ SETTORE: ARTIGIANATO E COSTRUZIONI

---

**🪵 FALEGNAME / EBANISTA**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Porte | 🚪 | porta interna, porta blindata, portone, stipite, telaio porta, anta |
| Cucine | 🍳 | mobile cucina, pensile, base cucina, anta cucina, cassetto |
| Armadi | 🪞 | armadio, cabina armadio, guardaroba, ante scorrevoli |
| Pavimenti | 🪵 | parquet, listoni, pavimento legno, posa spina di pesce |
| Finestre | 🪟 | infisso, persiana, scuretto, davanzale, finestra legno |
| Scale | 🪜 | scala legno, gradini, ringhiera, corrimano |
| Mobili su misura | 🛋️ | libreria, comodino, cassettiera, scrivania artigianale |
| Restauro | 🔨 | restauro mobile, verniciatura, levigatura, patinatura |
| Cantiere/Lavori | 🔧 | installazione, montaggio in opera, misurazioni, cantiere |

---

**🧱 MURATORE / GEOMETRA / IMPRESA EDILE**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Fondamenta e struttura | 🏗️ | fondamenta, casseforme, pilastri, solai, travi |
| Muratura | 🧱 | mattoni, blocchi, malta, muratura, parete |
| Intonaci | 🎨 | intonaco, rasatura, finitura pareti, lisciatura |
| Pavimenti e rivestimenti | 🪟 | posa piastrelle, pavimento, rivestimento, fughe |
| Tetti e coperture | 🏠 | tetto, tegole, guaina, impermeabilizzazione, grondaia |
| Bagni | 🚿 | bagno ristrutturato, sanitari, doccia, vasca |
| Cantiere | 🔧 | ponteggio, gru, betoniera, cantiere attivo |
| Prima e dopo | 📸 | stato di fatto, demolizione, opera finita, confronto |

---

**⚡ ELETTRICISTA**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Quadri elettrici | 🔌 | quadro elettrico, interruttori, salvavita, cablaggio |
| Impianti civili | 🏠 | prese, interruttori, cavi, tubazioni, scatole |
| Impianti industriali | 🏭 | canaline, quadri industriali, motori, inverter |
| Illuminazione | 💡 | plafoniere, LED, faretti, neon, illuminazione esterna |
| Fotovoltaico | ☀️ | pannelli solari, inverter fotovoltaico, batterie |
| Automazione | 🤖 | domotica, tapparelle motorizzate, videocitofono |
| Collaudo e test | 🔍 | tester, misurazione, verifica impianto, certificazione |

---

**🔧 IDRAULICO / TERMOIDRAULICO**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Impianti idrici | 💧 | tubi, raccordi, valvole, collettori, tubature |
| Bagni e sanitari | 🚿 | wc, lavabo, vasca, doccia, bidet, rubinetti |
| Caldaie e riscaldamento | 🔥 | caldaia, radiatori, termosifoni, pompa calore |
| Condizionamento | ❄️ | climatizzatore, split, unità esterna, canalizzazioni |
| Impianti gas | ⚠️ | tubazione gas, contatore, bruciatore, cucina a gas |
| Scarichi e fognature | 🌊 | scarico, sifone, pozzetto, fognatura, sifonatura |
| Interventi urgenti | 🆘 | perdita, allagamento, guasto, riparazione emergenza |

---

**🎨 PITTORE / DECORATORE**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Pittura interni | 🎨 | pareti dipinte, tinteggiatura, colori interni |
| Carta da parati | 🖼️ | wallpaper, carta da parati, applicazione |
| Decorazioni | ✨ | stencil, decorazione, effetti speciali, marmorino |
| Esterni e facciate | 🏠 | facciata, tinteggiatura esterna, silossanica |
| Verniciatura legno/ferro | 🔧 | verniciatura, smalto, primer, antiruggine |
| Resine e spatolati | 💎 | resina epossidica, microcemento, spatola veneziana |
| Prima e dopo | 📸 | stato prima, risultato finale, confronto lavoro |

---

#### 📸 SETTORE: ARTE E CREATIVITÀ

---

**📷 FOTOGRAFO PROFESSIONISTA**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Matrimoni | 💍 | matrimonio, sposi, cerimonia, chiesa, ricevimento |
| Ritratti | 👤 | ritratto, studio, sfondo bianco, bokeh, modello |
| Newborn / Neonati | 👶 | neonato, neonato in posa, fascia, cesto, fiori |
| Reportage eventi | 🎤 | concerto, conferenza, evento, folla, palco |
| Paesaggi e natura | 🌄 | tramonto, montagna, mare, lago, foresta |
| Food photography | 🍽️ | piatto, food styling, ristorante, ingredienti |
| Architettura | 🏛️ | edificio, interno architettura, geometria |
| Prodotti/Ecommerce | 📦 | prodotto su sfondo, pack shot, studio prodotto |
| BTS / Backstage | 🎬 | backstage, dietro le quinte, set fotografico |

---

**🎨 ARTISTA / PITTORE / ILLUSTRATORE**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Dipinti a olio | 🖌️ | tela, pennellata, olio su tela, pittura classica |
| Acquerelli | 💧 | acquerello, carta acquerello, trasparenze, sfumature |
| Illustrazioni digitali | 💻 | illustrazione digitale, tablet grafico, vettoriale |
| Scultura | 🗿 | scultura, argilla, bronzo, marmo, busto |
| Murales / Street art | 🏙️ | murales, graffiti arte, spray, muro dipinto |
| WIP (Work in progress) | 🔄 | lavoro in corso, bozzetto, schizzo, studio |
| Esposizioni | 🖼️ | mostra, galleria d'arte, esposizione, vernissage |

---

**✂️ STILISTA / SARTO / FASHION DESIGNER**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Capi creati | 👗 | abito, vestito, gonna, pantalone, giacca fatta a mano |
| Dettagli sartoriali | 🧵 | cuciture, ricamo, bottoni, chiusure, finishing |
| Sfilate e show | 👠 | sfilata, passerella, modella, fashion show |
| Tessuti e materiali | 🧶 | tessuto, stoffe, campioni, cartella colori |
| Lavoro in atelier | ✂️ | manichino, ago e filo, macchina da cucire, taglio |
| Accessori | 👜 | borsa, cintura, cappello, gioiello, accessorio |

---

#### 🍽️ SETTORE: RISTORAZIONE E FOOD

---

**👨‍🍳 CHEF / CUOCO**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Piatti pronti | 🍽️ | piatto impiattato, presentazione, guarnizione |
| Antipasti | 🥗 | antipasto, entrée, finger food, bruschetta |
| Primi piatti | 🍝 | pasta, risotto, zuppa, minestra, primo |
| Secondi | 🥩 | carne, pesce, secondo piatto, arrosto, grigliata |
| Dolci e dessert | 🍰 | dolce, torta, dessert, pasticceria, plated dessert |
| Ingredienti e mise en place | 🥬 | ingredienti freschi, preparazione, mise en place |
| Cucina e brigata | 👨‍🍳 | cucina professionale, brigata, fuochi, padelle |
| Tecniche | 🔬 | sous vide, sifone, fiamma ossidrica, sferificazione |

---

**🍰 PASTICCERE / CAKE DESIGNER**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Torte decorate | 🎂 | torta decorata, fondente, pasta di zucchero |
| Wedding cake | 💍 | torta matrimonio, torta nuziale, multi piano |
| Praline e cioccolato | 🍫 | praline, cioccolato, ganache, tempera cioccolato |
| Lievitati | 🥐 | croissant, brioche, pane artigianale, panettone |
| Mignon e monoporzioni | 🧁 | mignon, tartelletta, éclair, monoporzione |
| Decorazioni sugar art | 🌸 | fiori in zucchero, decorazione, scultura zucchero |

---

**🍷 SOMMELIER / ENOTECARIO**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Vini | 🍷 | bottiglia vino, etichetta, cantina, calice |
| Degustazioni | 🥂 | degustazione, bicchieri, assaggio, calici allineati |
| Cantine e barrique | 🪣 | cantina, barrique, botti, affinamento |
| Abbinamenti | 🍽️ | abbinamento cibo vino, tagliere, formaggi |

---

#### 🏥 SETTORE: SALUTE E BENESSERE

---

**💆 ESTETISTA / CENTRO BENESSERE**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Trattamenti viso | 💆 | trattamento viso, maschera, pulizia viso |
| Unghie e nail art | 💅 | nail art, unghie gel, ricostruzione unghie, smalto |
| Massaggi | 🙌 | massaggio, tavolo massaggi, oli essenziali |
| Prima e dopo | 📸 | prima trattamento, dopo trattamento, risultato |
| Attrezzature | 🔧 | strumenti estetici, apparecchiatura, cabina estetica |
| Prodotti | 🧴 | cosmetici, prodotti, brand, linea prodotti |

---

**💪 PERSONAL TRAINER / FITNESS**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Allenamenti | 🏋️ | allenamento, esercizio, squat, pesi, cardio |
| Clienti in sessione | 🤸 | cliente che si allena, correzione posturale, coach |
| Progressi fisici | 📈 | prima e dopo, trasformazione corpo, risultati |
| Attrezzature | 🔧 | palestra, manubri, kettlebell, bande elastiche |
| Nutrizione | 🥗 | meal prep, dieta, integrazione, piatto bilanciato |

---

**🦷 DENTISTA / ORTODONTISTA**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Prima e dopo cure | 📸 | denti prima cura, risultato trattamento dentale |
| Protesi e manufatti | 🦷 | corona dentale, protesi, veneer, impianto |
| Strumentazione | 🔬 | riunito dentale, strumenti odontoiatrici |
| Radiografie (anonime) | 📷 | radiografia dentale, ortopantomografia |

---

#### 🌿 SETTORE: NATURA E AMBIENTE

---

**🌿 GIARDINIERE / PAESAGGISTA**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Giardini realizzati | 🌳 | giardino, prato, aiuole, siepi, alberature |
| Potatura e manutenzione | ✂️ | potatura, taglio erba, siepe potata, pulizia |
| Giardini pensili e verticali | 🌱 | giardino verticale, parete verde, giardino pensile |
| Fiori e piante | 🌸 | fioritura, pianta in vaso, coltivazione, semina |
| Attrezzature | 🚜 | motosega, trattorino, attrezzatura giardino |
| Piscine e laghetti | 💧 | piscina, laghetto ornamentale, fontana, bordo piscina |
| Irrigazione | 💦 | impianto irrigazione, ugelli, programmatore |

---

**🐾 VETERINARIO / TOELETTATORE**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Animali in visita | 🐶 | cane, gatto, animale domestico, visita veterinaria |
| Toelettatura | ✂️ | toelettatura, bagno animale, taglio pelo, grooming |
| Prima e dopo toelettatura | 📸 | prima e dopo toelettatura, risultato grooming |
| Animali esotici | 🦜 | rettile, uccello esotico, roditore, animale esotico |

---

**🌾 AGRICOLTORE / AGRONOMO**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Coltivazioni | 🌾 | campo coltivato, filari, semina, raccolto |
| Mezzi agricoli | 🚜 | trattore, mietitrebbia, aratro, seminatrice |
| Frutta e verdura | 🍅 | prodotti agricoli, frutta, verdura, orto |
| Vigneti e oliveti | 🍇 | vigna, vendemmia, olivo, uliveto, olive |
| Serre | 🏡 | serra, coltivazione idroponica, tunnel |
| Allevamento | 🐄 | mucche, pecore, stalla, pascolo, allevamento |

---

#### 🚗 SETTORE: AUTOMOTIVE E TRASPORTI

---

**🔧 MECCANICO / CARROZZIERE**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Riparazioni motore | 🔧 | motore, distribuzione, cambio olio, revisione motore |
| Carrozzeria | 🚗 | carrozzeria, ammaccatura, riverniciatura, lamierista |
| Prima e dopo riparazione | 📸 | auto danneggiata, auto riparata, confronto |
| Pneumatici | 🔄 | pneumatici, cambio gomme, equilibratura, gommista |
| Interni auto | 🪑 | rivestimento interno, plancia, selleria auto |
| Auto d'epoca / Restauro | 🏆 | auto d'epoca, restauro auto storica, oldtimer |

---

**🏍️ CONCESSIONARIO / DETAILER**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Auto in stock | 🚙 | auto usata, auto nuova, showroom, esposizione |
| Detailing | ✨ | lucidatura auto, ceramic coating, polish, detailing |
| Interni | 🪑 | interno auto pulito, lavaggio interni, ozonizzazione |
| Moto | 🏍️ | moto, scooter, moto d'epoca, customizzazione |

---

#### 🏠 SETTORE: INTERIOR DESIGN E ARCHITETTURA

---

**🏛️ ARCHITETTO / INTERIOR DESIGNER**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Render e progetti | 💻 | render 3D, planimetria, progetto architettonico |
| Residenziale realizzato | 🏠 | interno casa, living, camera da letto, cucina design |
| Commerciale | 🏢 | ufficio, negozio, showroom, hotel, ristorante design |
| Dettagli costruttivi | 📐 | dettaglio architettonico, nodo costruttivo, sezione |
| Materiali e campioni | 🪨 | campioni materiali, pavimento, rivestimento, marmo |
| Prima e dopo ristrutturazione | 📸 | prima ristrutturazione, dopo ristrutturazione |
| Esterno e facciate | 🏗️ | facciata, esterno edificio, terrazzo, giardino design |

---

**🛒 ARREDATORE / HOME STAGER**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Sale e living | 🛋️ | soggiorno arredato, divano, tavolino, decorazione |
| Camere da letto | 🛏️ | camera da letto, letto, comodini, armadio camera |
| Bagni | 🚿 | bagno arredato, sanitari design, specchio bagno |
| Home staging | 🏡 | casa messa in vendita, allestimento, staging |
| Dettagli decorativi | 🕯️ | cuscini, candele, quadri, piante, accessori |

---

#### 💻 SETTORE: TECNOLOGIA E MEDIA

---

**📱 SVILUPPATORE / IT**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Setup workstation | 💻 | scrivania, monitor, setup pc, tastiera meccanica |
| Server e infrastruttura | 🖥️ | server rack, datacenter, cavi rete, switch |
| Coding e schermo | 👨‍💻 | schermo con codice, IDE, terminale, programmazione |
| Hardware | 🔧 | scheda madre, CPU, GPU, assemblaggio PC |

---

**🎬 VIDEO MAKER / CONTENT CREATOR**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Setup ripresa | 🎥 | videocamera, gimbal, treppiede, ring light, set |
| Montaggio | 🖥️ | schermo montaggio, timeline video, editing |
| Drone | 🚁 | drone, ripresa aerea, vista dall'alto, drone shot |
| Backstage | 🎬 | set ripresa, regista, ciak, dietro le quinte |
| Podcast | 🎙️ | microfono, podcast studio, registrazione audio |

---

#### 🎓 SETTORE: ISTRUZIONE E FORMAZIONE

---

**📚 INSEGNANTE / FORMATORE**
| Categoria | Emoji | Keyword AI |
|---|---|---|
| Aula e lezioni | 📚 | aula, lavagna, studenti, lezione frontale |
| Materiali didattici | 📋 | dispense, slide, materiale formativo, schede |
| Laboratori | 🔬 | laboratorio, esperimento, microscopia, chimica |
| Eventi e seminari | 🎤 | seminario, conferenza, speaker, platea |
| Graduazioni | 🎓 | laurea, diploma, tocco, toga, cerimonia |

---

### 6.3 Gestione del sistema professioni — lato utente

#### Selezione profilo

```
PRIMO AVVIO
     │
     ▼
Scegli il tuo settore:
 🏗️ Artigianato    📸 Arte e Creatività   🍽️ Ristorazione
 🏥 Salute         🌿 Natura              🚗 Automotive
 🏠 Design         💻 Tecnologia          🎓 Istruzione
 ➕ Personalizzato
     │
     ▼
Scegli la tua professione (lista filtrata per settore)
     │
     ▼
Categorie precaricate → personalizzabili
     │
     ▼
Aggiungi/modifica/elimina categorie a piacere
     │
     ▼
AVVIO SCANSIONE
```

#### Profili multipli

L'utente può creare e salvare **più profili**. Esempio:
- Profilo "Lavoro" → categorie da falegname
- Profilo "Personale" → categorie famiglia + eventi + amici
- Si passa da un profilo all'altro con un tap

#### Espansione personalizzata

Ogni categoria predefinita è editabile. L'utente può:
- Rinominare la categoria
- Cambiare l'emoji
- Aggiungere/rimuovere keyword per il riconoscimento AI
- Aggiungere categorie completamente nuove
- Condividere il proprio profilo professionale (esportazione JSON)
- Importare profili creati da altri utenti

---

## 7. Gestione Cartelle Fisiche

### 7.1 Concetto

Ogni album creato dall'AI corrisponde a una **cartella fisica reale** nello storage del dispositivo. Le foto vengono **copiate** (non spostate) nella cartella corrispondente, mantenendo sempre l'originale nella galleria.

### 7.2 Struttura cartelle sul dispositivo

```
/storage/emulated/0/
└── PhotoAI/
    │
    ├── [ProfiloLavoro]/
    │   ├── Porte/
    │   │   ├── porta_rovere_2024.jpg
    │   │   ├── porta_blindata_appartamento.jpg
    │   │   └── ...
    │   ├── Cucine/
    │   │   ├── cucina_moderna_cliente_rossi.jpg
    │   │   └── ...
    │   ├── Armadi/
    │   ├── Pavimenti/
    │   └── Altro/
    │
    ├── [ProfiloPersonale]/
    │   ├── Famiglia/
    │   │   ├── Mario/
    │   │   │   ├── mario_compleanno_2023.jpg
    │   │   │   └── ...
    │   │   ├── Sara/
    │   │   └── Tutta_la_famiglia/
    │   ├── Amici/
    │   │   ├── Gruppo_calcetto/
    │   │   └── ...
    │   └── Eventi/
    │       ├── Carnevale/
    │       │   ├── 2022/
    │       │   ├── 2023/
    │       │   └── 2024/
    │       ├── Natale/
    │       │   ├── 2022/
    │       │   └── 2023/
    │       └── Vacanze/
    │           ├── Estate_2023/
    │           └── Estate_2024/
    │
    └── _Da_revisionare/
        └── (foto con confidenza AI < 70%)
```

### 7.3 Logica di gestione cartelle

```dart
// services/folder_service.dart
class FolderService {

  // Crea la struttura cartelle di un profilo
  Future<void> createProfileFolderStructure(Profile profile) async {
    final baseDir = await _getBaseDirectory();
    
    for (final category in profile.categories) {
      final categoryPath = '${baseDir.path}/${profile.name}/${category.name}';
      await Directory(categoryPath).create(recursive: true);
      
      // Se la categoria va suddivisa per anno, crea le sottocartelle anni
      if (category.splitByYear) {
        final years = await _getYearsForCategory(category.id);
        for (final year in years) {
          await Directory('$categoryPath/$year').create(recursive: true);
        }
      }
    }
    
    // Crea sempre la cartella "Da revisionare"
    await Directory('${baseDir.path}/_Da_revisionare').create(recursive: true);
  }

  // Copia la foto nella cartella corretta
  Future<void> copyPhotoToAlbumFolder({
    required String sourcePath,
    required String categoryName,
    required String profileName,
    int? year,
    String? personName,
  }) async {
    final baseDir = await _getBaseDirectory();
    
    String targetDir = '${baseDir.path}/$profileName/$categoryName';
    if (year != null) targetDir += '/$year';
    if (personName != null) targetDir = '${baseDir.path}/$profileName/Persone/$personName';
    
    await Directory(targetDir).create(recursive: true);
    
    final sourceFile = File(sourcePath);
    final fileName = path.basename(sourcePath);
    final targetPath = '$targetDir/$fileName';
    
    // Copia solo se non esiste già
    if (!await File(targetPath).exists()) {
      await sourceFile.copy(targetPath);
    }
  }

  // Rinomina una cartella quando l'album viene rinominato
  Future<void> renameAlbumFolder({
    required String oldName,
    required String newName,
    required String profileName,
  }) async {
    final baseDir = await _getBaseDirectory();
    final oldDir = Directory('${baseDir.path}/$profileName/$oldName');
    final newDir = Directory('${baseDir.path}/$profileName/$newName');
    
    if (await oldDir.exists()) {
      await oldDir.rename(newDir.path);
    }
  }

  // Ottieni il percorso base (configurabile dall'utente)
  Future<Directory> _getBaseDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('base_folder_path');
    
    if (customPath != null) {
      return Directory(customPath);
    }
    
    // Default: storage pubblico
    return Directory('/storage/emulated/0/PhotoAI');
  }
}
```

### 7.4 Opzioni cartelle per l'utente

- **Cartella base personalizzabile**: l'utente sceglie dove creare la cartella principale (`/PhotoAI/`, `/MieFoto/`, ecc.)
- **Naming automatico**: la cartella prende il nome della categoria (modificabile)
- **Copia vs. collegamento**: l'utente sceglie se copiare la foto nella cartella o usare symlink
- **Pulizia**: opzione per rimuovere le cartelle e foto duplicate quando si elimina un album
- **Esclusione dalla galleria**: le cartelle PhotoAI possono essere escluse dalla galleria di sistema per evitare duplicati visibili

---

## 8. Backup Cloud Multi-Provider

### 8.1 Provider supportati

| Provider | Tipo | Piano gratuito | Autenticazione |
|---|---|---|---|
| **Google Drive** | Cloud Google | 15 GB | OAuth2 Google |
| **Dropbox** | Cloud indipendente | 2 GB | OAuth2 Dropbox |
| **OneDrive** | Cloud Microsoft | 5 GB | OAuth2 Microsoft |
| **Mega** | Cloud cifrato | 20 GB | Email + Password |
| **Manuale (cartella)** | NAS / SD card | Illimitato | Nessuna |

### 8.2 Architettura del sync

```dart
// services/cloud/cloud_sync_service.dart

abstract class CloudProvider {
  String get name;
  String get emoji;
  Future<bool> authenticate();
  Future<void> uploadFile(File file, String remotePath);
  Future<void> createFolder(String remotePath);
  Future<List<String>> listFolder(String remotePath);
  Future<void> deleteFile(String remotePath);
  Future<bool> fileExists(String remotePath);
}

class CloudSyncService {
  final List<CloudProvider> _activeProviders = [];

  // Sync completo di tutti gli album su tutti i provider attivi
  Future<void> syncAll({bool wifiOnly = true}) async {
    // Controlla connessione
    final connectivity = await Connectivity().checkConnectivity();
    if (wifiOnly && connectivity != ConnectivityResult.wifi) {
      return; // Aspetta il Wi-Fi
    }

    final baseDir = await FolderService().getBaseDirectory();
    
    for (final provider in _activeProviders) {
      await _syncDirectoryToCloud(baseDir, provider, '/PhotoAI');
    }
  }

  // Sync ricorsivo di una cartella
  Future<void> _syncDirectoryToCloud(
    Directory localDir,
    CloudProvider provider,
    String remotePath,
  ) async {
    await provider.createFolder(remotePath);
    
    await for (final entity in localDir.list()) {
      if (entity is Directory) {
        final folderName = path.basename(entity.path);
        await _syncDirectoryToCloud(
          entity, provider, '$remotePath/$folderName'
        );
      } else if (entity is File) {
        final fileName = path.basename(entity.path);
        final remoteFilePath = '$remotePath/$fileName';
        
        // Carica solo se non esiste già (by name — future versioni: by hash)
        if (!await provider.fileExists(remoteFilePath)) {
          await provider.uploadFile(entity, remoteFilePath);
        }
      }
    }
  }
}
```

### 8.3 Google Drive — Implementazione

```dart
// services/cloud/google_drive_provider.dart
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveProvider implements CloudProvider {
  @override
  String get name => 'Google Drive';
  @override
  String get emoji => '📁';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );
  
  drive.DriveApi? _driveApi;

  @override
  Future<bool> authenticate() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      
      final authHeaders = await account.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(client);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> uploadFile(File file, String remotePath) async {
    final parts = remotePath.split('/');
    final fileName = parts.last;
    final folderPath = parts.sublist(0, parts.length - 1).join('/');
    
    final folderId = await _ensureFolderExists(folderPath);
    
    final driveFile = drive.File()
      ..name = fileName
      ..parents = [folderId];
    
    await _driveApi!.files.create(
      driveFile,
      uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
    );
  }

  Future<String> _ensureFolderExists(String folderPath) async {
    // Crea la struttura di cartelle su Drive se non esiste
    // e ritorna l'ID della cartella finale
    // ... (implementazione ricorsiva)
    return 'folder_id';
  }
}
```

### 8.4 Dropbox — Implementazione

```dart
// services/cloud/dropbox_provider.dart
class DropboxProvider implements CloudProvider {
  @override
  String get name => 'Dropbox';
  @override
  String get emoji => '📦';

  static const String _clientId = 'TUO_DROPBOX_CLIENT_ID';
  String? _accessToken;

  @override
  Future<bool> authenticate() async {
    // OAuth2 con Dropbox
    // Apertura browser per autorizzazione, callback con token
    _accessToken = await _dropboxOAuth();
    return _accessToken != null;
  }

  @override
  Future<void> uploadFile(File file, String remotePath) async {
    final response = await Dio().post(
      'https://content.dropboxapi.com/2/files/upload',
      options: Options(headers: {
        'Authorization': 'Bearer $_accessToken',
        'Dropbox-API-Arg': jsonEncode({
          'path': '/PhotoAI/$remotePath',
          'mode': 'add',
          'autorename': false,
        }),
        'Content-Type': 'application/octet-stream',
      }),
      data: file.openRead(),
    );
  }
}
```

### 8.5 Mega — Implementazione

```dart
// services/cloud/mega_provider.dart
// Mega non ha SDK Flutter ufficiale, si usa la REST API via dio
class MegaProvider implements CloudProvider {
  @override
  String get name => 'Mega';
  @override
  String get emoji => '🔒';

  // Mega usa crittografia end-to-end
  // L'autenticazione avviene con email + password
  // I file vengono cifrati localmente prima dell'upload

  @override
  Future<bool> authenticate() async {
    // Apertura dialog in-app per email + password Mega
    // Derivazione chiave dalla password (PBKDF2)
    // Autenticazione con le API Mega
    return true;
  }
}
```

### 8.6 OneDrive — Implementazione

```dart
// services/cloud/onedrive_provider.dart
class OneDriveProvider implements CloudProvider {
  @override
  String get name => 'OneDrive';
  @override
  String get emoji => '☁️';

  // Usa Microsoft Graph API
  // OAuth2 con account Microsoft/Azure AD
  static const String _clientId = 'TUO_MICROSOFT_CLIENT_ID';

  @override
  Future<void> uploadFile(File file, String remotePath) async {
    // Microsoft Graph upload per file < 4MB
    final response = await Dio().put(
      'https://graph.microsoft.com/v1.0/me/drive/root:/$remotePath:/content',
      options: Options(headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/octet-stream',
      }),
      data: file.openRead(),
    );
    
    // Per file > 4MB: upload session (chunked upload)
  }
}
```

### 8.7 Configurazione Sync — Impostazioni utente

```
┌──────────────────────────────────────┐
│ ☁️ Impostazioni Backup Cloud         │
├──────────────────────────────────────┤
│                                      │
│  Provider attivi:                    │
│  📁 Google Drive          ✅ Attivo  │
│  📦 Dropbox               ❌ Off     │
│  ☁️  OneDrive              ❌ Off     │
│  🔒 Mega                  ✅ Attivo  │
│  📂 Cartella manuale       ❌ Off     │
│                                      │
│  ─── Opzioni sync ──────────────────│
│                                      │
│  Sync automatico:          ✅        │
│  Solo su Wi-Fi:            ✅        │
│  Frequenza: [Ogni notte ▼]          │
│  Solo nuove foto:          ✅        │
│  Comprimi prima del cloud: ❌        │
│                                      │
│  ─── Cosa sincronizzare ────────────│
│  ✅ Tutte le cartelle album          │
│  ✅ Cartella "Da revisionare"        │
│  ❌ Foto originali (solo albumate)   │
│                                      │
│  Spazio usato su Drive: 2.3 GB / 15 │
│  Ultima sync: oggi 03:14             │
│                                      │
│  [🔄 SINCRONIZZA ORA]               │
└──────────────────────────────────────┘
```

### 8.8 Gestione conflitti e delta sync

- **File già presenti**: non vengono ricaricati (confronto per nome + dimensione)
- **File modificati**: versioning semplice (aggiunta suffisso data)
- **File eliminati dall'album**: rimangono sul cloud (soft delete, l'utente decide)
- **Delta sync**: ad ogni avvio app controlla solo le modifiche dall'ultima sync
- **Stato sync per file**: ogni foto nel DB ha un campo `cloud_sync_status` (synced, pending, error)

---

## 9. Interfaccia Utente (UI/UX)

### Schermata — Home / Dashboard

```
┌──────────────────────────────────┐
│ 📷 PhotoAI            👤  ⚙️   │
│ Profilo: 🪵 Falegname    [▼]   │
├──────────────────────────────────┤
│ ☁️ Sync: ✅ Drive · ✅ Mega     │
│ 📂 Cartelle: /storage/PhotoAI   │
├──────────────────────────────────┤
│                                  │
│  ┌──────────┐  ┌──────────┐     │
│  │🚪 Porte  │  │🍳 Cucine │     │
│  │ 127 foto │  │  89 foto │     │
│  │📁✅☁️   │  │📁✅☁️   │     │
│  └──────────┘  └──────────┘     │
│                                  │
│  ┌──────────┐  ┌──────────┐     │
│  │🎭Carne.  │  │👨‍👩‍👧Famiglia│     │
│  │  3 anni  │  │ 234 foto │     │
│  │📁✅⏳   │  │📁✅☁️   │     │
│  └──────────┘  └──────────┘     │
│                                  │
│ ════════════════════════════════ │
│  1,847 foto totali analizzate    │
│  Ultima scan: oggi 14:30         │
│  [🔍 NUOVA SCANSIONE]           │
└──────────────────────────────────┘
```
*(📁 = cartella creata, ✅ = sincronizzato, ⏳ = sync in attesa)*

### Schermata — Selezione Professione (Primo avvio)

```
┌──────────────────────────────────┐
│ 👋 Benvenuto in PhotoAI Catalog  │
│    Seleziona la tua professione  │
├──────────────────────────────────┤
│  🔍 Cerca professione...         │
├──────────────────────────────────┤
│ 🏗️ ARTIGIANATO                  │
│  ├── 🪵 Falegname / Ebanista     │
│  ├── 🧱 Muratore / Impresa edile │
│  ├── ⚡ Elettricista             │
│  ├── 🔧 Idraulico               │
│  └── 🎨 Pittore / Decoratore    │
│                                  │
│ 📸 ARTE E CREATIVITÀ             │
│  ├── 📷 Fotografo               │
│  ├── 🎨 Artista / Pittore       │
│  └── ✂️ Stilista / Sarto        │
│                                  │
│ 🍽️ RISTORAZIONE                  │
│  ├── 👨‍🍳 Chef / Cuoco            │
│  └── 🍰 Pasticcere              │
│                                  │
│  [➕ CREA PROFILO PERSONALIZZATO]│
│  [📥 IMPORTA PROFILO]           │
└──────────────────────────────────┘
```

### Schermata — Dettaglio Album con Cartella

```
┌──────────────────────────────────┐
│ ← 🚪 Porte              ✏️  ⋮  │
├──────────────────────────────────┤
│  127 foto · Aggiornato oggi      │
│                                  │
│  📁 /PhotoAI/Falegname/Porte/    │
│  ☁️ Drive: ✅ sync · Mega: ✅    │
│                                  │
│  [📂 Apri cartella] [☁️ Sync ora]│
├──────────────────────────────────┤
│  📅 Filtra: [Tutti ▼]  🔤[A-Z▼] │
├──────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐      │
│ │[foto]│ │[foto]│ │[foto]│      │
│ └──────┘ └──────┘ └──────┘      │
│ ┌──────┐ ┌──────┐ ┌──────┐      │
│ │[foto]│ │[foto]│ │[foto]│      │
│ └──────┘ └──────┘ └──────┘      │
│                                  │
│ [📤 Esporta] [🗑️ Gestisci]      │
└──────────────────────────────────┘
```

### Schermata — Impostazioni Categoria

```
┌──────────────────────────────────┐
│ ← ✏️ Modifica categoria          │
├──────────────────────────────────┤
│                                  │
│  Emoji:  [🚪]                    │
│  Nome:   [Porte              ]   │
│                                  │
│  Descrizione per AI:             │
│  ┌──────────────────────────────┐│
│  │porta interna, porta blindata,││
│  │portone, stipite, telaio,     ││
│  │anta, infisso legno...        ││
│  └──────────────────────────────┘│
│                                  │
│  🔄 Suddividi per anno:    ❌    │
│  📁 Nome cartella: [Porte    ]   │
│                                  │
│  Soglia confidenza AI:           │
│  60% ●──────────────○ 95%        │
│       [75%]                      │
│                                  │
│  ─── Anteprima cartella ────────  │
│  📁 /PhotoAI/Falegname/Porte/    │
│     127 foto · 2.3 GB            │
│                                  │
│  [🗑️ Elimina] [✅ SALVA]        │
└──────────────────────────────────┘
```

---

## 10. Scheletro del Codice Flutter

### Struttura del progetto aggiornata

```
photo_ai_catalog/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── gemini_prompts.dart
│   │   │   └── professions_catalog.dart    ← catalogo professioni
│   │   ├── database/
│   │   │   └── database_helper.dart
│   │   └── utils/
│   │       ├── image_utils.dart
│   │       └── exif_utils.dart
│   │
│   ├── models/
│   │   ├── photo.dart
│   │   ├── album.dart
│   │   ├── person.dart
│   │   ├── category.dart
│   │   ├── profession.dart                 ← modello professione
│   │   ├── profile.dart                    ← profilo utente
│   │   ├── cloud_sync_status.dart
│   │   └── scan_result.dart
│   │
│   ├── services/
│   │   ├── gallery_service.dart
│   │   ├── gemini_service.dart
│   │   ├── face_service.dart
│   │   ├── scan_service.dart
│   │   ├── database_service.dart
│   │   ├── folder_service.dart             ← gestione cartelle fisiche
│   │   └── cloud/
│   │       ├── cloud_sync_service.dart     ← orchestratore sync
│   │       ├── cloud_provider.dart         ← interfaccia astratta
│   │       ├── google_drive_provider.dart
│   │       ├── dropbox_provider.dart
│   │       ├── onedrive_provider.dart
│   │       ├── mega_provider.dart
│   │       └── manual_folder_provider.dart
│   │
│   ├── providers/ (Riverpod)
│   │   ├── albums_provider.dart
│   │   ├── persons_provider.dart
│   │   ├── categories_provider.dart
│   │   ├── professions_provider.dart
│   │   ├── scan_provider.dart
│   │   └── cloud_sync_provider.dart
│   │
│   └── screens/
│       ├── onboarding/
│       │   ├── welcome_screen.dart
│       │   └── profession_picker_screen.dart   ← selezione professione
│       ├── home/
│       │   └── home_screen.dart
│       ├── album/
│       │   ├── album_list_screen.dart
│       │   └── album_detail_screen.dart
│       ├── person/
│       │   ├── person_list_screen.dart
│       │   └── add_person_screen.dart
│       ├── category/
│       │   ├── category_list_screen.dart
│       │   └── category_edit_screen.dart
│       ├── profession/
│       │   └── profession_settings_screen.dart
│       ├── cloud/
│       │   └── cloud_settings_screen.dart      ← impostazioni backup cloud
│       ├── scan/
│       │   └── scan_screen.dart
│       └── settings/
│           └── settings_screen.dart
│
├── assets/
│   └── professions/
│       └── professions_catalog.json            ← catalogo JSON professioni
│
└── pubspec.yaml
```

### Modello Professione

```dart
// models/profession.dart
class ProfessionCategory {
  final String id;
  final String name;
  final String emoji;
  final String description;        // keywords per il prompt AI
  final bool splitByYear;
  final bool isCustom;             // false = predefinita, true = aggiunta dall'utente
  final String folderName;         // nome cartella fisica (default = name)

  const ProfessionCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.splitByYear = false,
    this.isCustom = false,
    String? folderName,
  }) : folderName = folderName ?? name;
}

class Profession {
  final String id;
  final String name;
  final String emoji;
  final String sector;
  final List<ProfessionCategory> defaultCategories;
  final bool isCustom;
}

class UserProfile {
  final String id;
  final String name;
  final String emoji;
  final Profession baseProfession;
  final List<ProfessionCategory> categories; // default + personalizzate
  final String baseFolderPath;               // percorso cartella base
  final Map<String, bool> cloudSyncEnabled;  // quale provider è attivo
  final DateTime createdAt;
}
```

### Catalogo Professioni (JSON — caricato da assets)

```json
{
  "version": "1.0",
  "sectors": [
    {
      "id": "artigianato",
      "name": "Artigianato e Costruzioni",
      "emoji": "🏗️",
      "professions": [
        {
          "id": "falegname",
          "name": "Falegname / Ebanista",
          "emoji": "🪵",
          "categories": [
            {
              "id": "porte",
              "name": "Porte",
              "emoji": "🚪",
              "description": "porta interna, porta blindata, portone, stipite, telaio porta, anta, uscio, portoncino",
              "splitByYear": false,
              "folderName": "Porte"
            },
            {
              "id": "cucine",
              "name": "Cucine",
              "emoji": "🍳",
              "description": "mobile cucina, pensile cucina, base cucina, anta cucina, cassetto cucina, blocco cucina",
              "splitByYear": false,
              "folderName": "Cucine"
            }
          ]
        }
      ]
    }
  ]
}
```

---

## 11. Flusso di Catalogazione

```
AVVIO SCANSIONE
      │
      ▼
Carica lista foto dalla galleria (solo nuove dall'ultima scan)
      │
      ▼
Per ogni foto:
 ┌────┴─────────────────────────────────────┐
 │                                          │
 ▼                                          ▼
Comprimi foto (800px)                Leggi metadati EXIF
                                     (data, GPS, anno)
 └──────────────────┬───────────────────────┘
                    │
                    ▼
         Foto già in cache AI? ──SÌ──► Usa risultato salvato
                    │ NO
                    ▼
         Invia a Gemini 2.0 Flash
         (prompt con categorie del profilo attivo)
                    │
                    ▼
         Ricevi: categoria + confidenza + descrizione
                    │
                    ▼
         Confidenza ≥ soglia? ──NO──► Cartella "_Da_revisionare"
                    │ SÌ
                    ▼
         ML Kit: rileva e riconosce volti
                    │
                    ▼
         Salva nel DB SQLite
         (categoria, persone, anno, path)
                    │
                    ▼
         FolderService.copyPhotoToAlbumFolder()
         → copia foto nella cartella fisica corretta
                    │
                    ▼
         Aggiorna album virtuale nel DB
                    │
                    ▼
         Marca foto come "pending sync" per il cloud
                    │
                    ▼
FINE SCANSIONE → CloudSyncService.syncPending() (se Wi-Fi)
```

---

## 12. Gestione della Privacy

### Dati inviati al cloud AI (Gemini)
- Immagini compresse e ridimensionate (max 800px)
- NON vengono inviati: percorso file, nome file, metadati EXIF, coordinate GPS, identità persone

### Dati che rimangono on-device (ML Kit)
- Tutti gli embedding facciali rimangono esclusivamente sul dispositivo
- Il database SQLite è locale e non condiviso
- I risultati AI vengono cachati localmente dopo la prima analisi

### Dati inviati al cloud storage (Google Drive, Mega, ecc.)
- Le foto (copie degli originali) vengono caricate sul provider scelto dall'utente
- Mega offre crittografia end-to-end: neanche Mega può vedere i file
- Google Drive e Dropbox: i file sono leggibili dal provider (ma protetti dal tuo account)

### Permessi Android richiesti
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

---

## 13. Struttura del Database SQLite

```sql
-- Profili utente
CREATE TABLE profiles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT,
  profession_id TEXT,
  base_folder_path TEXT,
  is_active INTEGER DEFAULT 0,
  created_at INTEGER
);

-- Categorie (predefinite + personalizzate)
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  profile_id TEXT,
  name TEXT NOT NULL,
  emoji TEXT,
  description TEXT,
  keywords TEXT,           -- JSON array
  split_by_year INTEGER DEFAULT 0,
  folder_name TEXT,
  confidence_threshold REAL DEFAULT 0.75,
  is_predefined INTEGER DEFAULT 0,
  sort_order INTEGER,
  is_active INTEGER DEFAULT 1
);

-- Foto analizzate
CREATE TABLE photos (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL,
  date_taken INTEGER,
  year INTEGER,
  ai_category TEXT,
  ai_confidence REAL,
  ai_description TEXT,
  is_manually_moved INTEGER DEFAULT 0,
  analyzed_at INTEGER,
  latitude REAL,
  longitude REAL,
  local_folder_path TEXT,      -- percorso cartella fisica dove è stata copiata
  cloud_sync_status TEXT DEFAULT 'pending',  -- pending / synced / error
  cloud_sync_at INTEGER
);

-- Album
CREATE TABLE albums (
  id TEXT PRIMARY KEY,
  profile_id TEXT,
  name TEXT NOT NULL,
  emoji TEXT,
  category_id TEXT,
  person_id TEXT,
  year INTEGER,
  folder_path TEXT,            -- percorso cartella fisica
  cover_photo_id TEXT,
  photo_count INTEGER DEFAULT 0,
  cloud_synced INTEGER DEFAULT 0,
  created_at INTEGER,
  updated_at INTEGER
);

-- Persone
CREATE TABLE persons (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  nickname TEXT,
  relationship TEXT,
  profile_image_path TEXT,
  face_embeddings BLOB,
  album_id TEXT,
  folder_path TEXT,
  created_at INTEGER
);

-- Relazione foto-persone
CREATE TABLE photo_persons (
  photo_id TEXT,
  person_id TEXT,
  confidence REAL,
  PRIMARY KEY (photo_id, person_id)
);

-- Log sync cloud
CREATE TABLE cloud_sync_log (
  id TEXT PRIMARY KEY,
  provider TEXT,
  photo_id TEXT,
  remote_path TEXT,
  status TEXT,
  error_message TEXT,
  synced_at INTEGER
);

-- Professioni custom create dall'utente
CREATE TABLE custom_professions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT,
  sector TEXT,
  categories TEXT,    -- JSON array di categorie
  is_shared INTEGER DEFAULT 0,
  created_at INTEGER
);
```

---

## 14. Roadmap e Versioni

### v1.0 — MVP Core
- Scansione galleria Android
- Integrazione Gemini 2.0 Flash
- Sistema professioni con catalogo predefinito (tutti i settori)
- Profili multipli e categorie personalizzabili
- Album automatici
- Creazione cartelle fisiche corrispondenti
- Database SQLite locale
- UI completa

### v1.5 — Persone e Volti
- ML Kit Face Recognition
- Registro persone con album dedicati
- Cartelle per persona
- Album eventi per anno con sottocartelle

### v2.0 — Cloud Sync
- Backup Google Drive
- Backup Dropbox
- Backup OneDrive
- Backup Mega (con cifratura)
- Sync automatico notturno su Wi-Fi
- Dashboard stato sync

### v2.5 — Social e Condivisione
- Esportazione profilo professionale (JSON)
- Marketplace profili (condivisione community)
- Importazione profili di altri utenti
- Widget home screen Android

### v3.0 — Privacy First
- Integrazione Ollama + LLaVA (analisi completamente offline)
- Zero dati inviati a server esterni
- Sincronizzazione opzionale con Nextcloud self-hosted

---

## 15. Requisiti di Sistema

### Dispositivo Android
| Requisito | Minimo | Consigliato |
|---|---|---|
| Versione Android | Android 8.0 (API 26) | Android 12+ |
| RAM | 3 GB | 6 GB+ |
| Storage libero | 1 GB | 5 GB+ |
| Connessione | Internet per AI | Wi-Fi per sync cloud |

### API Keys necessarie (tutte gratuite per uso personale)
| Servizio | Come ottenerla | Limite gratuito |
|---|---|---|
| Gemini 2.0 Flash | aistudio.google.com/apikey | 1.500 req/giorno |
| Google Drive | console.cloud.google.com | 15 GB storage |
| Dropbox | dropbox.com/developers | 2 GB storage |
| OneDrive | portal.azure.com | 5 GB storage |
| Mega | mega.nz (account gratuito) | 20 GB storage |

### Ambiente di sviluppo
| Strumento | Versione |
|---|---|
| Flutter SDK | 3.22+ |
| Dart SDK | 3.4+ |
| Android Studio | Hedgehog+ |
| Java JDK | 17+ |
| Gradle | 8.x |

---

## Stima Tempi di Sviluppo

| Fase | Contenuto | Durata |
|---|---|---|
| Setup + UI base | Struttura, navigazione, onboarding | 1 settimana |
| Sistema professioni | Catalogo JSON, picker, profili | 1 settimana |
| Galleria + EXIF | Lettura foto e metadati | 3-5 giorni |
| Gestione cartelle fisiche | FolderService, sync DB-cartelle | 3-5 giorni |
| Integrazione Gemini AI | Analisi, prompt, cache | 1 settimana |
| Face recognition ML Kit | Registrazione, riconoscimento | 1-2 settimane |
| Cloud sync (tutti i provider) | Drive, Dropbox, OneDrive, Mega | 2 settimane |
| Rifinitura UI/UX | Animazioni, dark mode, polish | 1 settimana |
| Testing e bug fix | Dispositivi reali, edge cases | 1 settimana |
| **TOTALE** | | **9-12 settimane** |

---

*Documento: PhotoAI Catalog — Documentazione Tecnica Completa v2.0*
*Aggiornato: Febbraio 2026*
