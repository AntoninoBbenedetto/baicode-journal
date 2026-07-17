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
