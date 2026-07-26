---
title: "Perché il mio blog non salva articoli in un database"
date: 2026-07-26
draft: false
translationKey: "post-why-my-blog-doesn-t-save-articles-in-a-database"
tags: ["statamic", "cms", "php"]
---

Una volta deciso di aprire il blog, dovevo iniziare a svilupparlo.

Foglio, carta, diagramma E/R. La carica di chi pensa: adesso me lo sviluppo da solo. La tentazione che abbiamo un po' tutti, noi sviluppatori.

È il classico progetto che sembra un weekend. Poi entri nel cuore della progettazione e arrivano editor, slug, versioning, preview, SEO, sitemap, RSS, gestione immagini, ricerca.

E l'effort diventa più di quanto potessi davvero dedicarci.

Regola generale, per me: non scrivere una riga di codice finché la progettazione non è finita.

L'opzione scontata sembrava WordPress. Probabilmente è il CMS più maturo che esista.

Ma significa rilasci ad hoc,stare dietro agli aggiornamento e patch sicurezza, sia core per gestione plugin, tema custom.

In più anche gestire un database comunque voluminoso alla sua installazione worpress installa il db bello pieno.

E io non volevo un progetto editoriale. Volevo un blog semplice con pochi articoli anno e tutti publicato da me non utente medio che ha bisogno di tutto i vantaggi funzioni che worpress ci dà gratis

Quindi ho scelto la soluzione meno ovvia, ma più efficace: un CMS flat file. Gli articoli sono file markdown. Si versionano, si spostano facilmente, non dipendono da un database.

Per articoli che una volta scritti cambiano poco, è la soluzione giusta. Con la cache impostata bene: zero query al database, caricamento immediato.

Uno dei punti che porta i parametri Core Web Vitals al massimo.

*\[nota editoriale: qui screenshot delle metriche*

*Il panora dei CMS flat file per quanto di nicchia e ricco di soluzioni affidabili.*

*Mantenendoci su PHP abbiamo Grav un CMS moderno, open source e altamente customizabille basato su TWING e symfony, ma non è l'unico anche PICO promettere stesse magie, senza pannello admin si modificano direttamente i file, ottimo per sito di documentazione o piccolissimo.*

*La generazione di siti statici l'ho scarta a priori perché preferivo un CMS con dashboard.*

La soluzione che ho individuato invece é Statamic.

Ho scelto Statamic perché non volevo costruire un CMS, ma nemmeno uscire dall'ecosistema Laravel."

Statamic ha un ottimo sistema di Blueprint, grazie al quale costruire  layout personalizzabili è veramente intuitivo e semplice, soprattutto Puoi customizzare per sezione.

Hai anche un controllo assoluto su ogni porzione di HTML, gestire SEO customizzando tag e metà tag ed anche creare tag specifici per condivisione sui social.

In pratica in un weekend ho rilasciato il mio blog, personalizzato e aggiornabile facilmente.

Da sviluppatori abbiamo spesso l'istinto di costruire tutto da zero. Ma scrivere codice non è sempre la scelta migliore.

A volte, la decisione migliore è evitare di scriverne.

---

La decisione in breve

Problema: dove pubblicare gli articoli del sito.

Alternative valutate: sviluppo custom, WordPress, Statamic.

Decisione: Statamic.

Perché: massimizza il valore, minimizza il codice da mantenere.

Trade-off: rinuncio a parte della flessibilità di una soluzione completamente custom.

Approfondimento tecnico: ADR-002 \+ tag Git v0.1-blog.
