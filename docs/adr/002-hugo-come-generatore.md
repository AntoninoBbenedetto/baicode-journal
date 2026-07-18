# ADR-002: Hugo come generatore del sito

- **Stato**: accettata
- **Data**: 2026-07-14

## Contesto

Decisa la forma dei contenuti — file Markdown versionati in git ([ADR-001](001-contenuti-flat-file.md)) — serve lo strumento che li trasforma in sito statico. I requisiti che pesano sulla scelta:

- **bilingue IT/EN come funzione nativa**, non come plugin o convenzione fragile;
- **RSS e sitemap per lingua**, senza configurazione ad hoc;
- **minima superficie di dipendenze da mantenere**: il sito cambia solo quando si pubblica, e la toolchain non deve chiedere lavoro (aggiornamenti, vulnerabilità, breaking change) nel frattempo.

L'autore non ha uno "stack di casa" tra i generatori statici (PHP/Laravel nel lavoro quotidiano, Go in apprendimento): la scelta è libera di seguire solo il problema.

## Decisione

Il sito è generato con [Hugo](https://gohugo.io): binario Go singolo, zero dipendenze Node, multilingual mode nativo, RSS/sitemap e syntax highlighting (Chroma) inclusi nel core, build veloci.

Dallo stesso vincolo — nessuna toolchain Node da mantenere — seguono due corollari:

- **Nessun tema di terze parti.** Molti temi Hugo impacchettano una propria toolchain Node/PostCSS per lo styling, reintroducendo esattamente ciò che la scelta di Hugo vuole evitare. Il layout è custom e minimale — home, lista post, articolo singolo, pagina tag — cioè poco codice per un blog di poche viste.
- **CSS scritto a mano, niente Tailwind.** Da Hugo v0.161.0 l'integrazione nativa `css.TailwindCSS` richiede Tailwind installato via npm (il supporto al binario standalone è stato rimosso). Per 3-4 viste il beneficio delle utility class non giustifica una toolchain Node. La minificazione in produzione usa la pipeline nativa di Hugo (`resources.Minify`), inclusa nel core.

## Alternative scartate

### Astro

Il suo punto di forza è reale: le content collections validano il frontmatter contro uno schema in fase di build, colmando esattamente la lacuna accettata in ADR-001. In cambio, ogni build richiede la toolchain Node — `node_modules`, aggiornamenti di dipendenze, superficie di breaking change. Scartato per asimmetria tra costi e benefici: la manutenzione della toolchain è ricorrente e certa, il beneficio della validazione è puntuale e mitigabile in altro modo (es. un check in CI).

### Statamic (in modalità SSG)

In [ADR-001](001-contenuti-flat-file.md) Statamic era stato scartato come piattaforma di serving, rimandando a questa ADR la valutazione come generatore. Anche usando l'export statico (`statamic/ssg`), la toolchain di build resta un'applicazione Laravel completa: PHP, Composer, aggiornamenti del framework. Pro: stack familiare all'autore e pannello admin per l'editing. Scartato per la stessa asimmetria di Astro, amplificata: il costo di manutenzione è ricorrente e più pesante, mentre il beneficio principale — il pannello admin — è già stato giudicato superfluo per un singolo autore tecnico in ADR-001.

## Conseguenze

Diventa più facile:

- build riproducibile ovunque con un solo binario: la CI è banale e aggiornare la toolchain significa sostituire un eseguibile;
- i18n, RSS, sitemap e syntax highlighting senza plugin né dipendenze aggiuntive;
- nessuna manutenzione ricorrente della toolchain tra una pubblicazione e l'altra.

Diventa più difficile:

- il frontmatter resta senza validazione a schema: lacuna nota da ADR-001, mitigabile in futuro con un check in CI;
- il templating di Hugo (Go template) ha una curva di apprendimento propria;
- con il layout custom, tutta la manutenzione di HTML e CSS è in carico a questo repo: nessun tema a monte da cui ricevere fix o migliorie.
