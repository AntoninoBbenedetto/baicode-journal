# ADR-003: Hosting su Cloudflare Pages

- **Stato**: accettata
- **Data**: 2026-07-14

## Contesto

Il sito è output statico puro ([ADR-001](001-contenuti-flat-file.md), [ADR-002](002-hugo-come-generatore.md)): servirlo non richiede alcun runtime. L'autore ha già un VPS pagato che ospita la homepage personale — il che rende la domanda non banale: perché *non* usare quello che c'è già?

I requisiti che pesano sulla scelta:

- **zero manutenzione ricorrente dell'hosting**: coerente con ADR-001 e ADR-002, nessun lavoro tra una pubblicazione e l'altra;
- **HTTPS gestito**, senza rinnovi di certificati in carico all'autore;
- **blog su un sottodominio del dominio personale** (es. `blog.<dominio>`), senza spostare i nameserver del dominio.

## Decisione

Il blog è hostato su [Cloudflare Pages](https://pages.cloudflare.com), raggiungibile su un sottodominio del dominio personale tramite record CNAME verso il progetto Pages — setup che non richiede di spostare i nameserver. HTTPS è gestito da Cloudflare.

Il deploy parte da GitHub Actions con `wrangler pages deploy` (API token Cloudflare come secret del repo), **non** dalla Git integration di Cloudflare: così i gate di CI — build Hugo e check dei link interni — restano effettivi anche pushando direttamente su `main`, perché è la pipeline a pubblicare, non Cloudflare a osservare il repo.

## Alternative scartate

### Il VPS già di proprietà

L'argomento forte è "c'è già ed è già pagato": costo marginale zero. Scartato perché il costo vero non è il canone ma la manutenzione: configurazione e rinnovo TLS, hardening del web server, aggiornamenti di sistema — lavoro ricorrente per servire file statici che una CDN serve meglio (edge globale, nessun single point of failure). Accoppierebbe inoltre la disponibilità del blog a quella della macchina personale. Il VPS resta dov'è, a servire la homepage: i due siti si linkano a vicenda e nessuno dipende dall'altro.

### GitHub Pages

Gratuito e nello stesso ecosistema del repository. Scartato per i limiti sul controllo: nessun preview deployment per branch, meno flessibilità su header e redirect, e la pubblicazione tramite le action ufficiali spinge verso il percorso standard invece del gate CI custom voluto qui. Cloudflare Pages offre le stesse cose gratuitamente, più le preview per branch.

## Conseguenze

Diventa più facile:

- zero manutenzione dell'hosting: HTTPS, CDN globale e scalabilità inclusi;
- preview deployment per ogni branch, utile per rivedere un articolo pubblicato ma non ancora su `main`;
- il VPS resta intonso: nessun nuovo servizio da mantenere sulla macchina personale.

Diventa più difficile:

- dipendenza da una piattaforma terza — lock-in mitigato dal fatto che l'output è una cartella `public/` statica: migrare significa solo cambiare dove la si carica;
- la presenza personale vive su due infrastrutture separate (homepage sul VPS, blog su Cloudflare), collegate solo da link reciproci;
- va gestito un API token Cloudflare come secret del repository, con relativa rotazione.
