# ADR-001: Contenuti flat-file versionati in git

- **Stato**: accettata
- **Data**: 2026-07-14

## Contesto

Il blog è personale, bilingue (IT/EN), con un solo autore — tecnico, a suo agio con git e con l'editor di testo. Il catalogo atteso è di poche decine di articoli, con frequenza di pubblicazione bassa. I requisiti che pesano sulla decisione:

- **manutenzione minima**: il sito cambia solo quando si pubblica un articolo, e non deve richiedere lavoro ricorrente nel frattempo;
- **nessuna infrastruttura sempre attiva**: niente da aggiornare, proteggere o backuppare in continuazione;
- **contenuti pubblicamente verificabili**: il blog è parte di un portfolio, e la storia dei contenuti è essa stessa materiale dimostrativo.

La decisione su *dove vivono i contenuti* viene prima di qualunque scelta di strumento: condiziona hosting, workflow di pubblicazione e la scelta del generatore (oggetto di ADR-002).

## Decisione

I contenuti sono file Markdown con frontmatter, versionati in git nello stesso repository del sito. Nessun database, nessun servizio esterno.

Il perché: git fornisce gratis versioning, storia e review dei contenuti; non c'è alcun runtime da mantenere o proteggere; i file restano leggibili e portabili con qualunque toolchain presente o futura; e il repository dei contenuti è esso stesso parte verificabile del portfolio — chiunque può vedere non solo cosa è stato scritto, ma come è evoluto.

## Alternative scartate

### Blog custom Laravel + database

Il controfattuale più onesto, essendo Laravel lo stack quotidiano dell'autore: pieno controllo, nessun apprendimento richiesto. Scartato perché richiede runtime PHP e database sempre attivi — con relativi aggiornamenti, backup e superficie di sicurezza — per un sito che cambia solo al momento della pubblicazione. Sarebbe la scelta di comfort dello stack di casa, non quella che segue dal problema: esattamente il vincolo guida di questo progetto.

### CMS tradizionale (WordPress)

Il default di categoria per un blog. Il suo valore — multi-autore, editor WYSIWYG, ecosistema di plugin — risponde a esigenze che questo blog non ha. In cambio porta con sé database, aggiornamenti di sicurezza continui e contenuti intrappolati nel database invece che in file leggibili. Scartato: costo ricorrente certo, beneficio nullo per questo caso d'uso.

### Git-based CMS con UI (Decap, Sveltia)

I contenuti restano flat-file in git; si aggiunge un pannello web di editing con relativa configurazione e autenticazione. Per un singolo autore tecnico l'unico beneficio è evitare l'editor di testo — cioè il posto dove già scrive. Scartato per beneficio nullo, con una nota: è *compatibile* con il modello scelto e potrebbe essere aggiunto in futuro senza superare questa ADR.

### Statamic

CMS flat-file nello stack Laravel: i contenuti sarebbero comunque file Markdown versionati, quindi condivide il modello di storage scelto. Scartato perché per servire il sito richiede un runtime PHP/Laravel sempre attivo — application server, aggiornamenti, manutenzione — quando l'obiettivo è tenere l'infrastruttura più snella possibile: non basta eliminare il database, non serve nemmeno un runtime applicativo. Vale la stessa considerazione fatta per il blog custom: sarebbe lo stack di casa, non lo strumento che segue dal problema. (Nota di confine: Statamic riappare in ADR-002 come alternativa a Hugo — lì per la scelta del generatore, qui solo per il requisito di runtime.)

## Conseguenze

Diventa più facile:

- backup e portabilità: un clone del repository è una copia completa di sito e contenuti;
- review dei contenuti con gli stessi strumenti del codice (diff, PR);
- zero manutenzione infrastrutturale tra una pubblicazione e l'altra;
- storia editoriale pubblica e verificabile, coerente con lo scopo di portfolio.

Diventa più difficile:

- pubblicare richiede git: niente editing da mobile o da pannello web;
- qualunque funzione dinamica futura (es. commenti) dovrà venire da servizi esterni;
- il frontmatter non ha validazione a schema: la robustezza su questo fronte dipende dallo strumento scelto in ADR-002.
