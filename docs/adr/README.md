# Architecture Decision Records

Ogni decisione architetturale significativa di questo repository è documentata come ADR, seguendo il formato di [template.md](template.md): contesto → decisione → alternative scartate → conseguenze.

## Convenzioni

- **File**: `NNN-slug.md`, numerazione progressiva a tre cifre (es. `001-contenuti-flat-file.md`).
- **Lingua**: italiano.
- **Stati**: `proposta` → `accettata` → `superata da [ADR-NNN]`.
- **Immutabilità**: una ADR accettata non si riscrive. Se la decisione cambia, si scrive una nuova ADR che la supera e si aggiorna lo stato della vecchia con il link alla nuova.

## Indice

| N | Titolo | Stato | Data |
|---|--------|-------|------|
| 001 | [Contenuti flat-file versionati in git](001-contenuti-flat-file.md) | accettata | 2026-07-14 |
| 002 | [Hugo come generatore del sito](002-hugo-come-generatore.md) | accettata | 2026-07-14 |
| 003 | [Hosting su Cloudflare Pages](003-hosting-cloudflare-pages.md) | accettata | 2026-07-14 |
| 004 | [Pubblicazione via pull request con anteprima](004-pubblicazione-pr-anteprima.md) | accettata | 2026-07-14 |
