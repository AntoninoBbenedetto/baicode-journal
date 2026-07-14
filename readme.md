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
hugo new -k blog content/it/blog/mio-articolo.md
hugo new -k blog content/en/blog/my-article.md
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
