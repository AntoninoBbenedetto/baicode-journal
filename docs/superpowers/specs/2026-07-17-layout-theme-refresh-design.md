# Design: rifinitura tipografica e presentazione lista articoli

Data: 2026-07-17

## Contesto

Il layout attuale (ADR-002: nessun tema di terze parti, CSS scritto a mano in `assets/css/main.css`) è volutamente minimale: una colonna singola, tipografia di sistema senza scala definita, lista post come `<ul>` spoglia (solo titolo, data, tag). Il sito è la componente "repository" del piano di portfolio pubblico dell'autore: il codice deve restare rigoroso, ma il layout non deve sembrare abbandonato a sé stesso.

Requisiti raccolti dall'autore:

- Migliorare **tipografia e leggibilità** (scala dei titoli, spaziatura, gerarchia) e la **presentazione di homepage e liste articoli**.
- Restare sullo **stack di font di sistema**: nessun file di font da scaricare/servire, coerente con la filosofia zero-dipendenze di ADR-002.
- **Fuori scope in questo giro**: dark mode, rifinitura responsive/mobile, nuovi contenuti in home (bio, link a GitHub/LinkedIn, evidenza sulle ADR) — la home resta solo intro + lista articoli, ma presentata meglio.
- Nessun nuovo tema di terze parti, nessuna toolchain Node (Tailwind escluso, come da ADR-002): tutto il lavoro resta dentro `assets/css/main.css` e i template esistenti in `layouts/`.

## 1. Token di tipografia e spaziatura

`assets/css/main.css` guadagna, nel blocco `:root` esistente, due nuove scale come custom property, ad affiancare quelle già presenti (`--color-*`, `--max-width`):

- **Scala tipografica**: dimensioni fisse in `rem` per i livelli usati nel sito (testo base, `h1`/titolo articolo, `h2`/titolo sezione, `h3`, meta/small). Nessun `clamp()` o media query aggiuntiva — è fuori scope il lavoro responsive, e il contenitore `--max-width: 42rem` già limita la larghezza su schermi grandi.
- **Scala di spaziatura**: 5-6 valori (`--space-1` … `--space-6`, da ~0.25rem a ~3rem) che sostituiscono i valori sparsi attuali (`1rem`, `1.5rem`, `0.5rem` ripetuti a mano in più selettori).

Titoli e blocchi esistenti (`.site-nav`, `.site-footer`, `main`, `article`) vengono aggiornati per usare le nuove variabili al posto dei valori letterali, senza cambiare la struttura HTML esistente. `h1`/`h2`/`h3` prendono dimensione e margini distinti dalla scala tipografica, per separare visivamente titolo di pagina, titolo di sezione (es. "Articoli recenti") e titolo di un singolo articolo.

## 2. Componente lista articoli

Il markup della lista post (`.post-list`, oggi un semplice `<li>` con link + `<time>` + tag) si arricchisce, restando un `<ul>`/`<li>` (nessun cambio semantico), con:

- **Riga meta** che affianca alla data il **tempo di lettura**, calcolato da Hugo (`.ReadingTime`, nativo, nessun campo frontmatter nuovo).
- **Estratto**: un paragrafo con `.Summary` (generato automaticamente da Hugo da ogni post — tronca a un numero di parole di default, o rispetta un separatore `<!--more-->` se in futuro un post lo aggiunge). Nessuna modifica ai contenuti esistenti richiesta.
- **Tag**: stile invariato rispetto a oggi (chip con bordo arrotondato).

Questo componente è condiviso da:
- `layouts/_default/list.html` (archivio `/blog/` e pagine tag) — tutti i post nello stesso stile;
- `layouts/index.html` — solo per i post **oltre il primo** (vedi sezione 3).

Nuova chiave i18n in `i18n/it.toml` e `i18n/en.toml` per il tempo di lettura (es. `readingTime`, con placeholder per il numero di minuti — niente pluralizzazione complessa: "min" non cambia forma in italiano né in inglese per i valori interi usati qui).

## 3. Home con articolo in evidenza

In `layouts/index.html`, tra i 5 post recenti mostrati oggi, il **più recente** si separa dagli altri 4:

- Renderizzato con un trattamento tipografico distinto (titolo più grande, dalla scala della sezione 1; estratto più esteso della stessa `.Summary`), ma **nessuna nuova etichetta testuale** ("in evidenza" non compare da nessuna parte) — è solo gerarchia visiva sotto il titolo di sezione "Articoli recenti" già esistente (chiave i18n `recentPosts`, invariata).
- Gli altri 4 post usano il componente lista della sezione 2, identico a quello di `/blog/`.

Nessun cambio ai contenuti o alla logica di selezione (`first 5 (where .Site.RegularPages "Section" "blog")` resta invariata): cambia solo come il primo elemento del range viene renderizzato rispetto al resto.

## 4. File toccati

Tutti file esistenti, nessun nuovo asset o partial:

- `assets/css/main.css` — token (sezione 1) + stili del componente lista (sezione 2) + stile per il post in evidenza (sezione 3).
- `layouts/index.html` — split primo post / resto del range.
- `layouts/_default/list.html` — nuovo markup card (estratto, tempo di lettura).
- `layouts/_default/single.html` — solo micro-rifiniture di gerarchia titolo/meta con le nuove variabili; nessun cambio strutturale.
- `i18n/it.toml`, `i18n/en.toml` — nuova chiave per il tempo di lettura.

`layouts/partials/nav.html`, `layouts/partials/footer.html`, `layouts/partials/head.html` e `layouts/_default/terms.html` non cambiano struttura: al più ereditano gli stili aggiornati di `main.css` (es. spaziatura via le nuove variabili), senza modifiche al markup.

## 5. Verifica

Nessun test automatico in questo repo (per convenzione esistente: `htmltest` sui link interni è l'unico gate CI). Verifica manuale:

1. `hugo server -D`: controllo visivo di home, `/blog/`, una pagina tag, un articolo singolo, in entrambe le lingue (IT/EN) — gerarchia titoli, spaziatura, estratto, tempo di lettura, tag, post in evidenza in home vs. resto della lista.
2. `hugo --gc --minify` seguito da `htmltest -c .htmltest.yml public`: conferma che il nuovo markup non introduca link interni rotti.

## Fuori scope

- Dark mode e rifinitura responsive/mobile: nessuna media query nuova in questo giro: riaggiungerli in futuro è un design a parte che riusa le stesse variabili di token introdotte qui.
- Nuovi contenuti in home (bio, link a GitHub/LinkedIn, evidenza sulle ADR): la home resta intro + lista articoli.
- Font self-hosted: scartato esplicitamente, resta lo stack di sistema.
- Layout a due colonne / sidebar tag: scartato, romperebbe la colonna singola su cui è costruito il resto del sito e tocca territorio responsive fuori scope.
