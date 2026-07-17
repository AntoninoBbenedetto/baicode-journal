# Design: skill di conversione export Google Docs → articolo del blog

Data: 2026-07-17

## Contesto

Gli articoli di baicode journal nascono come testo scritto fuori dal repository (vedi README, sezione "Pubblicare un articolo") e vengono poi trasformati in coppia di file `content/it/blog/<slug>.md` + `content/en/blog/<slug>.md`. Lo strumento di scrittura è Google Docs: l'autore scrive il documento, lo esporta come Markdown (funzione nativa "Download → Markdown"), e oggi deve trasformarlo a mano nel formato richiesto dal sito — frontmatter completo, `translationKey` allineato tra le due lingue, traduzione nella seconda lingua, branch dedicato.

Un esempio reale di export è stato aggiunto in `docs/Antonino_Benedetto_Presentazione.md`: è un file Markdown pulito (nessuna virgoletta tipografica, nessuna immagine, nessun artefatto di nota a piè di pagina), con un H1 come titolo del documento e sezioni H2 separate da `---`.

Requisito raccolto dall'autore: un processo **riutilizzabile**, non una conversione una tantum di questo singolo file. La forma scelta è una **skill di progetto** (non uno script deterministico): la trasformazione richiede giudizio (dove tagliare gli artefatti, come tradurre, come nominare lo slug) più che pura meccanica, quindi si presta a un flusso guidato e interattivo piuttosto che a un comando cieco.

## 1. Trigger e input

Nuova skill di progetto in `.claude/skills/convert-gdoc/SKILL.md`, invocabile con:

```
/convert-gdoc <path-al-file-esportato>
```

Il path è libero: nessuna cartella "inbox" imposta. L'utente esporta il documento da Google Docs, lo salva dove preferisce nel repository (come già fatto con `docs/Antonino_Benedetto_Presentazione.md`), e lo passa come argomento.

Se il path non esiste o non è un file `.md`, la skill si ferma con un messaggio d'errore chiaro, senza procedere.

## 2. Rilevamento immagini (guardia preliminare)

Prima di qualunque altra elaborazione, la skill scansiona il file sorgente per riferimenti a immagini (sintassi `![...](...)`) e verifica se esiste una cartella di asset associata (convenzione tipica dell'export Google Docs: `<nome-file>_files/` o `images/` accanto al `.md`).

Se trova immagini o una cartella associata: **si ferma subito**, spiega che la gestione immagini non è ancora supportata (nessuna pipeline immagini esiste nel repo — fuori scope di questo design) e non genera alcun file. L'utente può rimuovere le immagini dal documento sorgente e ritentare, oppure aspettare un futuro design dedicato.

Se il file è solo testo, la skill procede.

## 3. Ordine dei passi

Perché lo slug della lingua di destinazione dipende dalla traduzione (sezione 5), ma sia il branch (sezione 6) sia il controllo di conflitti richiedono di conoscere entrambi gli slug, la skill segue questo ordine fisso:

1. Estrae il titolo (primo H1) e propone slug + `tags` + `date` per la **sola lingua sorgente** (sezione 4a).
2. Pulisce il corpo della lingua sorgente (sezione 4b).
3. Traduce nella seconda lingua e propone titolo + slug per la **lingua di destinazione** (sezione 5).
4. Conferma finale: mostra entrambi gli slug, il `translationKey` proposto (`post-<slug-inglese>`, indipendentemente da quale delle due lingue sia sorgente o destinazione), `tags` e `date`; verifica che nessuno dei due path (`content/it/blog/<slug>.md`, `content/en/blog/<slug>.md`) esista già e che il `translationKey` non collida con uno esistente. Se un conflitto emerge, lo segnala e chiede valori alternativi invece di sovrascrivere.
5. Crea il branch `post/<slug-inglese>` da `main` (sezione 6).
6. Scrive i due file (sezione 7).

`draft: true` è sempre impostato in entrambi i file, non è negoziabile in questa fase: il flip a `false` resta un passo editoriale manuale successivo (invariato rispetto al workflow esistente in README).

## 4. Pulizia del contenuto (lingua sorgente)

### 4a. Metadati provvisori

Dal primo H1 del documento sorgente, la skill propone titolo e slug (kebab-case) per la lingua sorgente, da confermare o correggere subito (passo 1 della sezione 3).

### 4b. Pulizia meccanica

Sul corpo del documento (H1 già estratto e rimosso, va a `title`), la skill applica solo pulizia **meccanica** degli artefatti tipici dell'export Google Docs:

- spazi non-interrompibili (` `) → spazio normale;
- link di ancora/indice autogenerati (es. riferimenti tipo `[#heading-id]` senza corrispondenza semantica nel testo);
- riferimenti a note a piè di pagina orfani (marcatori numerici senza nota corrispondente rimasta nel testo);
- righe vuote in eccesso (più di una consecutiva) normalizzate a una sola.

Esplicitamente **non tocca**: grassetti/corsivi, uso di `---` come separatore di sezione, struttura degli heading H2/H3, elenchi puntati, em-dash (`—`) e altra punteggiatura tipografica intenzionale. Queste sono scelte editoriali dell'autore, non artefatti — se l'autore vuole cambiarle lo fa in revisione, la skill non riscrive la prosa.

## 5. Traduzione

Dopo la pulizia, la skill traduce il contenuto (titolo incluso) nella seconda lingua, con il mio supporto — non è una chiamata a un servizio di traduzione automatica esterno, è un passo assistito nella stessa conversazione. Mantiene la stessa struttura (stessi heading, stessi blocchi), lo stesso `translationKey`, e propone lo slug per la seconda lingua (default kebab-case del titolo tradotto, modificabile).

Entrambe le versioni (sorgente pulita + traduzione) vengono mostrate per revisione prima di essere scritte su disco: nessun file viene creato senza conferma esplicita, in particolare la traduzione va sempre riletta da un madrelingua/dall'autore prima di considerarla pronta.

## 6. Branch git

Dopo la conferma finale di entrambi gli slug, `translationKey`, `tags` e `date` (passo 4 della sezione 3) e prima di scrivere i file, la skill crea il branch `post/<slug-inglese>` da `main`, seguendo il workflow già documentato in README. Se il branch esiste già, si ferma e lo segnala invece di sovrascriverlo o passare a un nome diverso senza chiedere.

## 7. Output

La skill scrive:
- `content/it/blog/<slug-it>.md`
- `content/en/blog/<slug-en>.md`

ciascuno con frontmatter completo (`title`, `date`, `draft: true`, `translationKey`, `tags`) e corpo pulito/tradotto secondo le sezioni 4-5.

Non esegue `git add`, `commit`, `push` né apre una pull request: questi passi restano manuali, come per qualunque altra modifica al sito (README, sezione "Pubblicare un articolo").

## 8. Fuori scope

- **Gestione immagini**: rilevata e bloccata (sezione 2), non gestita. Richiede una pipeline immagini dedicata (cartella asset, riscrittura path, ottimizzazione) che è un design a parte.
- **Automazione git oltre la creazione del branch**: nessun commit/push/PR automatico.
- **Riscrittura di stile o tono**: la skill pulisce artefatti meccanici, non editing.
- **Deduzione automatica di tag o categoria**: sempre richiesti esplicitamente all'utente.
- **Script deterministico non interattivo**: scartato in favore della skill — la trasformazione richiede giudizio (naming, traduzione, cosa considerare artefatto) più che pura meccanica.
- **Cartella "inbox" dedicata per gli export grezzi**: il path del file sorgente resta libero, nessuna nuova convenzione di collocazione imposta da questo design.

## 9. Verifica

Nessun test automatico (coerente con la convenzione del repo: `htmltest` è l'unico gate CI, qui non applicabile perché la skill non tocca `layouts/`/`assets/`). Verifica manuale:

1. Eseguire `/convert-gdoc docs/Antonino_Benedetto_Presentazione.md` come caso di prova reale: controllare che titolo, slug proposti, pulizia e traduzione risultino corretti, che il branch `post/<slug>` venga creato da `main`, e che i due file finiscano in `content/it/blog/` e `content/en/blog/` con frontmatter completo.
2. Ripetere l'invocazione sullo stesso file: verificare che la skill rilevi il conflitto (file/translationKey già esistenti) invece di sovrascrivere.
3. Provare un export con un riferimento immagine finto (es. `![alt](img.png)`): verificare che la skill si fermi con il messaggio previsto invece di procedere.
