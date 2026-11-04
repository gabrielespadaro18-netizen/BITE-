# BITE! — versione SwiftUI aggiornata

Base: i **15 file Swift** e gli asset originali forniti dall'utente, con l'interfaccia degli **8 screenshot Sketch**. La cartella `BITE/` contiene **23 file Swift**, le tre mascotte originali e quattro silhouette delle mappe ricavate dai reference Sketch. Il progetto nativo `BITE.xcodeproj` è incluso e il file `project.yml` è fornito come alternativa per XcodeGen.

## Modifiche effettivamente implementate

1. **Scontrini:** `Pantry` → `Add Food` → `Scan Receipt`. È possibile fare una foto con la fotocamera su un dispositivo reale oppure selezionarla nella libreria. OCR on-device Apple Vision (italiano/inglese), estrazione delle possibili righe prodotto, controllo/eliminazione/modifica delle righe e delle quantità, aggiunta alla dispensa *solo dopo conferma*. Le foto non sono inviate ad Airtable.
2. **Icone Sketch/SF Symbols:** barra inferiore a quattro schede con icone utensili, ciotola/cucchiaio, calendario e carota; icona del pulsante `Plan Your Meal`; calendari 1/7 nella scelta daily/weekly; silhouette geografiche estratte dagli screenshot per Europa, Asia, Africa e Sud America (per gli altri continenti, fallback SF Symbols). Verde di riferimento `#34C759` e menta `#C3F5D0`.
3. **Liste vuote all'inizio:** `SeedData.pantry` e `SeedData.shopping` partono vuote. Una migrazione elimina anche la combinazione *esatta* dei vecchi dati dimostrativi quando non risultano piani o ricette recenti; non elimina altri inventari personali. `Reset all data` ripristina elenchi vuoti.
4. **Ricette basate sulla dispensa:** `Pantry` → `Cook with my pantry`, oppure `Recipes` → `From my pantry`. Le ricette sono ordinate per ingredienti mancanti, distinguendo quelle pronte da quelle con 1–2 ingredienti mancanti; se la dispensa è vuota appare uno stato vuoto. Sono inclusi 8 schemi di ricette personalizzate scritti esplicitamente, proposti solo quando tutti gli ingredienti nominati sono disponibili; possono essere salvati come ricette proprie.
5. **Ricette personali:** `Recipes` → `My own recipe`. Inserimento libero di nome e ingredienti con quantità, selezione facoltativa di ingredienti in dispensa, durata, porzioni, pasto e passaggi; salvataggio in `AppState`/UserDefaults e integrazione in ricerca, dettagli e pianificazione. Le ricette personali non vengono condivise con altri utenti e non sono inviate al database remoto.
6. **Airtable:** creata la base remota **BITE! - Recipe Catalog** con **174 record attualmente presenti** (catalogo originale, ricette semplici e nuove ricette senza glutine; alcune ricette aggiuntive erano già state inserite nella base). Include le 90 originali e 54 nuove ricette semplici (3 per nazione). Sono state create anche 18 righe `Countries`. Il proxy read-only per iOS si trova in `Backend/`.

## Base Airtable reale

- URL: https://airtable.com/apprz0iFWleXvRBBW
- Base ID: `apprz0iFWleXvRBBW`
- Tabella `Recipes`: `tbla8wjgmaHEgMbr9`
- Tabella `Countries`: `tbl0rMpSJXSUuLnnw`
- Verifica effettuata dopo l'importazione: **174 record** in `Recipes` alla verifica del 4 novembre 2026, con almeno 8 ricette per Paese.
- Sono state conservate le etichette `Verified`/`Draft`: le 22 ricette indicate come complete dal vecchio catalogo sono marcate `Verified`, mentre le 68 ricette originariamente in bozza e le 54 nuove sono marcate `Draft`. I dati delle ricette non sono certificazioni mediche di sicurezza alimentare.

### Collegare l'app iOS in modo sicuro

Per **non includere un Airtable PAT nell'app installabile**, l'app usa una piccola API read-only. La base Airtable **esiste già** ed è popolata, ma l'API va pubblicata dalla persona che controlla il servizio di hosting; senza questo passaggio l'app continua a funzionare con il catalogo locale incluso.

1. Crea un *personal access token* Airtable con il solo scope `data.records:read` e accesso esclusivamente alla base BITE!, da https://airtable.com/create/tokens. **Non inserirlo nei file Swift o su GitHub.**
2. Crea/accedi a un account Cloudflare. Apri un terminale nella cartella `Backend` e lancia:

   ```bash
   npx wrangler login
   npx wrangler secret put AIRTABLE_TOKEN
   npx wrangler deploy
   ```

   Al secondo comando inserisci il token quando richiesto. Il file `wrangler.toml` contiene già i due ID Airtable non segreti.
3. Copia l'indirizzo HTTPS pubblico del Worker al termine del deploy; in `BITE/Info.plist` sostituisci `https://YOUR_WORKER.workers.dev/recipes` con `https://<worker-reale>.workers.dev/recipes` (mantieni `/recipes`).
4. Riapri l'app; dalla pagina Profilo puoi anche premere `Refresh from Airtable`. A connessione riuscita compare `Airtable synchronized · <numero ricette ricevute>`.

**Importante:** l'integrazione Airtable è **in sola lettura** per il catalogo, mentre dispensa, piano e ricette personali restano locali. Pubblicare il catalogo tramite Worker significa renderne consultabili le informazioni dall'URL pubblico, non i dati privati degli utenti.

## Aprire e provare BITE! su Mac

1. Apri `BITE.xcodeproj` in Xcode (consigliata una versione recente, inclusa Xcode 27). Il progetto ha deployment target iOS **17.0+** e supporta quindi versioni successive di iOS.
2. Seleziona il target `BITE`, scegli un iPhone Simulator e premi `⌘B` per compilare e poi `⌘R` per eseguire.
3. Per installare su iPhone fisico configura il tuo `Team` e un bundle identifier univoco in **Signing & Capabilities**. L'acquisizione dalla fotocamera richiede un dispositivo con fotocamera; in simulatore è disponibile la selezione dalla libreria foto.
4. Completa l'onboarding: la dispensa e la lista della spesa devono essere **vuote**. Inserisci alcuni alimenti (ad esempio Eggs e Tomatoes), apri `Cook with my pantry`, seleziona una ricetta e prova a salvarla in `My recipes`.
5. Prova uno scontrino reale verificando e correggendo le righe prima della conferma; poi aggiungi un pasto al calendario e controlla la lista della spesa.

Se preferisci rigenerare il progetto con XcodeGen, nella radice lancia `xcodegen generate` usando il `project.yml` incluso (XcodeGen va installato separatamente). Il `.xcodeproj` già presente non ne ha bisogno.

## Controlli eseguiti in questo ambiente

Eseguiti con esito positivo:

```text
PASS: receipt parser · 4 candidates
PASS: catalog has 156 recipes, at least 8 per country, 22 verified
PASS: Airtable worker payload decodes into the iOS Recipe model
PASS: worker Airtable pagination, decoding, and missing-credentials error
BITE.xcodeproj/project.pbxproj: OK
```

Inoltre: `swiftc -frontend -parse` su tutti i file Swift, lint del progetto `.pbxproj`, convalida di `Info.plist` ed effettivo conteggio dei record nel database Airtable. Gli esempi di test si eseguono con `./Tests/run-tests.sh` (richiede Swift e facoltativamente Node.js).

**Limite importante:** questo ambiente è Linux e non contiene l'SDK iOS/Xcode. Non è stato possibile eseguire `xcodebuild`, lanciare un simulatore iPhone né verificare dal vivo tutti i flussi della UI. La validità sintattica e i test dei modelli **non equivalgono** a una compilazione iOS riuscita. Per dichiarare la release pronta è necessaria la prova in Xcode su Mac/iPhone e, per il sync remoto, il deploy del Worker.

## Note sulla qualità e sulla sicurezza

- L'OCR interpreta testo stampato, non è una lettura infallibile degli alimenti: le righe possono contenere intestazioni o errori e vanno confermate dall'utente.
- Il confronto con la dispensa si basa sui nomi degli ingredienti e su una quantità intera semplificata, non garantisce che ci siano i grammi necessari per ogni ricetta.
- Le ricette `Draft` (incluse nuove e personalizzate) non sono suggerite automaticamente agli utenti che hanno indicato allergie, intolleranze o diete restrittive. Le informazioni sulle allergie del catalogo non sostituiscono la verifica delle etichette originali.
- La scelta delle icone segue gli screenshot forniti; per gli asset non visibili negli screenshot si usa un fallback coerente in SF Symbols invece di inventare grafiche attribuite allo Sketch.
- Tutte le risorse originali sono incluse. Le schermate sono conservate in `DesignReferences/`, fuori dal target iOS per evitare di aggiungere immagini di riferimento inutili al bundle.


## Aggiornamento 4 novembre 2026 — correzioni richieste

1. **Home:** mela `MascotHappy` riposizionata sopra la CTA senza acquisire tocchi; icona SF Symbols `takeoutbag.and.cup.and.straw` e angoli del pulsante più arrotondati (`cornerRadius: 58`). La tab bar conserva icone Sketch: posate nel cerchio, ciotola/cucchiaio, calendario e carota, selezione menta.
2. **Pantry:** i pulsanti `Cook with my pantry` e `Open Shopping List` sono ora in un inset inferiore separato dal `List`. La lista può crescere e scrollare, mantenendo i pulsanti distanti dalla tab bar (da verificare in Xcode su diverse dimensioni schermo).
3. **My own recipe:** campo nome modificabile, ingredienti aggiungibili liberamente con quantità facoltative, pulsanti Aggiungi/Rimuovi ingrediente; gli alimenti della dispensa sono facoltativi. Il salvataggio richiede nome, almeno un ingrediente (manuale o da dispensa) e un passaggio di preparazione.
4. **Ricette gluten-free:** ulteriori **12 ricette senza glutine** aggiunte a `simple_recipes.json` e inserite in Airtable. Il catalogo locale completo contiene ora **156 ricette** (90 originali + 54 semplici + 12 nuove senza glutine), oltre a 8 template opzionali basati sulla dispensa. La sezione `Gluten-Free ideas` nel tab Ricette mostra le nuove ricette. Sono **bozze**, non certificate: controllare etichette, allergeni e contaminazioni.
5. **Onboarding facoltativo:** tasto `Skip` sempre disponibile, finestra di conferma, flag `skippedOnboarding` salvato senza interrompere la lettura dei profili delle vecchie versioni; al primo ingresso nella Home un avviso ricorda come completare il percorso dal profilo.
6. **Notifiche locali:** `Profile` → `Notifications`: soglia scorte basse di 2 unità, avvisi scadenza due giorni prima, promemoria shopping dopo 24 ore e promemoria piano prima del pasto programmato. Usa `UserNotifications`; è necessario premere **Enable notifications on this iPhone** per concedere il permesso. Nessun dato viene inviato a un servizio di notifiche.
7. **Liste al primo avvio:** eliminato il caricamento di dati demo anche nell'inizializzatore `AppState` e in `resetAll`, senza cancellare gli inventari reali già salvati.

### Test eseguiti su questa revisione

- Test Swift Foundation delle ricette: **PASS** (156 ricette, almeno 8 per Paese, 22 dichiarate verificate dal dataset originale).
- Test parser scontrino: **PASS**.
- Test di compatibilità della decodifica del vecchio profilo e del flag Skip, e struttura delle 12 ricette senza glutine: **PASS**.
- Analisi sintattica `swiftc -frontend -parse` di tutti i file Swift: **PASS**.
- `plutil -lint` per `project.pbxproj` e `Info.plist`: **PASS**.
- Test Node del Worker Airtable: **PASS**.
- Controlli statici delle nuove viste e dei nuovi flussi: **PASS**.

**La compilazione e i test di interfaccia su iOS 27 (compresi keyboard focus, safe area reale della tab bar, SF Symbols e rilascio delle notifiche) richiedono Xcode su Mac o un iPhone.** Questo ambiente Linux non ha l'SDK iOS e non può dichiarare una build iOS completata. Prima di pubblicare l'app, eseguire `⌘B`, `⌘R` e test interattivi sul simulatore e un iPhone reale. Le notifiche locali si testano solo dopo aver abilitato i permessi sul dispositivo. Anche le ricette remote richiedono il deploy dell'API Worker (il token non deve mai essere incluso nell'app).
