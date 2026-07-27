---
title: "What Really Needs to Happen Before Responding to the User?"
date: 2026-07-27
draft: false
translationKey: "post-what-really-needs-to-happen-before-responding-to-the-user"
tags: ["architettura", "job-queue", "product-engineering"]
---

A few years ago my brother-in-law asked me to build a small e-commerce site. The idea was simple: sell online the artisanal digestive liqueur he made. A handful of products, a bare-bones checkout, the receipt printed and slipped straight into the package.

That's it.

## A deliberately simple architecture

At that point there was no reason to complicate the architecture. Every request started and ended in the same place: the user confirmed the order, the application completed every operation, the response came back immediately.

**It was exactly what the project needed.**

Then, as often happens, the product started to grow.

## The first request: automating invoices

One day my brother-in-law called me with a request that sounded trivial. "Can't we have invoices generated automatically? Orders keep piling up and doing them one by one is eating up too much of my time."

The request made perfect sense. **The solution, though, wasn't a job queue yet.**

The first compromise was much simpler: the order was still confirmed instantly, the invoice was generated overnight and made available the next day in the account area. For him, the manual work disappeared. For users, almost nothing changed. And the architecture stayed simple.

I thought that would be enough.

I was wrong.

## December, and my brother-in-law's secret weapon

December arrived. Orders increased, and so did the requests. Above all, his secret weapon entered the scene: my niece Matilde. Instead of calling me himself, he started sending her. It was impossible to say no to her.

Between one request and the next, new needs kept coming. Notifications. Loyalty points. Recurring payments. Operations that hadn't existed just a few months earlier.

That's when I understood the problem was no longer automating a single operation. **The product itself was changing.**

## The question changes

The question was no longer "how do I get everything done?"

It had become a different one: **what really needs to happen before I can respond to the user?**

Checking availability had to stay immediate. So did the payment. But the invoice? The points calculation? Sending notifications? Those operations could wait a few seconds.

That's when I started thinking seriously about job queues. Not because they were the trendiest solution, but because the product had finally grown enough to justify the complexity.

## The price of responsiveness

From that point on, the application's flow was no longer linear. In exchange for a more responsive system, I had to start dealing with new problems: tasks executed twice, errors that needed retrying, operations that could fail without the user ever noticing, temporary data inconsistency.

**All solvable problems. But problems that, until the day before, simply didn't exist.**

## The question I ask myself today

Since then, every time someone proposes introducing a job queue, I don't ask myself which technology to use. I ask myself a much simpler question.

**Does this operation really need to finish before I respond to the user?**

Because the hard part of asynchronous programming isn't implementing it. **It's understanding when the complexity it introduces is truly the right price to pay.**
