# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Cos'è questo repository

Blog personale di Antonino Benedetto generato con [Hugo](https://gohugo.io) (edizione standard, non extended). Ogni articolo racconta una decisione tecnica reale: problema, alternative valutate, scelta fatta, compromessi accettati. Contenuti flat-file in Markdown, nessun framework CSS, hosting su Cloudflare Pages.

## Comandi

```bash
hugo server -D        # dev server locale su http://localhost:1313/, include le bozze (-D)
hugo --gc --minify    # build di produzione in public/, stesso comando eseguito dalla CI
```

Creare un nuovo articolo (richiede sempre la coppia IT+EN, su un branch `post/<slug>`, non direttamente su `main`):

```bash
git checkout -b post/<slug> main
hugo new -k blog content/it/blog/mio-articolo.md
hugo new -k blog content/en/blog/my-article.md
```

Non ci sono test automatici o linter JS/CSS: la verifica di correttezza in CI è il link check (`htmltest`) più il guardrail sul front matter (`scripts/check-content-guardrails.sh`).

## Architettura

**Bilingue by design.** Ogni contenuto esiste in `content/it/` e `content/en/`, con `defaultContentLanguage = "it"` e sotto-directory NON in URL (`defaultContentLanguageInSubdir = false`). I due file di un articolo sono legati tramite lo stesso valore di `translationKey` nel frontmatter — è questo campo, non il path, a far riconoscere a Hugo le due versioni come traduzioni; il language switcher in `layouts/partials/nav.html` si basa su `.Translations`, che dipende da questo collegamento. L'archetype `archetypes/blog.md` pre-popola `translationKey` con lo slug del file, quindi va allineato a mano quando si crea la versione nell'altra lingua.

**Nessun tema di terze parti.** Tutti i template sono in `layouts/` (baseof + partials `head`/`nav`/`footer` + `_default/single|list|terms`), tutto il CSS è scritto a mano in `assets/css/main.css` e `assets/css/chroma.css` (syntax highlighting), processato tramite Hugo Pipes con fingerprinting SHA-256 e integrity hash (vedi `layouts/partials/head.html`). Le stringhe di UI (non i contenuti) sono in `i18n/it.toml` e `i18n/en.toml`.

**Governance delle decisioni tecniche.** Le decisioni architetturali significative del repository stesso sono registrate come ADR in `docs/adr/` (formato: contesto → decisione → alternative scartate → conseguenze; una volta accettata un'ADR non si riscrive, si supera con una nuova). L'indice è in `docs/adr/README.md`. I design doc più ampi (spec + piano di implementazione) sono in `docs/superpowers/specs/` e `docs/superpowers/plans/`.

**Pubblicazione via PR con anteprima; il merge è l'atto di pubblicazione (ADR-004).** Ogni articolo o modifica al sito passa da un branch a vita breve `post/<slug>` e una pull request verso `main`. `.github/workflows/deploy.yml` reagisce sia a `push` su `main` (deploy di produzione: build Hugo, `htmltest` sui link interni, `wrangler pages deploy`) sia a `pull_request` verso `main` (guardrail bloccante sul front matter via `scripts/check-content-guardrails.sh` — rifiuta `draft: true` o `date` futura —, build con `--baseURL` puntato all'anteprima, `htmltest`, deploy di anteprima su `post-<slug>.baicode-journal.pages.dev` con `wrangler pages deploy --branch=<alias>`). Cloudflare Pages è configurato come progetto "direct upload" gestito solo dalla CI (non collegato direttamente al repo GitHub, per evitare un doppio trigger di deploy). Il branch `main` è protetto: merge solo via PR con CI verde. I link esterni sono invece controllati settimanalmente da `.github/workflows/link-check-external.yml` (config `.htmltest.external.yml`), che apre una issue in caso di link rotti senza bloccare la pubblicazione.
