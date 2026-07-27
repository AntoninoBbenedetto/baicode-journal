---
title: "Cosa deve davvero succedere prima di rispondere all'utente?"
date: 2026-07-27
draft: false
translationKey: "post-what-really-needs-to-happen-before-responding-to-the-user"
tags: ["architettura", "job-queue", "product-engineering"]
---

Qualche anno fa mio cognato mi chiese di realizzare un piccolo e-commerce. L'idea era semplice: vendere online lo stomatico artigianale che produceva. Pochi prodotti, un checkout essenziale, lo scontrino stampato e infilato direttamente nel pacco.

Fine.

## Un'architettura volutamente semplice

In quel momento non c'era nessun motivo per complicare l'architettura. Ogni richiesta iniziava e finiva nello stesso punto: l'utente confermava l'ordine, l'applicazione completava tutte le operazioni, la risposta tornava immediatamente.

**Era esattamente quello di cui il progetto aveva bisogno.**

Poi, come succede spesso, il prodotto ha iniziato a crescere.

## La prima richiesta: automatizzare le fatture

Un giorno mio cognato mi chiamò con una richiesta che sembrava banale. «Ma le fatture non possiamo farle creare automaticamente? Ormai gli ordini sono tanti e farle una a una mi porta via troppo tempo.»

La richiesta aveva perfettamente senso. **La soluzione, però, non era ancora una coda di lavoro.**

Il primo compromesso fu molto più semplice: l'ordine continuava a essere confermato subito, la fattura veniva generata durante la notte e resa disponibile il giorno dopo nell'area riservata. Per lui il lavoro manuale spariva. Per gli utenti non cambiava quasi nulla. E l'architettura restava semplice.

Pensavo che sarebbe bastato.

Mi sbagliavo.

## Dicembre, e l'arma segreta di mio cognato

Arrivò dicembre. Gli ordini aumentarono, e le richieste anche. Soprattutto, entrò in scena la sua arma segreta: mia nipote Matilde. Invece di chiamarmi, iniziò a mandare lei. Era impossibile dirle di no.

Tra una richiesta e l'altra arrivarono nuove esigenze. Notifiche. Punti fedeltà. Pagamenti ricorrenti. Operazioni che fino a pochi mesi prima non esistevano.

Ed è lì che ho capito che il problema non era più automatizzare una singola operazione. **Il prodotto stava cambiando.**

## La domanda cambia

La domanda non era più "come faccio a eseguire tutto?".

Era diventata un'altra: **cosa deve davvero succedere prima di poter rispondere all'utente?**

La verifica della disponibilità doveva restare immediata. Il pagamento anche. Ma la fattura? Il calcolo dei punti? L'invio delle notifiche? Quelle operazioni potevano aspettare qualche secondo.

È stato in quel momento che ho iniziato a ragionare sulle code di lavoro. Non perché fossero la soluzione più moderna, ma perché il prodotto era finalmente cresciuto abbastanza da giustificarne la complessità.

## Il prezzo della reattività

Da quel momento il flusso dell'applicazione non è più stato lineare. In cambio di un sistema più reattivo, ho dovuto iniziare a gestire problemi nuovi: task eseguiti due volte, errori da ritentare, operazioni che potevano fallire senza che l'utente se ne accorgesse, consistenza temporanea dei dati.

**Tutti problemi risolvibili. Ma problemi che, fino al giorno prima, semplicemente non esistevano.**

## La domanda che mi faccio oggi

Da allora, ogni volta che qualcuno propone di introdurre una coda di lavoro, non mi chiedo quale tecnologia utilizzare. Mi faccio una domanda molto più semplice.

**Questa operazione deve davvero terminare prima di rispondere all'utente?**

Perché la parte difficile della programmazione asincrona non è implementarla. **È capire quando la complessità che introduce è davvero il prezzo giusto da pagare.**
