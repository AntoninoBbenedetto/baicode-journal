# Design: strategia di pubblicazione dei contenuti

Data: 2026-07-14

## Contesto

Il design del blog (`2026-07-11-blog-design.md`) e il relativo piano di implementazione definiscono già la pipeline di deploy: push su `main` → build Hugo → controllo link interni con htmltest (bloccante) → `wrangler pages deploy` verso Cloudflare Pages. Non definiscono però **come un articolo arriva su `main`**: il flusso di lavoro dell'autore dal contenuto finito alla pubblicazione online.

Questo design colma quel vuoto. Requisiti raccolti:

- L'autore vuole vedere l'articolo renderizzato su un **URL di anteprima temporaneo** prima che vada online.
- Le due versioni linguistiche di un articolo (IT + EN) escono **insieme, nella stessa pull request**.
- Le bozze vivono **fuori dal repository** (strumenti di scrittura personali): nel repo entra solo l'articolo finito. I branch di contenuto sono quindi a vita breve.
- **Il merge è l'atto di pubblicazione**: appena la PR viene mergiata, l'articolo è online. Nessuna pubblicazione programmata, nessun workflow schedulato di rebuild.

## 1. Flusso di pubblicazione

1. L'articolo si scrive fuori dal repo. Quando è pronto, si stacca un branch `post/<slug>` da `main`.
2. Nel branch si creano i due file con `hugo new content/it/blog/<slug-it>.md` e `hugo new content/en/blog/<slug-en>.md` (archetype esistente), si allinea `translationKey` allo stesso valore in entrambi, si incolla il contenuto, si imposta `draft: false` e `date` alla data corrente.
3. Push del branch e apertura della PR verso `main`.
4. La CI della PR esegue, in ordine e in modo bloccante:
   - build Hugo;
   - controllo dei link interni con htmltest;
   - guardrail sul front matter (sezione 2);
   - deploy di **anteprima** su Cloudflare Pages: `wrangler pages deploy public --branch=post/<slug>`, che produce l'URL temporaneo `post-<slug>.baicode-journal.pages.dev` (alias di branch di Cloudflare Pages, con i caratteri non ammessi del nome branch normalizzati da Cloudflare). La build di anteprima passa a Hugo `--baseURL` puntato a quell'URL, così link assoluti, RSS e sitemap dell'anteprima restano navigabili.
5. L'autore controlla l'anteprima e mergia quando è soddisfatto. Il merge innesca il workflow di produzione già previsto (push su `main`), che pubblica l'articolo. Il branch si cancella al merge.

Lo stesso flusso vale per qualunque modifica al sito (layout, CSS, config): la PR ottiene comunque build, link check e anteprima. Non serve distinguere "PR di contenuto" da "PR di codice".

## 2. Guardrail in CI sulla PR (bloccanti)

Con "merge = pubblicazione" e nessuna build schedulata, un articolo con `date` nel futuro verrebbe **silenziosamente escluso** dalla build di produzione (comportamento di default di Hugo) e non comparirebbe mai, perché nessuna build successiva avverrebbe dopo la maturazione della data. Stesso rischio per un `draft: true` dimenticato.

La CI della PR quindi **fallisce** se un file sotto `content/` ha:

- `date` nel futuro rispetto al momento del check, oppure
- `draft: true`.

Il controllo è un piccolo script nel workflow (nessuna dipendenza esterna: il front matter è leggibile con gli strumenti già presenti nel runner). L'allineamento di `translationKey` tra le coppie IT/EN **non** viene verificato in CI: non è controllabile in modo affidabile senza imporre convenzioni rigide sui nomi file; resta un passo della checklist nel README.

A livello di repository, `main` è protetto: si mergia solo via PR con CI verde. L'autore è singolo e si auto-approva; il vincolo serve a impedire push diretti accidentali e a rendere il flusso uniforme.

## 3. Modifiche rispetto al piano esistente

- **`.github/workflows/deploy.yml`** (Task 6 del piano, non ancora implementato): al trigger `push` su `main` si aggiunge il trigger `pull_request`. Gli step di installazione Hugo, build e htmltest sono comuni; cambiano per la PR il `--baseURL` (URL di anteprima invece di produzione), il flag `--branch` del deploy wrangler e l'aggiunta dello step di guardrail sul front matter. Le PR provengono sempre da branch dello stesso repository (autore singolo), quindi i secret Cloudflare sono disponibili anche nelle build di PR; eventuali PR da fork non avrebbero i secret e fallirebbero il deploy di anteprima — accettabile, non è un caso d'uso previsto.
- **README** (Task 8 del piano): la sezione "Pubblicare un articolo" descrive il flusso branch → PR → anteprima → merge, inclusa la checklist manuale (allineare `translationKey`, `draft: false`, `date` corrente).
- **ADR-004** — *Pubblicazione via pull request con anteprima; il merge è l'atto di pubblicazione*: documenta la decisione e le alternative scartate: branch `content` persistente (diverge da `main`, pubblicare un solo articolo richiede cherry-pick, e con le bozze fuori dal repo non custodisce nulla), commit diretto su `main` (nessun URL di anteprima), pubblicazione programmata via cron (infrastruttura in più per un'esigenza non prioritaria; rinunciarvi elimina anche lo stato "mergiato ma non ancora visibile").

## 4. Casi limite e rimedi

- **Errore in un articolo già pubblicato**: fix con una nuova PR (o revert del merge su `main`); il push risultante ripubblica il sito corretto.
- **Anteprime accumulate su Cloudflare Pages**: i deployment di anteprima restano sul dominio `pages.dev`, non indicizzati e senza costi; nessuna pulizia automatica necessaria.
- **Articolo in una sola lingua**: il flusso non lo vieta tecnicamente (la CI non impone la coppia IT/EN), ma la regola editoriale è "insieme, stessa PR"; il layout gestisce già esplicitamente la traduzione mancante (design 2026-07-11, sezione 2).

## Fuori scope

- Pubblicazione programmata (date future + rebuild schedulato): scartata esplicitamente; riaggiungerla in futuro significherebbe rimuovere il guardrail sulla data e aggiungere un workflow cron, senza altri cambi strutturali.
- Workflow editoriali multi-autore, review di terzi, code owner.
- Automazioni sulla scrittura (generazione bozze, traduzione automatica IT→EN).
