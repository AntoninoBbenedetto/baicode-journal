# Layout Theme Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the layout refresh described in `docs/superpowers/specs/2026-07-17-layout-theme-refresh-design.md`: a typographic/spacing token system, a richer post-list card (excerpt + reading time + tags) shared by the blog archive and tag pages, a visually distinct featured post on the homepage, and matching meta refinements on the single-article page.

**Architecture:** All changes live in the existing hand-written `assets/css/main.css` and the existing Hugo templates in `layouts/` — no new CSS files, no new partials, no third-party theme or Node toolchain (ADR-002). Hugo's built-in `.Summary` and `.ReadingTime` page fields drive the excerpt and reading-time display; no new front-matter fields are introduced. A single new i18n key (`readingTime`) is shared by the post-list card and the single-article page.

**Tech Stack:** Hugo v0.164.0 (standard binary, already installed at `~/.local/bin/hugo`), hand-written CSS (custom properties), Hugo i18n (`i18n/it.toml`, `i18n/en.toml`), htmltest v0.17.0 (already installed at `~/.local/bin/htmltest`) for internal-link verification.

## Global Constraints

- No third-party theme, no Node.js/npm/Tailwind toolchain anywhere (ADR-002). Do not add `package.json` or any build step beyond Hugo Pipes.
- No new CSS files or new template partials — every change lands in `assets/css/main.css` and the four existing templates listed in the spec (`docs/superpowers/specs/2026-07-17-layout-theme-refresh-design.md` §4).
- No dark mode and no new responsive media queries in this plan — out of scope per the spec.
- No new font files — system font stack only (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`, already in `main.css`), unchanged.
- No automated test suite in this repository (project convention — see `CLAUDE.md`). Every verification step below is a real `hugo` build followed by a `grep`/`find` assertion on the generated output in `public/`, not a persisted test framework.
- `public/` is git-ignored (`.gitignore:1`) — building into it during verification never dirties `git status`.
- Both `hugo` and `htmltest` are already installed and on `PATH` in this environment (`~/.local/bin`); no install step is needed before running them.

---

## Task 1: Typography and spacing tokens

**Files:**
- Modify: `assets/css/main.css`

**Interfaces:**
- Produces: CSS custom properties `--space-1` … `--space-6` and `--font-size-sm`, `--font-size-base`, `--font-size-lg`, `--font-size-xl`, `--font-size-2xl` on `:root`, plus base `h1`/`h2`/`h3`/`p` rules. Tasks 2–4 use these variables and heading rules; do not rename them.

- [ ] **Step 1: Add the token variables to `:root`**

Replace:

```css
:root {
  --color-bg: #ffffff;
  --color-fg: #1a1a1a;
  --color-muted: #6b6b6b;
  --color-accent: #1d4ed8;
  --max-width: 42rem;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
```

with:

```css
:root {
  --color-bg: #ffffff;
  --color-fg: #1a1a1a;
  --color-muted: #6b6b6b;
  --color-accent: #1d4ed8;
  --max-width: 42rem;

  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 1rem;
  --space-4: 1.5rem;
  --space-5: 2.5rem;
  --space-6: 4rem;

  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.25rem;
  --font-size-xl: 1.75rem;
  --font-size-2xl: 2.25rem;

  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
```

- [ ] **Step 2: Add heading and paragraph rules**

Directly after the `body { ... }` rule (before `main { ... }`), insert:

```css
h1, h2, h3 {
  line-height: 1.25;
  font-weight: 700;
}

h1 {
  font-size: var(--font-size-2xl);
  margin: 0 0 var(--space-3);
}

h2 {
  font-size: var(--font-size-xl);
  margin: var(--space-5) 0 var(--space-3);
}

h3 {
  font-size: var(--font-size-lg);
  margin: var(--space-4) 0 var(--space-2);
}

p {
  margin: 0 0 var(--space-3);
}
```

- [ ] **Step 3: Replace literal spacing values with tokens**

In `main`, replace `padding: 1.5rem;` with `padding: var(--space-4);`.

In `.site-nav`, replace:

```css
.site-nav {
  display: flex;
  gap: 1rem;
  align-items: center;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e5e5;
}
```

with:

```css
.site-nav {
  display: flex;
  gap: var(--space-3);
  align-items: center;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: var(--space-4);
  border-bottom: 1px solid #e5e5e5;
}
```

In `.lang-switch`, replace `gap: 0.5rem;` with `gap: var(--space-2);`.

In `.site-footer`, replace:

```css
.site-footer {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 1.5rem;
  border-top: 1px solid #e5e5e5;
  color: var(--color-muted);
  display: flex;
  justify-content: space-between;
}
```

with:

```css
.site-footer {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: var(--space-4);
  border-top: 1px solid #e5e5e5;
  color: var(--color-muted);
  display: flex;
  justify-content: space-between;
}
```

In `pre`, replace `padding: 1rem;` with `padding: var(--space-3);`.

- [ ] **Step 4: Verify the production build succeeds (validates CSS syntax)**

```bash
hugo --gc --minify
echo "build exit: $?"
```

Expected: `build exit: 0`. (Hugo's CSS minifier parses the file; a syntax error here would fail the build.)

- [ ] **Step 5: Verify the new tokens are present in the built CSS**

```bash
css_file=$(find public/css -name 'main.*.css')
grep -o -- '--space-1:[^;]*' "$css_file" && echo "space token OK"
grep -o -- '--font-size-2xl:[^;]*' "$css_file" && echo "font-size token OK"
```

Expected: both `OK` lines printed (the minifier keeps custom property declarations intact).

- [ ] **Step 6: Commit**

```bash
git add assets/css/main.css
git commit -m "Add typography and spacing token scale to main.css"
```

---

## Task 2: Reading-time i18n string and post-list card

**Files:**
- Modify: `i18n/it.toml`
- Modify: `i18n/en.toml`
- Modify: `layouts/_default/list.html`
- Modify: `assets/css/main.css`

**Interfaces:**
- Consumes: `--space-*`, `--font-size-*` tokens from Task 1.
- Produces: i18n key `readingTime` (takes a numeric argument, e.g. `{{ i18n "readingTime" .ReadingTime }}`) and CSS classes `.post-card`, `.post-card-title`, `.post-card-meta`, `.post-card-excerpt`. Task 3 (`index.html`) and Task 4 (`single.html`) reuse the `readingTime` key and the `.post-card-*` classes; do not rename them.

- [ ] **Step 1: Add the `readingTime` i18n key**

Append to `i18n/it.toml`:

```toml
[readingTime]
other = "{{ .Count }} min di lettura"
```

Append to `i18n/en.toml`:

```toml
[readingTime]
other = "{{ .Count }} min read"
```

- [ ] **Step 2: Rewrite the post-list markup in `list.html`**

Replace the whole file with:

```html
{{ define "main" }}
  <h1>{{ .Title }}</h1>
  <ul class="post-list">
    {{ range .Pages }}
      <li class="post-card">
        <h2 class="post-card-title"><a href="{{ .RelPermalink }}">{{ .Title }}</a></h2>
        <p class="post-card-meta">
          <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "2 January 2006" }}</time>
          · {{ i18n "readingTime" .ReadingTime }}
        </p>
        <p class="post-card-excerpt">{{ .Summary }}</p>
        {{ if .Params.tags }}
          <p class="tags">
            {{ range .Params.tags }}<a href="{{ "/tags/" | relLangURL }}{{ . | urlize }}/" class="tag">{{ . }}</a>{{ end }}
          </p>
        {{ end }}
      </li>
    {{ end }}
  </ul>
{{ end }}
```

(`<h2>` is correct here: this page's own title — "Blog", a tag name — renders as `<h1>` above, so each post title inside is one level down.)

- [ ] **Step 3: Replace `.post-list` item styling in `main.css`**

Replace:

```css
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
```

with:

```css
.post-list {
  list-style: none;
  padding: 0;
}

.post-card {
  margin-bottom: var(--space-5);
}

.post-card-title {
  margin: 0 0 var(--space-1);
}

.post-card-title a {
  text-decoration: none;
}

.post-card-title a:hover {
  text-decoration: underline;
}

.post-card-meta {
  color: var(--color-muted);
  font-size: var(--font-size-sm);
  margin: 0 0 var(--space-2);
}

.post-card-excerpt {
  margin: 0 0 var(--space-2);
}
```

(`.post-card-title` deliberately does not set `font-size`: it inherits the surrounding heading tag's size from Task 1's `h2`/`h3` rules, so the same class looks right whether it wraps an `<h2>` here or an `<h3>` in Task 3's homepage markup.)

Also update `.tags` (used both standalone in `single.html` and inside `.post-card`): replace `margin-top: 0.5rem;` with `margin-top: var(--space-2);`.

- [ ] **Step 4: Build with drafts and verify the card markup renders (Italian)**

```bash
hugo --gc --minify -D
echo "build exit: $?"
grep -qE '<li class="?post-card"?>' public/blog/index.html && echo "post-card OK"
grep -qE '<p class="?post-card-meta"?>' public/blog/index.html && echo "meta OK"
grep -q 'min di lettura' public/blog/index.html && echo "reading time IT OK"
grep -q 'Questo blog nasce' public/blog/index.html && echo "excerpt OK"
```

Expected: `build exit: 0`, then `post-card OK`, `meta OK`, `reading time IT OK`, `excerpt OK`.

(Hugo's HTML minifier drops quotes from attribute values that contain no whitespace, e.g. `class=post-card` instead of `class="post-card"` — the `-E` regex with `"?` matches both forms. This applies to every class-matching `grep` in this plan from here on.)

- [ ] **Step 5: Verify the English variant**

```bash
grep -q 'min read' public/en/blog/index.html && echo "reading time EN OK"
grep -q 'This blog exists' public/en/blog/index.html && echo "excerpt EN OK"
```

Expected: `reading time EN OK` and `excerpt EN OK`.

- [ ] **Step 6: Verify a tag page reuses the same card (falls back to `list.html`)**

```bash
grep -qE '<li class="?post-card"?>' public/tags/meta/index.html && echo "tag page card OK"
```

Expected: `tag page card OK`.

- [ ] **Step 7: Rebuild production (no drafts) to confirm no breakage with zero posts**

```bash
hugo --gc --minify
echo "production build exit: $?"
```

Expected: `production build exit: 0` (both current posts are `draft: true`, so the list is legitimately empty in production — this just confirms the new template doesn't error on an empty `.Pages`).

- [ ] **Step 8: Commit**

```bash
git add i18n/it.toml i18n/en.toml layouts/_default/list.html assets/css/main.css
git commit -m "Add reading-time i18n key and post-list card (excerpt, reading time, tags)"
```

---

## Task 3: Homepage featured post

**Files:**
- Modify: `layouts/index.html`
- Modify: `assets/css/main.css`

**Interfaces:**
- Consumes: `readingTime` i18n key and `.post-card`/`.post-card-title`/`.post-card-meta`/`.post-card-excerpt` classes from Task 2.
- Produces: CSS classes `.post-featured`, `.post-featured-title`, `.post-featured-excerpt`. Nothing downstream depends on these.

- [ ] **Step 1: Split the most recent post out of the range in `index.html`**

Replace:

```html
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

with:

```html
{{ define "main" }}
  <section class="home-intro">
    <h1>{{ .Title }}</h1>
    {{ .Content }}
  </section>
  <section class="recent-posts">
    <h2>{{ i18n "recentPosts" }}</h2>
    {{ $posts := first 5 (where .Site.RegularPages "Section" "blog") }}
    {{ if $posts }}
      {{ $featured := index $posts 0 }}
      <article class="post-featured">
        <h3 class="post-card-title post-featured-title"><a href="{{ $featured.RelPermalink }}">{{ $featured.Title }}</a></h3>
        <p class="post-card-meta">
          <time datetime="{{ $featured.Date.Format "2006-01-02" }}">{{ $featured.Date.Format "2 January 2006" }}</time>
          · {{ i18n "readingTime" $featured.ReadingTime }}
        </p>
        <p class="post-card-excerpt post-featured-excerpt">{{ $featured.Summary }}</p>
        {{ if $featured.Params.tags }}
          <p class="tags">
            {{ range $featured.Params.tags }}<a href="{{ "/tags/" | relLangURL }}{{ . | urlize }}/" class="tag">{{ . }}</a>{{ end }}
          </p>
        {{ end }}
      </article>
      {{ $rest := after 1 $posts }}
      {{ if $rest }}
        <ul class="post-list">
          {{ range $rest }}
            <li class="post-card">
              <h3 class="post-card-title"><a href="{{ .RelPermalink }}">{{ .Title }}</a></h3>
              <p class="post-card-meta">
                <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "2 January 2006" }}</time>
                · {{ i18n "readingTime" .ReadingTime }}
              </p>
              <p class="post-card-excerpt">{{ .Summary }}</p>
              {{ if .Params.tags }}
                <p class="tags">
                  {{ range .Params.tags }}<a href="{{ "/tags/" | relLangURL }}{{ . | urlize }}/" class="tag">{{ . }}</a>{{ end }}
                </p>
              {{ end }}
            </li>
          {{ end }}
        </ul>
      {{ end }}
    {{ end }}
  </section>
{{ end }}
```

(`{{ if $posts }}` guards `index $posts 0`: Go templates panic on an out-of-range `index` call, so the guard must wrap the call itself, not just the visible markup — this matters today because production builds have zero non-draft posts.)

- [ ] **Step 2: Add featured-post styling to `main.css`**

Append after the `.post-card-excerpt` rule (added in Task 2):

```css
.post-featured {
  margin-bottom: var(--space-6);
  padding-bottom: var(--space-5);
  border-bottom: 1px solid #e5e5e5;
}

.post-featured-title {
  font-size: var(--font-size-xl);
}

.post-featured-excerpt {
  font-size: var(--font-size-base);
}
```

(`.post-featured-title` must be declared after `.post-card-title` in the stylesheet: both are single-class selectors of equal specificity, so source order decides which `font-size` wins.)

- [ ] **Step 3: Verify the single-post case (today's real content) renders the featured post with no trailing list**

```bash
hugo --gc --minify -D
echo "build exit: $?"
grep -qE 'class="?post-featured"?' public/index.html && echo "featured OK (IT)"
grep -qE '<li class="?post-card"?>' public/index.html && echo "UNEXPECTED: rest list rendered with only 1 post" || echo "no rest list OK (IT)"
grep -qE 'class="?post-featured"?' public/en/index.html && echo "featured OK (EN)"
```

Expected: `featured OK (IT)`, `no rest list OK (IT)`, `featured OK (EN)`. (Both current posts are the only post in their language, so `$rest` is empty and no `<ul class="post-list">` should appear inside `.recent-posts`.)

- [ ] **Step 4: Add temporary fixture posts to verify the multi-post case**

```bash
cat > content/it/blog/fixture-secondo-post.md <<'EOF'
---
title: "Fixture: secondo articolo"
date: 2026-01-01
draft: false
translationKey: "fixture-secondo-post"
tags: ["fixture"]
---
Contenuto di prova per verificare la lista degli articoli non in evidenza in home.
EOF
cat > content/it/blog/fixture-terzo-post.md <<'EOF'
---
title: "Fixture: terzo articolo"
date: 2025-12-01
draft: false
translationKey: "fixture-terzo-post"
tags: ["fixture"]
---
Altro contenuto di prova, pubblicato prima del secondo.
EOF
```

- [ ] **Step 5: Rebuild and verify the featured post plus a rest-list of exactly 2**

```bash
hugo --gc --minify -D
echo "build exit: $?"
grep -qE 'class="?post-featured"?' public/index.html && echo "featured still OK"
grep -oE '<li class="?post-card"?>' public/index.html | wc -l
```

Expected: `build exit: 0`, `featured still OK`, and the count is `2` (the two fixtures; `benvenuto.md` is the most recent post so it becomes the featured one, not part of the rest-list count). Use `grep -o ... | wc -l` rather than `grep -c`: `grep -c` counts matching *lines*, and Hugo's minifier can put multiple elements on one line, which would silently undercount.

- [ ] **Step 6: Remove the fixtures and confirm the working tree is clean**

```bash
rm content/it/blog/fixture-secondo-post.md content/it/blog/fixture-terzo-post.md
git status --short content/it/blog
```

Expected: no output (fixtures were never staged, deleting them leaves no trace).

- [ ] **Step 7: Rebuild production once more to leave a clean state**

```bash
hugo --gc --minify
echo "production build exit: $?"
```

Expected: `production build exit: 0`.

- [ ] **Step 8: Commit**

```bash
git add layouts/index.html assets/css/main.css
git commit -m "Add featured-post treatment to the homepage recent-posts section"
```

---

## Task 4: Single-article meta refinement

**Files:**
- Modify: `layouts/_default/single.html`
- Modify: `assets/css/main.css`

**Interfaces:**
- Consumes: `readingTime` i18n key from Task 2.
- Produces: CSS class `.article-meta`. Nothing downstream depends on it.

- [ ] **Step 1: Wrap the date and add reading time in `single.html`**

Replace:

```html
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
```

with:

```html
{{ define "main" }}
  <article>
    <h1>{{ .Title }}</h1>
    <p class="article-meta">
      <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "2 January 2006" }}</time>
      · {{ i18n "readingTime" .ReadingTime }}
    </p>
    {{ if .Params.tags }}
      <div class="tags">
        {{ range .Params.tags }}<a href="{{ "/tags/" | relLangURL }}{{ . | urlize }}/" class="tag">{{ . }}</a>{{ end }}
      </div>
    {{ end }}
    {{ .Content }}
  </article>
```

(The rest of the file — the `<aside class="translations">` block — is unchanged.)

- [ ] **Step 2: Add `.article-meta` styling to `main.css`**

Append after the `.post-featured-excerpt` rule (added in Task 3):

```css
.article-meta {
  color: var(--color-muted);
  font-size: var(--font-size-sm);
  margin: 0 0 var(--space-3);
}
```

- [ ] **Step 3: Verify the single-article page (Italian)**

```bash
hugo --gc --minify -D
echo "build exit: $?"
grep -qE '<p class="?article-meta"?>' public/blog/benvenuto/index.html && echo "article-meta OK"
grep -q 'min di lettura' public/blog/benvenuto/index.html && echo "reading time on article OK"
```

Expected: `build exit: 0`, `article-meta OK`, `reading time on article OK`.

- [ ] **Step 4: Verify the English variant**

```bash
grep -qE '<p class="?article-meta"?>' public/en/blog/welcome/index.html && echo "article-meta EN OK"
grep -q 'min read' public/en/blog/welcome/index.html && echo "reading time EN OK"
```

Expected: `article-meta EN OK`, `reading time EN OK`.

- [ ] **Step 5: Rebuild production once more to leave a clean state**

```bash
hugo --gc --minify
echo "production build exit: $?"
```

Expected: `production build exit: 0`.

- [ ] **Step 6: Commit**

```bash
git add layouts/_default/single.html assets/css/main.css
git commit -m "Add reading time and meta wrapper to the single-article layout"
```

---

## Task 5: Full regression pass

**Files:** none (verification only).

**Interfaces:**
- Consumes: all templates and CSS from Tasks 1–4.
- Produces: nothing — this is the final confidence check before the branch is considered done.

- [ ] **Step 1: Production build (real content, no drafts) passes htmltest**

```bash
hugo --gc --minify
echo "build exit: $?"
htmltest -c .htmltest.yml public
echo "htmltest exit: $?"
```

Expected: `build exit: 0` and `htmltest exit: 0`.

- [ ] **Step 2: Draft build (real content, both languages) passes htmltest**

```bash
hugo --gc --minify -D
echo "build exit: $?"
htmltest -c .htmltest.yml public
echo "htmltest exit: $?"
```

Expected: `build exit: 0` and `htmltest exit: 0` — confirms the new card/featured/meta markup introduces no broken internal links across home, blog list, tag pages, and single articles in both languages.

- [ ] **Step 3: Spot-check every affected page type renders the new classes**

```bash
for f in public/index.html public/en/index.html public/blog/index.html public/en/blog/index.html public/tags/meta/index.html public/en/tags/meta/index.html public/blog/benvenuto/index.html public/en/blog/welcome/index.html; do
  test -f "$f" && echo "exists: $f" || echo "MISSING: $f"
done
grep -lE 'class="?post-card' public/blog/index.html public/en/blog/index.html public/tags/meta/index.html public/en/tags/meta/index.html
grep -lE 'class="?post-featured' public/index.html public/en/index.html
grep -lE 'class="?article-meta' public/blog/benvenuto/index.html public/en/blog/welcome/index.html
```

Expected: every `test -f` prints `exists:`, none print `MISSING`; each `grep -l` lists all the files passed to it (meaning the class is present in every one).

- [ ] **Step 4: Manual visual check (not automatable — for you, in a browser)**

```bash
hugo server -D
```

Open `http://localhost:1313/` and `http://localhost:1313/en/`, and click through to `/blog/`, a tag page, and the single article, in both languages. Confirm: the heading hierarchy reads cleanly (page title → section title → post title), the featured post on the home page stands out from the rest of the list, excerpts and reading time look right, and spacing feels consistent across pages. Stop the server (Ctrl-C) when done — the grep-based steps above already confirm the markup is technically correct; this step is about how it actually looks.

- [ ] **Step 5: Rebuild production once more to leave the working tree in its normal state**

```bash
hugo --gc --minify
echo "final build exit: $?"
git status --short
```

Expected: `final build exit: 0`; `git status --short` shows no unexpected changes (only `public/` activity, which is git-ignored, so no output related to it).

No commit for this task — it verifies work already committed in Tasks 1–4.
