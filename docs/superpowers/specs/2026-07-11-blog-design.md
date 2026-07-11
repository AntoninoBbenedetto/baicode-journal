# Design: baicode-journal — blog personale

Data: 2026-07-11

## Contesto

Questo repository (`baicode-journal`) è la componente "blog personale" del piano descritto in `docs/Antonino_Benedetto_Presentazione.md`: uno spazio pubblico dove ogni articolo racconta una decisione tecnica reale (problema, alternative valutate, scelta, compromessi). Il "progetto robusto" citato in quel documento — con test, ADR pesanti e CI sempre verde come dimostrazione di rigore ingegneristico — è un'iniziativa separata e **fuori scope** in questo design: qui l'obiettivo è costruire il blog stesso in modo semplice, veloce e mantenibile, senza sacrificare la pratica di documentare le decisioni prese.

Vincolo guida esplicito: "uso lo strumento migliore per le mie necessità" — le scelte tecniche seguono dal problema, non da una preferenza di stack a priori.

## 1. Stack e architettura generale

- **Generatore**: [Hugo](https://gohugo.io) — binario Go, zero dipendenze Node per il core, build molto veloce, i18n e RSS/sitemap nativi.
- **Repo**: la root di questo repository è la root del sito Hugo (`content/`, `layouts/`, `hugo.toml`, `static/`).
- **Tema**: si parte da un tema Hugo esistente, minimale e orientato a blog tecnici, personalizzato con Tailwind CSS per tipografia/colori/identità visiva. Tailwind è integrato tramite il **binario standalone** (supporto nativo di Hugo via `css.TailwindCSS`): nessuna toolchain Node, nessun `node_modules` nel progetto, coerentemente con la motivazione "zero dipendenze Node" alla base della scelta di Hugo.
- **Contenuti**: flat-file — Markdown con frontmatter, versionato in git. Nessun database, nessun CMS.
- **Hosting**: [Cloudflare Pages](https://pages.cloudflare.com), raggiungibile su un **sottodominio** del dominio personale (es. `blog.<dominio>`) tramite record CNAME verso il progetto Pages — setup che non richiede di spostare i nameserver su Cloudflare. HTTPS gestito da Cloudflare. Il sito personale/homepage dell'autore esiste già sul suo VPS, è fuori scope, e si limita a linkare il blog (e viceversa il blog linka la home).
- **Deploy**: GitHub Actions builda con Hugo e pubblica l'output su Cloudflare Pages via `wrangler pages deploy` (API token Cloudflare come secret). Niente rsync/SSH: il VPS non è nel percorso di build né di serving del blog.

Alternative valutate e scartate: Astro (validazione frontmatter a compile-time e integrazione Tailwind più immediata, ma dipendenza da toolchain Node) e Statamic (resta nello stack Laravel dell'autore e offre un pannello admin, ma richiede un runtime PHP sempre attivo invece di un output statico puro). Il ragionamento completo va formalizzato in ADR-002 (vedi sezione 4).

## 2. Struttura contenuti e i18n

- **Bilingue IT/EN** tramite il multilingual mode nativo di Hugo: `content/it/` e `content/en/`, con `defaultContentLanguage: it` in `hugo.toml` e `en` come lingua secondaria.
- Ogni articolo è una coppia di file allineati per slug/traduzione tramite il meccanismo di traduzione di Hugo. Se una traduzione manca, il sito lo gestisce esplicitamente (non un 404 silenzioso).
- **Tassonomia**: solo `tags` per ora — niente categorie separate, per non sovra-strutturare un catalogo di poche decine di articoli.
- **Pagine statiche**: una pagina "Chi sono" (bilingue), basata sui contenuti di `docs/Antonino_Benedetto_Presentazione.md`.
- **Pubblicare un articolo**: `hugo new content/it/blog/mio-articolo.md` da un archetype con frontmatter precompilato (titolo, data, tags, `draft: true`); si scrive il contenuto, si passa a `draft: false`, si fa commit e push.

## 3. Funzionalità del sito

- **RSS e sitemap**: generati nativamente da Hugo, uno per lingua, senza configurazione aggiuntiva.
- **SEO/social**: meta tag OpenGraph/Twitter Card di base forniti dal tema (title, description, immagine di copertina se presente).
- **Syntax highlighting**: Chroma, integrato in Hugo, nessun JS lato client.
- **Commenti**: assenti nella v1. Predisposti per un'integrazione futura via giscus (GitHub Discussions) — aggiunta successiva che non richiede cambi architetturali.
- **Analytics**: nessuno.
- **Collegamento al "progetto robusto"**: fuori scope qui. Nella v1 un articolo può linkare liberamente, in Markdown, a repository/commit/tag esterni, senza automazioni dedicate.

## 4. CI/CD, qualità, ADR e deploy

- **ADR per questo repo**: cartella `docs/adr/`, formato leggero (contesto → decisione → alternative scartate → conseguenze) definito in `docs/adr/template.md`, con indice e convenzioni (file `NNN-slug.md`, lingua italiana, stati proposta/accettata/superata, ADR accettate immutabili) in `docs/adr/README.md`. ADR iniziali richieste:
  - **ADR-001**: perché contenuti flat-file (Markdown in git) invece di CMS/database.
  - **ADR-002**: perché Hugo invece di Astro/Statamic come generatore.
  - **ADR-003**: perché il blog è hostato su Cloudflare Pages invece che sul VPS già di proprietà dell'autore (dove resta la homepage personale) o su GitHub Pages. Motivazione primaria: per un sito statico di contenuti, zero manutenzione ricorrente, CDN globale e preview deployment superano il vantaggio "il VPS c'è già ed è già pagato". Trade-off accettati da documentare: dipendenza da una piattaforma terza e hosting separato dalla homepage (sottodominio distinto).
  Le ADR sono documentazione versionata, non un gate di CI: non introducono processo pesante, restano coerenti con l'obiettivo "semplice e veloce", ma rendono esplicito il ragionamento dietro le scelte — in linea col messaggio di fondo del piano più ampio.
- **CI (GitHub Actions)**, su ogni push a `main`:
  1. `hugo --gc --minify` — se la build fallisce (shortcode rotto, template errato), il workflow fallisce e il deploy è bloccato.
  2. Controllo dei **soli link interni** rotti sull'output generato (es. `htmltest` configurato senza check esterni) — bloccante.
  3. Se entrambi i passi precedenti passano: `wrangler pages deploy` dell'output (`public/`) verso il progetto Cloudflare Pages (API token come secret). Il gate sui link interni resta effettivo anche pushando direttamente su `main`, perché il deploy parte dalla pipeline e non dalla Git integration di Cloudflare.
- **Link esterni**: verificati in un **workflow schedulato separato** (settimanale), non bloccante — segnala i link rotti (es. aprendo una issue) senza mai impedire un deploy. Razionale: i check su link esterni sono instabili (timeout, rate limiting, siti terzi giù) e non devono bloccare la pubblicazione di contenuti nuovi.
- Nessun test automatico o processo di review pesante oltre a questo: il livello di rigore "robusto" (test, ADR estese, analisi statica) resta riservato al progetto separato citato nel piano generale.

## Fuori scope (esplicito)

- Il sito personale/homepage sul VPS dell'autore: esiste già, non è gestito da questo repo; l'unico punto di contatto è il link reciproco tra home e blog.
- Il "progetto robusto" che il blog documenterà (altra iniziativa, altro repo/spec).
- Automazioni di collegamento tra articoli del blog e tag Git del progetto robusto.
- Commenti in v1 (rimandati), analytics, categorie/tassonomie aggiuntive oltre ai tag.
