# Design: baicode-journal — blog personale

Data: 2026-07-11

## Contesto

Questo repository (`baicode-journal`) è la componente "blog personale" del piano descritto in `docs/Antonino_Benedetto_Presentazione.md`: uno spazio pubblico dove ogni articolo racconta una decisione tecnica reale (problema, alternative valutate, scelta, compromessi). Il "progetto robusto" citato in quel documento — con test, ADR pesanti e CI sempre verde come dimostrazione di rigore ingegneristico — è un'iniziativa separata e **fuori scope** in questo design: qui l'obiettivo è costruire il blog stesso in modo semplice, veloce e mantenibile, senza sacrificare la pratica di documentare le decisioni prese.

Vincolo guida esplicito: "uso lo strumento migliore per le mie necessità" — le scelte tecniche seguono dal problema, non da una preferenza di stack a priori.

## 1. Stack e architettura generale

- **Generatore**: [Hugo](https://gohugo.io) — binario Go, zero dipendenze Node per il core, build molto veloce, i18n e RSS/sitemap nativi.
- **Repo**: la root di questo repository è la root del sito Hugo (`content/`, `layouts/`, `hugo.toml`, `static/`).
- **Tema**: si parte da un tema Hugo esistente, minimale e orientato a blog tecnici, personalizzato con Tailwind CSS per tipografia/colori/identità visiva (via Hugo Pipes + PostCSS).
- **Contenuti**: flat-file — Markdown con frontmatter, versionato in git. Nessun database, nessun CMS.
- **Hosting**: VPS di proprietà dell'autore, servito da Caddy (HTTPS automatico via Let's Encrypt).
- **Deploy**: GitHub Actions builda con Hugo ed esegue `rsync` dei file statici verso la cartella servita da Caddy sul VPS (via SSH, chiave privata come secret).

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

- **ADR per questo repo**: cartella `docs/adr/`, formato leggero (contesto → decisione → alternative scartate → conseguenze). ADR iniziali richieste:
  - **ADR-001**: perché contenuti flat-file (Markdown in git) invece di CMS/database.
  - **ADR-002**: perché Hugo invece di Astro/Statamic come generatore.
  Le ADR sono documentazione versionata, non un gate di CI: non introducono processo pesante, restano coerenti con l'obiettivo "semplice e veloce", ma rendono esplicito il ragionamento dietro le scelte — in linea col messaggio di fondo del piano più ampio.
- **CI (GitHub Actions)**, su ogni push a `main`:
  1. `hugo --gc --minify` — se la build fallisce (shortcode rotto, template errato), il workflow fallisce e il deploy è bloccato.
  2. Controllo link interni/esterni rotti sull'output generato (es. `htmltest`).
  3. Se entrambi i passi precedenti passano: `rsync` dell'output (`public/`) verso la cartella servita da Caddy sul VPS via SSH.
- Nessun test automatico o processo di review pesante oltre a questo: il livello di rigore "robusto" (test, ADR estese, analisi statica) resta riservato al progetto separato citato nel piano generale.
- **Caddy** sul VPS: HTTPS automatico via Let's Encrypt, configurazione minima (`Caddyfile` con dominio custom → root della cartella statica).

## Fuori scope (esplicito)

- Il "progetto robusto" che il blog documenterà (altra iniziativa, altro repo/spec).
- Automazioni di collegamento tra articoli del blog e tag Git del progetto robusto.
- Commenti in v1 (rimandati), analytics, categorie/tassonomie aggiuntive oltre ai tag.
