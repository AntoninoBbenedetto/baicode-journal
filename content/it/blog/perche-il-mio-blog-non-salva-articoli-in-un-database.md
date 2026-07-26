---
title: "Perché il mio blog non salva articoli in un database"
date: 2026-07-26
draft: false
translationKey: "post-why-my-blog-doesn-t-save-articles-in-a-database"
tags: ["hugo", "cms", "static-site"]
---

Una volta deciso di aprire il blog, dovevo iniziare a svilupparlo.

Foglio, carta, diagramma E/R. La carica di chi pensa: adesso me lo sviluppo da solo. La tentazione che abbiamo un po' tutti, noi sviluppatori.

È il classico progetto che sembra un weekend. Poi entri nel cuore della progettazione e arrivano editor, slug, versioning, preview, SEO, sitemap, RSS, gestione immagini, ricerca.

E l'effort diventa più di quanto potessi davvero dedicarci.

Regola generale, per me: non scrivere una riga di codice finché la progettazione non è finita.

L'opzione scontata sembrava WordPress. Probabilmente è il CMS più maturo che esista.

Ma significa rilasci ad hoc, stare dietro agli aggiornamenti e patch di sicurezza, sia del core che della gestione plugin e tema custom.

In più c'è comunque un database da gestire: già alla sua installazione, WordPress porta con sé un db tutt'altro che vuoto.

E io non volevo un progetto editoriale. Volevo un blog semplice, con pochi articoli l'anno, pubblicati tutti da me — non l'utente medio che ha bisogno di tutti i vantaggi che WordPress offre gratis.

Quindi ho scartato l'idea di un database fin da subito. Gli articoli sono file markdown. Si versionano, si spostano facilmente, non dipendono da un database.

Per articoli che una volta scritti cambiano poco, è la soluzione giusta. Zero query, contenuto già pronto in fase di build: caricamento immediato.

Uno dei punti che porta i parametri Core Web Vitals al massimo.

![Screenshot del report PageSpeed Insights per think.baicode.dev: punteggio 100/100 in Prestazioni, Accessibilità, Best Practice e SEO su mobile](/images/why-my-blog-doesn-t-save-articles-in-a-database/pagespeed-report.png)

*Il primo istinto, con contenuti in markdown, è stato cercare un CMS flat file con dashboard: mantenendoci su PHP c'è Grav, moderno e altamente customizzabile su Twig e Symfony; oppure Pico, ancora più minimale — niente pannello admin, si editano i file direttamente, ottimo per un sito di documentazione o un progetto piccolissimo.*

*Ma un pannello admin, per un solo autore tecnico che scrive pochi articoli l'anno e sa già usare git, è un costo — non un vantaggio. Se l'unico "utente" del CMS sono io, e mi sta bene aprire un editor invece di un browser, il pannello diventa superfluo.*

Tolto di mezzo il vincolo del dashboard, la strada si è aperta verso i generatori di siti statici. Content in git, build che produce HTML, deploy di file statici: niente da far girare, niente da patchare.

Ho valutato Astro: le content collections validano il frontmatter contro uno schema già in fase di build, cosa che a un CMS flat file puro manca. Ma ogni build richiede comunque una toolchain Node — `node_modules`, aggiornamenti, superficie di breaking change. Un costo ricorrente e certo, a fronte di un beneficio puntuale che si può ottenere anche altrimenti, ad esempio con un controllo in CI.

Ho valutato anche Statamic in modalità export statico: stack che conosco bene, essendo Laravel, ma la toolchain di build resta comunque un'applicazione Laravel completa — PHP, Composer, aggiornamenti del framework da seguire. Lo stesso compromesso di Astro, aggravato dal fatto che il suo punto di forza, il pannello admin, è proprio quello che avevo già scartato.

La soluzione che ho individuato invece è **Hugo**.

Un binario Go singolo: nessuna dipendenza Node da mantenere, nessun `npm install` prima di ogni build. Il multilingua è nativo, non un plugin o una convenzione da rispettare a mano — e per me, che scrivo in italiano e inglese, è un requisito, non un vezzo. RSS e sitemap per lingua arrivano già pronti, senza configurazione ad hoc. Il syntax highlighting (Chroma) è incluso nel core.

Ho scelto anche di non usare temi di terze parti: molti temi Hugo si portano dietro una propria toolchain Node/PostCSS per lo styling, reintroducendo esattamente ciò che volevo evitare scegliendo Hugo. Il layout è custom e minimale — home, lista post, articolo singolo, pagina tag — poco codice per un blog di poche viste. Stessa logica per il CSS: scritto a mano, senza Tailwind, perché per 3-4 template il beneficio delle utility class non giustifica una toolchain Node in più. La minificazione in produzione usa la pipeline nativa di Hugo.

In pratica in un weekend ho rilasciato il mio blog, personalizzato e con una build riproducibile ovunque: aggiornare la toolchain, in futuro, significherà solo sostituire un eseguibile.

Da sviluppatori abbiamo spesso l'istinto di costruire tutto da zero. Ma scrivere codice non è sempre la scelta migliore — a volte nemmeno installarne uno con un pannello di controllo lo è, se quel pannello lo aprirò io soltanto.

A volte, la decisione migliore è ridurre le parti in movimento.

---

# La decisione in breve

**Problema: dove pubblicare gli articoli del sito, e con quale strumento generarli.**

Alternative valutate: sviluppo custom, WordPress, CMS flat file con dashboard (Grav/Pico), Astro, Statamic (export statico), Hugo.

**Decisione: Hugo.**

Perché: nessuna toolchain da mantenere tra una pubblicazione e l'altra, i18n/RSS/sitemap nativi, superficie di dipendenze minima.

Trade-off: nessuna validazione dello schema del frontmatter in fase di build; curva di apprendimento del templating Go; nessun tema a monte da cui ricevere fix — tutta la manutenzione di HTML e CSS resta in carico al repo.

Approfondimento tecnico: ADR-001 (contenuti flat file) + ADR-002 (Hugo come generatore) + tag Git v0.1-blog.
