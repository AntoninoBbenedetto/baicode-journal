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
