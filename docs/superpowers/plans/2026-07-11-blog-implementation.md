# Blog baicode-journal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the baicode-journal blog described in `docs/superpowers/specs/2026-07-11-blog-design.md`: a bilingual (IT/EN) Hugo static blog, custom layout, hand-written CSS, ADRs documenting the technical decisions, and a CI pipeline that builds, checks internal links, and deploys to Cloudflare Pages.

**Architecture:** Hugo (standard, non-extended binary) generates the site from flat-file Markdown content under `content/it/` and `content/en/`, rendered through custom Go templates in `layouts/` (no third-party theme). Styling is hand-written CSS in `assets/css/`, minified by Hugo's own build pipeline — no CSS framework, no Node/npm anywhere in the project. GitHub Actions builds the site, runs `htmltest` against internal links (blocking), and deploys `public/` to Cloudflare Pages via `wrangler pages deploy`. A second, scheduled workflow checks external links non-blockingly. Three ADRs in `docs/adr/` document why flat-file content, why Hugo, and why Cloudflare Pages.

**Tech Stack:** Hugo v0.164.0 (standard binary), Go templates, plain CSS, htmltest, GitHub Actions, Cloudflare Pages (`wrangler pages deploy`).

## Global Constraints

- No Node.js/npm dependency anywhere in this project (core decision behind choosing Hugo — see ADR-002). Do not add a `package.json`.
- No CSS framework. Styling is hand-written CSS in `assets/css/main.css`.
- No third-party Hugo theme. All layouts live in this repo under `layouts/`.
- No automated test suite is being added to this repository — the spec explicitly reserves that level of rigor for a separate project. Each task's "test" step is a build + assertion on the generated output (`hugo build` + `grep`/`test` on files in `public/`), run manually during implementation, not committed as a persisted test suite.
- Hugo standard (non-extended) binary is sufficient — nothing in this plan requires Sass/SCSS.
- All content is bilingual IT/EN unless explicitly noted (spec section 2).
- `baseURL` in `hugo.toml` and `params.homeURL` use placeholder domains (`https://blog.example.com/`, `https://www.example.com/`); update them to the real domains before the first production deploy (see Task 8, Cloudflare Pages setup).

---

## Task 1: Repo scaffold and Hugo configuration

**Files:**
- Create: `.gitignore`
- Create: `hugo.toml`

**Interfaces:**
- Produces: a working Hugo config with i18n (`it` default, `en` secondary), `tags` taxonomy, and `params.homeURL`/`params.description` site params consumed by later layout tasks (Task 3+).

- [ ] **Step 1: Install the Hugo standard binary locally**

```bash
mkdir -p /tmp/hugo-install && cd /tmp/hugo-install
curl -sL https://github.com/gohugoio/hugo/releases/download/v0.164.0/hugo_0.164.0_linux-amd64.tar.gz -o hugo.tar.gz
tar -xzf hugo.tar.gz hugo
mkdir -p "$HOME/.local/bin"
mv hugo "$HOME/.local/bin/hugo"
cd - && rm -rf /tmp/hugo-install
export PATH="$HOME/.local/bin:$PATH"
hugo version
```

Expected: prints `hugo v0.164.0` (standard, not extended). If `$HOME/.local/bin` isn't already on `PATH`, add `export PATH="$HOME/.local/bin:$PATH"` to `~/.bashrc` or `~/.profile`.

- [ ] **Step 2: Write `.gitignore`**

```gitignore
/public/
/resources/_gen/
.hugo_build.lock
/tmp/
```

- [ ] **Step 3: Write `hugo.toml`**

```toml
baseURL = "https://blog.example.com/"
languageCode = "it-it"
defaultContentLanguage = "it"
defaultContentLanguageInSubdir = false
title = "baicode journal"
enableRobotsTXT = true

[params]
  homeURL = "https://www.example.com/"
  description = "Decisioni tecniche reali: problema, alternative, scelta, compromessi."

[taxonomies]
  tag = "tags"

[languages]
  [languages.it]
    languageName = "Italiano"
    languageCode = "it-IT"
    weight = 1
    title = "baicode journal"
  [languages.en]
    languageName = "English"
    languageCode = "en-US"
    weight = 2
    title = "baicode journal"

[markup]
  [markup.highlight]
    noClasses = false
    codeFences = true
    guessSyntax = true

[outputs]
  home = ["HTML", "RSS"]
  section = ["HTML", "RSS"]
```

- [ ] **Step 4: Verify the empty site builds**

```bash
hugo --gc --minify
echo "exit: $?"
test -d public && echo "public/ created: OK"
```

Expected: `exit: 0` and `public/ created: OK`. The output will be nearly empty (no content, no layouts yet) — that's expected at this stage.

- [ ] **Step 5: Commit**

```bash
git add .gitignore hugo.toml
git commit -m "Scaffold Hugo site config: bilingual IT/EN, tags taxonomy, RSS outputs"
```

---

## Task 2: Content structure and archetype

**Files:**
- Create: `content/it/_index.md`
- Create: `content/en/_index.md`
- Create: `content/it/blog/_index.md`
- Create: `content/en/blog/_index.md`
- Create: `archetypes/blog.md`

**Interfaces:**
- Consumes: `hugo.toml` from Task 1 (`defaultContentLanguage`, `languages`).
- Produces: home page content (`.Title`, `.Content` on the home `Page`) and blog section content, consumed by `layouts/index.html` and `layouts/_default/list.html` in Task 3/4. Archetype frontmatter fields `title`, `date`, `draft`, `translationKey`, `tags` are consumed by every future blog post.

- [ ] **Step 1: Write home page content**

`content/it/_index.md`:
```markdown
---
title: "baicode journal"
---

Uno spazio dove ogni articolo racconta una decisione tecnica reale: il problema, le alternative valutate, la scelta, i compromessi accettati.
```

`content/en/_index.md`:
```markdown
---
title: "baicode journal"
---

A space where every post walks through one real technical decision: the problem, the alternatives considered, the choice made, the trade-offs accepted.
```

- [ ] **Step 2: Write blog section content**

`content/it/blog/_index.md`:
```markdown
---
title: "Blog"
---
```

`content/en/blog/_index.md`:
```markdown
---
title: "Blog"
---
```

- [ ] **Step 3: Write the post archetype**

`archetypes/blog.md`:
```markdown
---
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
date: {{ .Date }}
draft: true
translationKey: "{{ .File.ContentBaseName }}"
tags: []
---
```

Note for the "publish a post" workflow (documented in Task 8's README): when creating the IT/EN pair of a post, the two files get different slugs (e.g. `benvenuto.md` / `welcome.md`) and therefore different default `translationKey` values from the archetype. Align `translationKey` manually to the same string in both files so Hugo recognizes them as translations of each other.

- [ ] **Step 4: Verify content and archetype**

```bash
hugo --gc --minify
echo "build exit: $?"
hugo new content/it/blog/prova-archetype.md
grep -q 'draft: true' content/it/blog/prova-archetype.md && echo "archetype OK"
rm content/it/blog/prova-archetype.md
```

Expected: `build exit: 0`, `archetype OK` printed, and the scratch file removed before committing.

- [ ] **Step 5: Commit**

```bash
git add content archetypes
git commit -m "Add bilingual home/blog section content and post archetype"
```

---

## Task 3: Base layout, navigation, and hand-written CSS

**Files:**
- Create: `layouts/_default/baseof.html`
- Create: `layouts/index.html`
- Create: `layouts/partials/head.html`
- Create: `layouts/partials/nav.html`
- Create: `layouts/partials/footer.html`
- Create: `assets/css/main.css`
- Create: `i18n/it.toml`
- Create: `i18n/en.toml`

**Interfaces:**
- Consumes: `content/it/_index.md` / `content/en/_index.md` (Task 2) for `.Title`/`.Content` on the home page; `hugo.toml` params `homeURL`, `description`.
- Produces: the `main` template block (defined in `baseof.html`, filled by `index.html` here and by `list.html`/`single.html`/`terms.html` in Task 4); i18n keys `navBlog`, `navAbout`, `recentPosts` consumed here, `allTags`, `availableIn`, `notTranslated` consumed by Task 4.

- [ ] **Step 1: Write the i18n string tables**

`i18n/it.toml`:
```toml
[navBlog]
other = "Blog"

[navAbout]
other = "Chi sono"

[recentPosts]
other = "Articoli recenti"

[allTags]
other = "Tutti i tag"

[availableIn]
other = "Disponibile anche in:"

[notTranslated]
other = "Questo articolo non è ancora disponibile in altre lingue."
```

`i18n/en.toml`:
```toml
[navBlog]
other = "Blog"

[navAbout]
other = "About"

[recentPosts]
other = "Recent posts"

[allTags]
other = "All tags"

[availableIn]
other = "Also available in:"

[notTranslated]
other = "This post is not yet available in other languages."
```

- [ ] **Step 2: Write `layouts/partials/nav.html`**

```gotemplate
<nav class="site-nav">
  <a class="brand" href="{{ "/" | relLangURL }}">{{ .Site.Title }}</a>
  <a href="{{ "/blog/" | relLangURL }}">{{ i18n "navBlog" }}</a>
  <a href="{{ .Site.Params.homeURL }}">{{ i18n "navAbout" }}</a>
  {{ if .Translations }}
    <div class="lang-switch">
      {{ range .Translations }}
        <a href="{{ .RelPermalink }}">{{ .Language.LanguageName }}</a>
      {{ end }}
    </div>
  {{ end }}
</nav>
```

- [ ] **Step 3: Write `layouts/partials/footer.html`**

```gotemplate
<footer class="site-footer">
  {{ with .OutputFormats.Get "RSS" }}
    <a href="{{ .Permalink | safeURL }}">RSS</a>
  {{ end }}
  <span>&copy; {{ now.Year }} Antonino Benedetto</span>
</footer>
```

- [ ] **Step 4: Write `layouts/partials/head.html`**

```gotemplate
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} · {{ .Site.Title }}{{ end }}</title>
<meta name="description" content="{{ if .Description }}{{ .Description }}{{ else }}{{ .Site.Params.description }}{{ end }}">
{{ with .OutputFormats.Get "RSS" }}
  <link rel="{{ .Rel }}" type="{{ .MediaType.Type }}" href="{{ .Permalink | safeURL }}" title="{{ $.Site.Title }}">
{{ end }}
{{ range .Translations }}
  <link rel="alternate" hreflang="{{ .Language.Lang }}" href="{{ .Permalink }}">
{{ end }}
<meta property="og:title" content="{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }}{{ end }}">
<meta property="og:description" content="{{ if .Description }}{{ .Description }}{{ else }}{{ .Site.Params.description }}{{ end }}">
<meta property="og:type" content="{{ if .IsPage }}article{{ else }}website{{ end }}">
<meta property="og:url" content="{{ .Permalink }}">
<meta name="twitter:card" content="summary">
{{ with resources.Get "css/main.css" }}
  {{ $css := . | resources.Fingerprint "sha256" }}
  <link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">
{{ end }}
```

- [ ] **Step 5: Write `layouts/_default/baseof.html`**

```gotemplate
<!DOCTYPE html>
<html lang="{{ .Site.Language.LanguageCode }}">
<head>
  {{ partial "head.html" . }}
</head>
<body>
  {{ partial "nav.html" . }}
  <main>
    {{ block "main" . }}{{ end }}
  </main>
  {{ partial "footer.html" . }}
</body>
</html>
```

- [ ] **Step 6: Write `layouts/index.html`**

```gotemplate
{{ define "main" }}
  <section class="home-intro">
    <h1>{{ .Title }}</h1>
    {{ .Content }}
  </section>
  <section class="recent-posts">
    <h2>{{ i18n "recentPosts" }}</h2>
    <ul class="post-list">
      {{ range first 5 (where .Site.RegularPages "Section" "blog") }}
        <li>
          <a href="{{ .RelPermalink }}">{{ .Title }}</a>
          <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "2 January 2006" }}</time>
        </li>
      {{ end }}
    </ul>
  </section>
{{ end }}
```

- [ ] **Step 7: Write `assets/css/main.css`**

```css
:root {
  --color-bg: #ffffff;
  --color-fg: #1a1a1a;
  --color-muted: #6b6b6b;
  --color-accent: #1d4ed8;
  --max-width: 42rem;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: var(--color-bg);
  color: var(--color-fg);
  line-height: 1.6;
}

main {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 1.5rem;
}

.site-nav {
  display: flex;
  gap: 1rem;
  align-items: center;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e5e5;
}

.site-nav .brand {
  font-weight: 700;
  margin-right: auto;
  text-decoration: none;
  color: var(--color-fg);
}

.site-nav a {
  color: var(--color-fg);
  text-decoration: none;
}

.site-nav a:hover {
  color: var(--color-accent);
}

.lang-switch {
  display: flex;
  gap: 0.5rem;
}

a {
  color: var(--color-accent);
}

.post-list {
  list-style: none;
  padding: 0;
}

.post-list li {
  margin-bottom: 1rem;
}

.post-list time {
  display: block;
  color: var(--color-muted);
  font-size: 0.875rem;
}

.tags {
  margin-top: 0.5rem;
}

.tag {
  display: inline-block;
  font-size: 0.8rem;
  padding: 0.1rem 0.5rem;
  border: 1px solid #ddd;
  border-radius: 999px;
  margin-right: 0.25rem;
  text-decoration: none;
}

.not-translated {
  color: var(--color-muted);
  font-style: italic;
}

.site-footer {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 1.5rem;
  border-top: 1px solid #e5e5e5;
  color: var(--color-muted);
  display: flex;
  justify-content: space-between;
}

pre {
  padding: 1rem;
  overflow-x: auto;
  border-radius: 0.375rem;
}
```

- [ ] **Step 8: Verify the home page renders**

```bash
hugo --gc --minify
echo "build exit: $?"
grep -q 'baicode journal' public/it/index.html && echo "IT home title OK"
grep -q 'baicode journal' public/en/index.html && echo "EN home title OK"
grep -q 'href="/en/"' public/it/index.html && echo "IT->EN lang switch link OK"
grep -q 'stylesheet' public/it/index.html && echo "CSS linked OK"
test -f public/sitemap.xml && echo "sitemap.xml OK"
```

Expected: `build exit: 0` and all five `OK` lines printed.

- [ ] **Step 9: Commit**

```bash
git add layouts assets i18n
git commit -m "Add base layout, nav, footer, home page, and hand-written CSS"
```

---

## Task 4: Blog list/single/tag templates, Chroma highlighting, and first post

**Files:**
- Create: `layouts/_default/list.html`
- Create: `layouts/_default/single.html`
- Create: `layouts/_default/terms.html`
- Create: `assets/css/chroma.css`
- Create: `content/it/blog/benvenuto.md`
- Create: `content/en/blog/welcome.md`
- Modify: `layouts/partials/head.html:19` (add chroma.css link after the closing `{{ end }}` of the main.css block)

**Interfaces:**
- Consumes: `main` block from `baseof.html` (Task 3); i18n keys `allTags`, `availableIn`, `notTranslated` (defined in Task 3).
- Produces: nothing consumed by later tasks — this is the last layout task.

- [ ] **Step 1: Write `layouts/_default/list.html`** (used for the blog section list and for each tag's term page)

```gotemplate
{{ define "main" }}
  <h1>{{ .Title }}</h1>
  <ul class="post-list">
    {{ range .Pages }}
      <li>
        <a href="{{ .RelPermalink }}">{{ .Title }}</a>
        <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "2 January 2006" }}</time>
        {{ if .Params.tags }}
          <span class="tags">
            {{ range .Params.tags }}<a href="{{ "/tags/" | relLangURL }}{{ . | urlize }}/" class="tag">{{ . }}</a>{{ end }}
          </span>
        {{ end }}
      </li>
    {{ end }}
  </ul>
{{ end }}
```

- [ ] **Step 2: Write `layouts/_default/terms.html`** (the `/tags/` index listing every tag)

```gotemplate
{{ define "main" }}
  <h1>{{ i18n "allTags" }}</h1>
  <ul class="tag-list">
    {{ range .Data.Terms.Alphabetical }}
      <li><a href="{{ .Page.RelPermalink }}">{{ .Page.Title }}</a> ({{ .Count }})</li>
    {{ end }}
  </ul>
{{ end }}
```

- [ ] **Step 3: Write `layouts/_default/single.html`**

```gotemplate
{{ define "main" }}
  <article>
    <h1>{{ .Title }}</h1>
    <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "2 January 2006" }}</time>
    {{ if .Params.tags }}
      <div class="tags">
        {{ range .Params.tags }}<a href="{{ "/tags/" | relLangURL }}{{ . | urlize }}/" class="tag">{{ . }}</a>{{ end }}
      </div>
    {{ end }}
    {{ .Content }}
  </article>
  <aside class="translations">
    {{ if .IsTranslated }}
      <p>{{ i18n "availableIn" }}
        {{ range .Translations }}
          <a href="{{ .RelPermalink }}">{{ .Language.LanguageName }}</a>
        {{ end }}
      </p>
    {{ else }}
      <p class="not-translated">{{ i18n "notTranslated" }}</p>
    {{ end }}
  </aside>
{{ end }}
```

- [ ] **Step 4: Generate the Chroma stylesheet**

```bash
hugo gen chromastyles --style=monokai > assets/css/chroma.css
head -3 assets/css/chroma.css
```

Expected: prints CSS rules starting with something like `/* Background */` or a `.bg {` block. This file is machine-generated by the command above — do not hand-edit it; regenerate with the same command if the highlight style needs to change.

- [ ] **Step 5: Link `chroma.css` in `layouts/partials/head.html`**

Add immediately after the existing `main.css` `{{ with resources.Get "css/main.css" }}...{{ end }}` block:

```gotemplate
{{ with resources.Get "css/chroma.css" }}
  {{ $chroma := . | resources.Fingerprint "sha256" }}
  <link rel="stylesheet" href="{{ $chroma.RelPermalink }}" integrity="{{ $chroma.Data.Integrity }}">
{{ end }}
```

- [ ] **Step 6: Write the first post pair (draft, doubles as pipeline verification and a real seed post)**

`content/it/blog/benvenuto.md`:
```markdown
---
title: "Benvenuto su baicode journal"
date: 2026-07-11
draft: true
translationKey: "post-welcome"
tags: ["meta"]
---

Questo blog nasce per rendere pubblico un modo di ragionare, non un elenco di tecnologie. Ogni articolo racconterà una decisione tecnica reale: il problema, le alternative valutate, la scelta fatta, i compromessi accettati.

Il primo esempio, piccolo e concreto — l'intera pipeline di questo sito è generata da un singolo binario:

```bash
hugo --gc --minify
```

Nessun database, nessuna dipendenza Node per il core: il contenuto è testo versionato in git, come il codice di cui parla.
```

`content/en/blog/welcome.md`:
```markdown
---
title: "Welcome to baicode journal"
date: 2026-07-11
draft: true
translationKey: "post-welcome"
tags: ["meta"]
---

This blog exists to make a way of reasoning public, not a list of technologies. Every post will walk through one real technical decision: the problem, the alternatives considered, the choice made, the trade-offs accepted.

A small, concrete first example — this entire site is generated by a single binary:

```bash
hugo --gc --minify
```

No database, no Node dependency for the core: content is text versioned in git, just like the code it talks about.
```

- [ ] **Step 7: Verify rendering, tags, RSS, and Chroma with drafts included**

```bash
hugo --gc --minify --buildDrafts --destination /tmp/hugo-draft-check
echo "build exit: $?"
grep -q 'Benvenuto su baicode journal' /tmp/hugo-draft-check/it/blog/benvenuto/index.html && echo "IT post renders OK"
grep -q 'chroma' /tmp/hugo-draft-check/it/blog/benvenuto/index.html && echo "Chroma classes present OK"
grep -q 'meta' /tmp/hugo-draft-check/it/blog/benvenuto/index.html && echo "tag rendered OK"
grep -q 'Benvenuto su baicode journal' /tmp/hugo-draft-check/it/index.xml && echo "post in RSS OK"
grep -q 'Also available in' /tmp/hugo-draft-check/en/blog/welcome/index.html && echo "translation note OK"
rm -rf /tmp/hugo-draft-check
```

Expected: `build exit: 0` and all five `OK` lines printed.

- [ ] **Step 8: Verify drafts are excluded from the production build**

```bash
hugo --gc --minify
test -f public/it/blog/benvenuto/index.html && echo "FAIL: draft leaked into production build" || echo "OK: draft excluded from production build"
```

Expected: `OK: draft excluded from production build` — confirms the CI build command (`hugo --gc --minify`, no `--buildDrafts`) never publishes an unfinished post by accident.

- [ ] **Step 9: Commit**

```bash
git add layouts assets content
git commit -m "Add blog list/single/tag templates, Chroma highlighting, and first draft post"
```

---

## Task 5: ADRs

**Files:**
- Create: `docs/adr/001-contenuti-flat-file.md`
- Create: `docs/adr/002-hugo-come-generatore.md`
- Create: `docs/adr/003-hosting-cloudflare-pages.md`
- Modify: `docs/adr/README.md` (populate the index table)

**Interfaces:**
- Consumes: format from `docs/adr/template.md` (already committed).
- Produces: nothing consumed by other tasks — documentation only.

- [ ] **Step 1: Write ADR-001**

`docs/adr/001-contenuti-flat-file.md`:
```markdown
# ADR-001: Contenuti flat-file invece di CMS/database

- **Stato**: accettata
- **Data**: 2026-07-11

## Contesto

Il blog ospita un numero contenuto di articoli tecnici, pubblicati da un singolo autore, senza necessità di un pannello multi-utente, di un workflow editoriale complesso o di contenuti generati a runtime. Va scelto dove e come persistere i contenuti: un CMS con database (es. WordPress) oppure file di testo versionati insieme al codice del sito.

## Decisione

I contenuti sono file Markdown con frontmatter, versionati in git nello stesso repository del sito (`content/it/`, `content/en/`). Nessun database, nessun CMS, nessun pannello di amministrazione.

## Alternative scartate

### CMS con database (es. WordPress)

Offre un'interfaccia di editing e gestione utenti più ricca, ma introduce un runtime da mantenere e aggiornare per sicurezza, un database da backuppare separatamente dal codice, e disaccoppia i contenuti dalla cronologia Git del progetto — mentre uno degli obiettivi del blog è collegare articoli a tag/commit precisi del codice di cui parlano.

### Statamic in modalità database

Resterebbe nello stack Laravel già noto all'autore e offre un pannello admin, ma richiede comunque un runtime PHP sempre attivo per servire le pagine, mentre l'obiettivo qui è un output statico puro, deployabile su CDN.

## Conseguenze

- Ogni articolo è tracciato in git: la cronologia delle modifiche a un post è la cronologia del file stesso, nessun sistema di versioning separato.
- Pubblicare un articolo è un commit; niente backup di database, niente credenziali di CMS da proteggere.
- Editing e bozze passano da un editor di testo e da `draft: true` nel frontmatter, non da un'interfaccia web: coerente con un autore singolo, meno comodo se in futuro si aggiungessero altri autori.
- Nessuna ricerca full-text lato server: se servisse in futuro, andrebbe aggiunta come funzionalità client-side (fuori scope qui).
```

- [ ] **Step 2: Write ADR-002**

`docs/adr/002-hugo-come-generatore.md`:
```markdown
# ADR-002: Hugo come generatore di sito statico

- **Stato**: accettata
- **Data**: 2026-07-11

## Contesto

Serve un generatore di siti statici per costruire il blog: build veloce, supporto nativo a contenuti multilingue (IT/EN), RSS e sitemap automatici, senza legare il progetto a una toolchain Node se non strettamente necessario.

## Decisione

Il sito è generato con Hugo (binario Go, edizione standard). Zero dipendenze Node per il core del sito; build in millisecondi anche a repository cresciuto; i18n, RSS e sitemap nativi, senza plugin.

## Alternative scartate

### Astro

Validazione del frontmatter a compile-time, ma il core stesso di Astro richiede una toolchain Node (npm/pnpm, `node_modules`, lockfile) per ogni build, anche per un sito di solo contenuto senza interattività client-side.

### Statamic

Resta nello stack Laravel già noto all'autore e offre un pannello admin (scartato comunque in [ADR-001](001-contenuti-flat-file.md) per la scelta flat-file), ma richiede un runtime PHP sempre attivo invece di un output statico puro deployabile su CDN.

## Conseguenze

- Zero Node per il core: build riproducibile con un solo binario, nessun `node_modules`, nessun lockfile da aggiornare per vulnerabilità.
- Nessun tema di terze parti: molti temi Hugo pubblicati bundlano una propria toolchain Node/PostCSS per lo styling, il che avrebbe reintrodotto Node dalla finestra dopo averlo escluso dalla porta — il layout è quindi custom, scritto direttamente in questo repo.
- Styling con CSS scritto a mano invece di un framework, minificato dalla pipeline nativa di Hugo: nessuna dipendenza aggiuntiva, edizione Hugo standard (non extended) sufficiente.
- Nessuna validazione di frontmatter a compile-time nativa (a differenza di Astro): un frontmatter malformato produce un errore di build Hugo generico, non un messaggio mirato sul campo mancante. Accettabile per un singolo autore consapevole del proprio schema.
```

- [ ] **Step 3: Write ADR-003**

`docs/adr/003-hosting-cloudflare-pages.md`:
```markdown
# ADR-003: Hosting del blog su Cloudflare Pages

- **Stato**: accettata
- **Data**: 2026-07-11

## Contesto

Il blog, generato come sito statico, deve essere pubblicato e servito in produzione. L'autore possiede già un VPS, dove gira la sua homepage personale (fuori scope di questo repository), e potrebbe servire anche il blog da lì; in alternativa esistono piattaforme di hosting per siti statici gestite da terzi.

## Decisione

Il blog è ospitato su Cloudflare Pages, raggiungibile su un sottodominio del dominio personale (es. `blog.<dominio>`) tramite record CNAME, senza spostare i nameserver del dominio su Cloudflare.

## Alternative scartate

### VPS proprio

Costo marginale zero, essendo già pagato per la homepage personale, e pieno controllo della configurazione. Ma per un sito puramente statico introduce superficie di manutenzione ricorrente (aggiornamenti di sistema, rotazione di una chiave SSH nei secret di CI) e un single point of failure: se il VPS ha un problema, cadono insieme homepage e blog.

### GitHub Pages

Anch'essa gratuita e a manutenzione zero, ma con una CDN meno estesa di quella di Cloudflare e opzioni di redirect/header custom più limitate.

## Conseguenze

- Il deploy passa da GitHub Actions con `wrangler pages deploy` (API token Cloudflare come secret) invece di `rsync`/SSH verso il VPS: il VPS resta completamente fuori dal percorso di build e serving del blog.
- Homepage (VPS) e blog (Cloudflare Pages) vivono su hosting distinti: restano collegati solo da link reciproci, non da configurazione condivisa — un problema sull'uno non si propaga all'altro.
- Dipendenza aggiuntiva da una piattaforma terza (Cloudflare) per la disponibilità del blog.
```

- [ ] **Step 4: Populate the ADR index**

Replace the empty table in `docs/adr/README.md`:

```markdown
## Indice

| N | Titolo | Stato | Data |
|---|--------|-------|------|
| [001](001-contenuti-flat-file.md) | Contenuti flat-file invece di CMS/database | accettata | 2026-07-11 |
| [002](002-hugo-come-generatore.md) | Hugo come generatore di sito statico | accettata | 2026-07-11 |
| [003](003-hosting-cloudflare-pages.md) | Hosting del blog su Cloudflare Pages | accettata | 2026-07-11 |
```

- [ ] **Step 5: Verify links resolve**

```bash
grep -q '001-contenuti-flat-file.md' docs/adr/README.md && echo "index links OK"
grep -q 'ADR-001' docs/adr/002-hugo-come-generatore.md && echo "cross-reference OK"
```

Expected: both `OK` lines printed.

- [ ] **Step 6: Commit**

```bash
git add docs/adr
git commit -m "Write ADR-001, ADR-002, ADR-003 and populate the ADR index"
```

---

## Task 6: CI — build, internal link check, deploy

**Files:**
- Create: `.htmltest.yml`
- Create: `.github/workflows/deploy.yml`

**Interfaces:**
- Consumes: `hugo --gc --minify` output in `public/` (all prior tasks).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write `.htmltest.yml`**

```yaml
DirectoryPath: "public"
CheckExternal: false
CheckInternal: true
CheckInternalHash: true
```

- [ ] **Step 2: Verify htmltest runs locally against the internal-only config**

```bash
curl https://htmltest.wjdp.uk | bash -s -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
hugo --gc --minify
htmltest -c .htmltest.yml public
echo "htmltest exit: $?"
```

Expected: `htmltest exit: 0` — no broken internal links across home, blog list, tag pages, and the (excluded, since draft) post pages.

- [ ] **Step 3: Write `.github/workflows/deploy.yml`**

```yaml
name: Build and deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Hugo
        run: |
          curl -sL https://github.com/gohugoio/hugo/releases/download/v0.164.0/hugo_0.164.0_linux-amd64.tar.gz -o hugo.tar.gz
          tar -xzf hugo.tar.gz hugo
          sudo mv hugo /usr/local/bin/hugo
          hugo version

      - name: Build site
        run: hugo --gc --minify

      - name: Install htmltest
        run: curl https://htmltest.wjdp.uk | sudo bash -s -- -b /usr/local/bin

      - name: Check internal links
        run: htmltest -c .htmltest.yml public

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy public --project-name=baicode-journal
```

- [ ] **Step 4: Verify workflow YAML is well-formed**

```bash
python3 -c "import yaml, sys; yaml.safe_load(open('.github/workflows/deploy.yml')); print('YAML OK')"
```

Expected: `YAML OK`. (This checks syntax only — the workflow itself can't run end-to-end until `CLOUDFLARE_API_TOKEN`/`CLOUDFLARE_ACCOUNT_ID` secrets and the Cloudflare Pages project exist; see Task 8's one-time setup checklist.)

- [ ] **Step 5: Commit**

```bash
git add .htmltest.yml .github/workflows/deploy.yml
git commit -m "Add CI workflow: build, internal link check, Cloudflare Pages deploy"
```

---

## Task 7: CI — scheduled external link check

**Files:**
- Create: `.htmltest.external.yml`
- Create: `.github/workflows/link-check-external.yml`

**Interfaces:**
- Consumes: `hugo --gc --minify` output in `public/` (all prior tasks).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write `.htmltest.external.yml`**

```yaml
DirectoryPath: "public"
CheckExternal: true
CheckInternal: false
IgnoreEmptyHref: true
```

- [ ] **Step 2: Write `.github/workflows/link-check-external.yml`**

```yaml
name: External link check

on:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:

jobs:
  external-link-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Hugo
        run: |
          curl -sL https://github.com/gohugoio/hugo/releases/download/v0.164.0/hugo_0.164.0_linux-amd64.tar.gz -o hugo.tar.gz
          tar -xzf hugo.tar.gz hugo
          sudo mv hugo /usr/local/bin/hugo

      - name: Build site
        run: hugo --gc --minify

      - name: Install htmltest
        run: curl https://htmltest.wjdp.uk | sudo bash -s -- -b /usr/local/bin

      - name: Check external links
        id: linkcheck
        run: htmltest -c .htmltest.external.yml public
        continue-on-error: true

      - name: Open issue on failure
        if: steps.linkcheck.outcome == 'failure'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh issue create \
            --title "Link esterni rotti rilevati ($(date +%F))" \
            --body "Il controllo settimanale dei link esterni ha rilevato uno o più link rotti. Vedi il log del workflow: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```

Note: this workflow never blocks a deploy — it runs independently of `deploy.yml`, on a weekly schedule, and only ever opens a GitHub issue on failure.

- [ ] **Step 3: Verify workflow YAML is well-formed**

```bash
python3 -c "import yaml, sys; yaml.safe_load(open('.github/workflows/link-check-external.yml')); print('YAML OK')"
```

Expected: `YAML OK`.

- [ ] **Step 4: Commit**

```bash
git add .htmltest.external.yml .github/workflows/link-check-external.yml
git commit -m "Add scheduled, non-blocking external link check workflow"
```

---

## Task 8: README and Cloudflare Pages one-time setup

**Files:**
- Modify: `readme.md`

**Interfaces:**
- Consumes: nothing (documentation only, references all prior tasks' files by path).

- [ ] **Step 1: Rewrite `readme.md`**

```markdown
# baicode journal

Blog personale di Antonino Benedetto: ogni articolo racconta una decisione tecnica reale — il problema, le alternative valutate, la scelta fatta, i compromessi accettati.

Generato con [Hugo](https://gohugo.io), contenuti flat-file in Markdown, nessun framework CSS, hosting su Cloudflare Pages. Il ragionamento dietro le scelte tecniche di questo progetto è in `docs/adr/`; il design complessivo in `docs/superpowers/specs/`.

## Sviluppo locale

Serve il binario Hugo (edizione standard, non extended):

```bash
hugo server -D
```

Apre il sito su `http://localhost:1313/` con i contenuti in bozza (`-D`) inclusi.

## Build di produzione

```bash
hugo --gc --minify
```

Genera il sito in `public/`. È lo stesso comando eseguito dalla CI prima del deploy.

## Pubblicare un articolo

```bash
hugo new content/it/blog/mio-articolo.md
hugo new content/en/blog/my-article.md
```

Allinea il campo `translationKey` nel frontmatter dei due file allo stesso valore, così Hugo li riconosce come traduzioni l'uno dell'altro anche con slug diversi. Scrivi il contenuto, imposta `draft: false` quando è pronto, poi commit e push su `main`: la CI builda, verifica i link interni e pubblica su Cloudflare Pages.

## Struttura

- `content/it/`, `content/en/` — articoli e pagine, uno per lingua
- `layouts/` — template Hugo custom (nessun tema di terze parti)
- `assets/css/` — CSS scritto a mano, nessun framework
- `docs/adr/` — Architecture Decision Record di questo repository
- `docs/superpowers/specs/` — design doc del progetto

## Deploy

Push su `main` innesca `.github/workflows/deploy.yml`: build Hugo, controllo dei link interni (bloccante), deploy su Cloudflare Pages via `wrangler`. I link esterni sono controllati settimanalmente da `.github/workflows/link-check-external.yml`, che apre una issue senza bloccare la pubblicazione.

### Setup una tantum di Cloudflare Pages

1. Crea un progetto Pages su Cloudflare (come progetto "direct upload", gestito solo da CI — non collegato direttamente al repo GitHub, per evitare un secondo trigger di deploy parallelo a quello della Action).
2. Aggiungi un record DNS CNAME `blog` → dominio assegnato da Cloudflare Pages, senza spostare i nameserver del dominio personale su Cloudflare.
3. Genera un API Token Cloudflare con permesso "Cloudflare Pages: Edit" e salvalo come secret `CLOUDFLARE_API_TOKEN` del repository GitHub.
4. Salva l'Account ID Cloudflare come secret `CLOUDFLARE_ACCOUNT_ID` del repository GitHub.
5. Aggiorna `baseURL` in `hugo.toml` e `params.homeURL` con i domini reali (blog e homepage) prima del primo deploy in produzione.
```

- [ ] **Step 2: Verify the README references existing paths**

```bash
for f in docs/adr docs/superpowers/specs content/it content/en layouts assets/css .github/workflows/deploy.yml .github/workflows/link-check-external.yml; do
  test -e "$f" && echo "OK: $f" || echo "MISSING: $f"
done
```

Expected: every line prints `OK: ...`, none print `MISSING`.

- [ ] **Step 3: Commit**

```bash
git add readme.md
git commit -m "Rewrite README: local dev, publishing workflow, Cloudflare Pages setup"
```
