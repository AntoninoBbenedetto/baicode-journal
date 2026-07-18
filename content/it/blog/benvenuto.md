---
title: "Benvenuto su baicode journal"
date: 2026-07-11
draft: true
translationKey: "post-welcome"
tags: ["meta"]
---

Questo blog nasce per rendere pubblico un modo di ragionare, non un elenco di tecnologie. Ogni articolo racconterà una decisione tecnica reale: il problema, le alternative valutate, la scelta fatta, i compromessi accettati.

Il primo esempio, piccolo e concreto — l'intera pipeline di questo sito è generata da un singolo binario:

```bash
hugo --gc --minify
```

Nessun database, nessuna dipendenza Node per il core: il contenuto è testo versionato in git, come il codice di cui parla.
