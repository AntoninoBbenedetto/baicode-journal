# Content Publishing Strategy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the publishing flow described in `docs/superpowers/specs/2026-07-14-content-publishing-design.md`: articles reach `main` via a short-lived `post/<slug>` branch and a PR that gets a live Cloudflare Pages preview and blocking front-matter guardrails; merging the PR is the act of publishing.

**Architecture:** A single GitHub Actions workflow (`.github/workflows/deploy.yml`) now reacts to both `push` (to `main`) and `pull_request` (into `main`) events. Both share the Hugo install, build, and `htmltest` internal-link-check steps; they diverge only in the `--baseURL` passed to Hugo, in whether the front-matter guardrail script runs, and in the `wrangler pages deploy` invocation (production vs. `--branch=<alias>` preview). The guardrail is a small dependency-free bash script (`scripts/check-content-guardrails.sh`) that fails the PR build if any content file under `content/` has `draft: true` or a future `date`. ADR-004 documents the decision; the README gains a rewritten "Pubblicare un articolo" section and a one-time GitHub branch-protection setup step.

**Tech Stack:** Bash, GitHub Actions, Hugo v0.164.0 (standard binary), htmltest, Cloudflare Pages (`wrangler pages deploy` via `cloudflare/wrangler-action@v3`).

## Global Constraints

- No Node.js/npm dependency anywhere in this project (ADR-002). Do not add a `package.json`.
- No automated test suite in this repository (per the blog design/plan's global constraints). Every verification step here is a manual script run + assertion (`bash script; echo "exit: $?"` / `grep` on output), not a persisted test framework.
- The guardrail script must have zero external dependencies beyond tools already present on the GitHub Actions `ubuntu-latest` runner and on a standard Linux dev machine (`bash`, `find`, `grep`, `sed`, `date` — no `yq`, no Python front-matter parser).
- `translationKey` alignment between an IT/EN post pair is **not** enforced by CI (per spec §2) — it stays a manual checklist item in the README.
- This plan does not touch `.github/workflows/link-check-external.yml` (external link checking) — that belongs to the original blog implementation plan's Task 7 and is out of scope for the content-publishing spec.
- `hugo` is not installed in a fresh shell in this environment — every verification step that runs `hugo` must (re)install it first, exactly as in the original blog plan's Task 1 Step 1.

---

## Task 1: Front-matter guardrail script

**Files:**
- Create: `scripts/check-content-guardrails.sh`

**Interfaces:**
- Produces: an executable script invoked as `./scripts/check-content-guardrails.sh [content-dir]` (`content-dir` defaults to `content`). Exits `0` if no file under `content-dir` has `draft: true` or a `date` in the future (UTC); exits `1` and prints one `FAIL: <path> ...` line per offending file otherwise. Consumed by Task 2's CI workflow.

- [ ] **Step 1: Write the script**

`scripts/check-content-guardrails.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

content_dir="${1:-content}"
now_epoch=$(date -u +%s)
failed=0

while IFS= read -r -d '' file; do
  delimiter_count=0
  frontmatter=""

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      delimiter_count=$((delimiter_count + 1))
      if [[ $delimiter_count -eq 2 ]]; then
        break
      fi
      continue
    fi
    if [[ $delimiter_count -eq 1 ]]; then
      frontmatter+="$line"$'\n'
    fi
  done < "$file"

  if echo "$frontmatter" | grep -qE '^draft:[[:space:]]*true[[:space:]]*$'; then
    echo "FAIL: $file has draft: true"
    failed=1
  fi

  date_line=$(echo "$frontmatter" | grep -E '^date:' || true)
  if [[ -n "$date_line" ]]; then
    date_value=$(printf '%s\n' "$date_line" | sed -E "s/^date:[[:space:]]*//; s/^['\"]//; s/['\"][[:space:]]*\$//")
    date_epoch=$(date -u -d "$date_value" +%s 2>/dev/null || echo "")
    if [[ -n "$date_epoch" && "$date_epoch" -gt "$now_epoch" ]]; then
      echo "FAIL: $file has future date ($date_value)"
      failed=1
    fi
  fi
done < <(find "$content_dir" -name '*.md' -print0)

if [[ "$failed" -eq 1 ]]; then
  echo "Guardrail check failed: draft or future-dated content found under $content_dir"
  exit 1
fi

echo "Guardrail check passed: no draft or future-dated content under $content_dir"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/check-content-guardrails.sh
```

- [ ] **Step 3: Verify it fails on a draft post**

```bash
rm -rf /tmp/guardrail-fixture-a && mkdir -p /tmp/guardrail-fixture-a
cat > /tmp/guardrail-fixture-a/draft-post.md <<'EOF'
---
title: "Draft"
date: 2026-01-01
draft: true
---
Body.
EOF
./scripts/check-content-guardrails.sh /tmp/guardrail-fixture-a
echo "exit: $?"
```

Expected: prints `FAIL: /tmp/guardrail-fixture-a/draft-post.md has draft: true`, then `Guardrail check failed: ...`, then `exit: 1`.

- [ ] **Step 4: Verify it fails on a future-dated post**

```bash
rm -rf /tmp/guardrail-fixture-b && mkdir -p /tmp/guardrail-fixture-b
cat > /tmp/guardrail-fixture-b/future-post.md <<'EOF'
---
title: "Future"
date: 2099-01-01
draft: false
---
Body.
EOF
./scripts/check-content-guardrails.sh /tmp/guardrail-fixture-b
echo "exit: $?"
```

Expected: prints `FAIL: /tmp/guardrail-fixture-b/future-post.md has future date (2099-01-01)`, then `Guardrail check failed: ...`, then `exit: 1`.

- [ ] **Step 5: Verify it passes on a normal post**

```bash
rm -rf /tmp/guardrail-fixture-c && mkdir -p /tmp/guardrail-fixture-c
cat > /tmp/guardrail-fixture-c/ok-post.md <<'EOF'
---
title: "OK"
date: 2026-01-01
draft: false
tags: ["meta"]
---
Body.
EOF
./scripts/check-content-guardrails.sh /tmp/guardrail-fixture-c
echo "exit: $?"
rm -rf /tmp/guardrail-fixture-a /tmp/guardrail-fixture-b /tmp/guardrail-fixture-c
```

Expected: prints `Guardrail check passed: no draft or future-dated content under /tmp/guardrail-fixture-c`, then `exit: 0`. Fixture directories removed afterward.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-content-guardrails.sh
git commit -m "Add front-matter guardrail script: reject draft or future-dated content"
```

---

## Task 2: CI workflow — PR preview and production deploy

**Files:**
- Create: `.htmltest.yml`
- Create: `.github/workflows/deploy.yml`

**Interfaces:**
- Consumes: `scripts/check-content-guardrails.sh` (Task 1, default `content-dir`); `hugo --gc --minify` build output in `public/` (all prior blog-implementation tasks).
- Produces: nothing consumed by later tasks in this plan.

- [ ] **Step 1: Write `.htmltest.yml`**

```yaml
DirectoryPath: "public"
CheckExternal: false
CheckInternal: true
CheckInternalHash: true
```

- [ ] **Step 2: Write `.github/workflows/deploy.yml`**

```bash
mkdir -p .github/workflows
```

`.github/workflows/deploy.yml`:
```yaml
name: Build and deploy

on:
  push:
    branches: [main]
  pull_request:
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

      - name: Check content guardrails
        if: github.event_name == 'pull_request'
        run: ./scripts/check-content-guardrails.sh

      - name: Compute preview alias and base URL
        if: github.event_name == 'pull_request'
        id: preview
        run: |
          alias=$(echo "${{ github.head_ref }}" | tr '/' '-')
          echo "alias=$alias" >> "$GITHUB_OUTPUT"
          echo "base_url=https://$alias.baicode-journal.pages.dev/" >> "$GITHUB_OUTPUT"

      - name: Build site (production)
        if: github.event_name == 'push'
        run: hugo --gc --minify

      - name: Build site (preview)
        if: github.event_name == 'pull_request'
        run: hugo --gc --minify --baseURL "${{ steps.preview.outputs.base_url }}"

      - name: Install htmltest
        run: curl https://htmltest.wjdp.uk | sudo bash -s -- -b /usr/local/bin

      - name: Check internal links
        run: htmltest -c .htmltest.yml public

      - name: Deploy to Cloudflare Pages (production)
        if: github.event_name == 'push'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy public --project-name=baicode-journal

      - name: Deploy preview to Cloudflare Pages
        if: github.event_name == 'pull_request'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy public --project-name=baicode-journal --branch=${{ steps.preview.outputs.alias }}
```

- [ ] **Step 3: Verify both YAML files are well-formed**

```bash
python3 -c "import yaml; yaml.safe_load(open('.htmltest.yml')); print('htmltest YAML OK')"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy.yml')); print('workflow YAML OK')"
```

Expected: `htmltest YAML OK` then `workflow YAML OK`.

- [ ] **Step 4: Install Hugo and htmltest locally (skip if already on PATH)**

```bash
command -v hugo >/dev/null || {
  curl -sL https://github.com/gohugoio/hugo/releases/download/v0.164.0/hugo_0.164.0_linux-amd64.tar.gz -o /tmp/hugo.tar.gz
  tar -xzf /tmp/hugo.tar.gz -C /tmp hugo
  mkdir -p "$HOME/.local/bin"
  mv /tmp/hugo "$HOME/.local/bin/hugo"
  export PATH="$HOME/.local/bin:$PATH"
}
hugo version
command -v htmltest >/dev/null || curl https://htmltest.wjdp.uk | bash -s -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
htmltest --version
```

Expected: both `hugo version` and `htmltest --version` print a version string with no error.

- [ ] **Step 5: Verify the production build passes htmltest**

```bash
export PATH="$HOME/.local/bin:$PATH"
hugo --gc --minify
echo "build exit: $?"
htmltest -c .htmltest.yml public
echo "htmltest exit: $?"
```

Expected: `build exit: 0` and `htmltest exit: 0`.

- [ ] **Step 6: Verify a preview build uses the custom baseURL end-to-end**

```bash
export PATH="$HOME/.local/bin:$PATH"
hugo --gc --minify --baseURL "https://post-test-slug.baicode-journal.pages.dev/"
echo "preview build exit: $?"
grep -q 'https://post-test-slug.baicode-journal.pages.dev' public/it/sitemap.xml && echo "sitemap uses preview baseURL OK"
grep -q 'https://post-test-slug.baicode-journal.pages.dev' public/it/index.xml && echo "RSS uses preview baseURL OK"
hugo --gc --minify
```

Expected: `preview build exit: 0`, both `OK` lines printed. The final `hugo --gc --minify` at the end restores `public/` to the production baseURL so the working tree isn't left in a preview state.

- [ ] **Step 7: Commit**

```bash
git add .htmltest.yml .github/workflows/deploy.yml
git commit -m "Add CI workflow: build, link check, guardrail, PR preview, production deploy"
```

---

## Task 3: ADR-004 — publish via PR with preview

**Files:**
- Create: `docs/adr/004-pubblicazione-pr-anteprima.md`
- Modify: `docs/adr/README.md` (append the new row to the index table)

**Interfaces:**
- Consumes: format from `docs/adr/template.md`; the flow and rejected alternatives from `docs/superpowers/specs/2026-07-14-content-publishing-design.md` §1 and §3.
- Produces: nothing consumed by other tasks — documentation only.

- [ ] **Step 1: Write ADR-004**

`docs/adr/004-pubblicazione-pr-anteprima.md`:
```markdown
# ADR-004: Pubblicazione via pull request con anteprima; il merge è l'atto di pubblicazione

- **Stato**: accettata
- **Data**: 2026-07-14

## Contesto

Le ADR precedenti definiscono dove vivono i contenuti (ADR-001), con quale generatore (ADR-002) e su quale hosting (ADR-003), e il piano di implementazione del blog definisce già la pipeline di deploy da `main` verso Cloudflare Pages. Manca però una decisione su **come un articolo arriva su `main`**: l'autore vuole vedere il rendering finale su un URL temporaneo prima che sia pubblico, le due versioni linguistiche (IT/EN) devono uscire insieme, le bozze restano fuori dal repository, e non è prevista pubblicazione programmata né un workflow schedulato di rebuild.

## Decisione

Ogni articolo si pubblica da un branch a vita breve `post/<slug>`, aperto in pull request verso `main`. La CI della PR builda il sito, verifica i link interni, esegue un guardrail bloccante sul front matter (rifiuta `draft: true` o `date` futura) e pubblica un deploy di anteprima su Cloudflare Pages all'URL `post-<slug>.baicode-journal.pages.dev` (alias di branch, build con `--baseURL` puntato a quell'URL). Il merge della PR innesca il deploy di produzione già esistente: **il merge è l'atto di pubblicazione**, senza passaggi ulteriori.

## Alternative scartate

### Branch `content` persistente

Un branch di lunga vita dove accumulare articoli pronti, distinto da `main`. Diverge nel tempo da `main` (richiede merge/rebase ricorrenti), e pubblicare un solo articolo tra i tanti accumulati richiederebbe un cherry-pick selettivo. Con le bozze già tenute fuori dal repository, questo branch non custodirebbe nulla che non sia già altrove.

### Commit diretto su `main`

Il più semplice: nessun branch, nessuna PR. Ma elimina la possibilità di vedere un'anteprima renderizzata prima che l'articolo sia pubblico — ogni commit su `main` pubblica immediatamente, senza finestra di revisione.

### Pubblicazione programmata via data futura + rebuild schedulato

Permetterebbe di mergiare in anticipo e pubblicare a una data prefissata. Richiede però un'infrastruttura aggiuntiva (workflow cron che ribuilda periodicamente) per un'esigenza — la pubblicazione programmata — non prioritaria per un autore singolo. Rinunciarvi elimina anche lo stato intermedio "mergiato ma non ancora visibile", più semplice da ragionare.

## Conseguenze

- Ogni articolo passa da una PR, quindi da una CI verde, prima di essere pubblico: guardrail su bozze/date future e link interni rotti bloccano la pubblicazione accidentale di contenuto non pronto.
- `main` è protetto a livello di repository (merge solo via PR con CI verde): impedisce push diretti accidentali, anche con un solo autore.
- Un errore in un articolo già pubblicato si corregge con una nuova PR (o un revert del merge su `main`); non serve un meccanismo di rollback dedicato.
- I deployment di anteprima si accumulano sul dominio `pages.dev` di Cloudflare: non indicizzati, senza costo aggiuntivo, nessuna pulizia automatica necessaria.
- L'allineamento del `translationKey` tra la coppia IT/EN e la regola "stessa PR per entrambe le lingue" restano affidati alla checklist manuale del README, non a un controllo CI: imporlo automaticamente richiederebbe convenzioni rigide sui nomi file, non applicate qui.
```

- [ ] **Step 2: Update the ADR index**

Append a new row to the table in `docs/adr/README.md` (after the `003` row):

```markdown
| 004 | [Pubblicazione via pull request con anteprima](004-pubblicazione-pr-anteprima.md) | accettata | 2026-07-14 |
```

- [ ] **Step 3: Verify the index links resolve and cross-references are consistent**

```bash
grep -q '004-pubblicazione-pr-anteprima.md' docs/adr/README.md && echo "index link OK"
grep -q 'ADR-001' docs/adr/004-pubblicazione-pr-anteprima.md || echo "no ADR-001 cross-ref (expected: this ADR references ADR-001..003 only in prose, not as markdown links)"
test -f docs/adr/004-pubblicazione-pr-anteprima.md && echo "ADR-004 file exists OK"
```

Expected: `index link OK` and `ADR-004 file exists OK` printed.

- [ ] **Step 4: Commit**

```bash
git add docs/adr/004-pubblicazione-pr-anteprima.md docs/adr/README.md
git commit -m "Add ADR-004: publish via PR with preview, merge is the publish act"
```

---

## Task 4: README — publishing workflow and one-time setup

**Files:**
- Modify: `readme.md` (currently a placeholder containing only `test`)

**Interfaces:**
- Consumes: nothing (documentation only, references paths created by this plan and by the original blog-implementation plan).

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

Genera il sito in `public/`. È lo stesso comando eseguito dalla CI prima del deploy di produzione.

## Pubblicare un articolo

1. Scrivi l'articolo fuori dal repository (strumento di scrittura personale). Quando è pronto:
   ```bash
   git checkout -b post/<slug> main
   hugo new -k blog content/it/blog/<slug-it>.md
   hugo new -k blog content/en/blog/<slug-en>.md
   ```
   (`-k blog` è necessario: senza l'archetype key, Hugo non popola `translationKey`/`tags` su contenuti multilingua.)
2. Incolla il contenuto nei due file. Allinea manualmente `translationKey` allo stesso valore in entrambi (gli slug diversi generano di default `translationKey` diversi). Imposta `draft: false` e `date` alla data corrente in entrambi.
3. **Regola editoriale**: le due versioni (IT + EN) escono sempre insieme, nella stessa pull request — non aprire una PR con una sola lingua di un articolo nuovo. Push del branch e apertura di una pull request verso `main`.
4. La CI della PR builda il sito, verifica i link interni, controlla che nessun contenuto sotto `content/` abbia `draft: true` o una `date` futura, e pubblica un'anteprima su Cloudflare Pages all'URL `post-<slug>.baicode-journal.pages.dev` (i caratteri non ammessi nel nome branch, come `/`, sono sostituiti con `-`).
5. Controlla l'anteprima. Quando sei soddisfatto, mergia: il merge innesca il deploy di produzione e l'articolo è online. Il branch si può cancellare dopo il merge.

Lo stesso flusso (branch → PR → anteprima → merge) vale per qualunque modifica al sito, non solo per i contenuti.

## Struttura

- `content/it/`, `content/en/` — articoli e pagine, uno per lingua
- `layouts/` — template Hugo custom (nessun tema di terze parti)
- `assets/css/` — CSS scritto a mano, nessun framework
- `scripts/` — script di supporto alla CI (es. guardrail sul front matter)
- `docs/adr/` — Architecture Decision Record di questo repository
- `docs/superpowers/specs/` — design doc del progetto

## Deploy

`.github/workflows/deploy.yml` reagisce sia a `push` su `main` (build di produzione, `hugo --gc --minify`, deploy su Cloudflare Pages) sia a `pull_request` verso `main` (build di anteprima con `--baseURL` puntato al dominio temporaneo, guardrail sul front matter, deploy di anteprima con `wrangler pages deploy --branch=<alias>`). In entrambi i casi la CI verifica i link interni con `htmltest` prima del deploy. I link esterni sono controllati settimanalmente da `.github/workflows/link-check-external.yml`, che apre una issue senza bloccare la pubblicazione.

### Setup una tantum di Cloudflare Pages

1. Crea un progetto Pages su Cloudflare (come progetto "direct upload", gestito solo da CI — non collegato direttamente al repo GitHub, per evitare un secondo trigger di deploy parallelo a quello della Action).
2. Aggiungi un record DNS CNAME `blog` → dominio assegnato da Cloudflare Pages, senza spostare i nameserver del dominio personale su Cloudflare.
3. Genera un API Token Cloudflare con permesso "Cloudflare Pages: Edit" e salvalo come secret `CLOUDFLARE_API_TOKEN` del repository GitHub.
4. Salva l'Account ID Cloudflare come secret `CLOUDFLARE_ACCOUNT_ID` del repository GitHub.
5. Aggiorna `baseURL` in `hugo.toml` e `params.homeURL` con i domini reali (blog e homepage) prima del primo deploy in produzione.

### Setup una tantum di GitHub

1. Proteggi il branch `main` (Settings → Branches → Branch protection rules): richiedi che il merge avvenga solo tramite pull request e che i check della CI (`build-and-deploy`) siano verdi prima di poter mergiare. Impedisce push diretti accidentali e rende uniforme il flusso di pubblicazione descritto sopra, anche con un solo autore.
```

- [ ] **Step 2: Verify the README references existing paths**

```bash
for f in docs/adr docs/superpowers/specs content/it content/en layouts assets/css scripts/check-content-guardrails.sh .github/workflows/deploy.yml .htmltest.yml; do
  test -e "$f" && echo "OK: $f" || echo "MISSING: $f"
done
```

Expected: every line prints `OK: ...`, none print `MISSING`.

- [ ] **Step 3: Commit**

```bash
git add readme.md
git commit -m "Rewrite README: PR-based publishing flow, preview deploy, GitHub setup"
```
