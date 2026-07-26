---
title: "Why my blog doesn't save articles in a database"
date: 2026-07-26
draft: false
translationKey: "post-why-my-blog-doesn-t-save-articles-in-a-database"
tags: ["statamic", "cms", "php"]
---

Once I decided to start the blog, I had to begin building it.

Paper, pen, E/R diagram. The rush you get when you think: I'll build it myself. The temptation we developers all feel, at least a little.

It's the classic project that looks like a weekend job. Then you get into the heart of the design and in come editor, slugs, versioning, preview, SEO, sitemap, RSS, image management, search.

And the effort becomes more than I could really dedicate to it.

General rule, for me: don't write a line of code until the design is finished.

The obvious choice seemed to be WordPress. It's probably the most mature CMS out there.

But that means ad hoc releases, staying on top of updates and security patches, both core and for plugin management, custom theme.

Plus, it also means managing a database that's fairly bulky right from installation — WordPress installs the DB already pretty full.

And I didn't want an editorial project. I wanted a simple blog with a few articles a year, all published by me — not the average user who needs all the features and benefits that WordPress gives for free.

So I chose the less obvious but more effective solution: a flat-file CMS. Articles are markdown files. They're version-controlled, easy to move, and don't depend on a database.

For articles that change little once written, it's the right solution. With caching set up properly: zero database queries, instant loading.

One of the points that pushes Core Web Vitals metrics to the max.

![Screenshot of the PageSpeed Insights report for think.baicode.dev: 100/100 score for Performance, Accessibility, Best Practices, and SEO on mobile](/images/why-my-blog-doesn-t-save-articles-in-a-database/pagespeed-report.png)

*The flat-file CMS landscape, while niche, is rich with reliable solutions.*

*Sticking with PHP we have Grav, a modern, open source, and highly customizable CMS based on Twig and Symfony, but it's not the only one — PICO also promises the same magic, with no admin panel, editing files directly, great for a documentation site or a very small one.*

*I ruled out static site generators from the start because I wanted a CMS with a dashboard.*

The solution I found instead is Statamic.

I chose Statamic because I didn't want to build a CMS, but I also didn't want to leave the Laravel ecosystem.

Statamic has an excellent Blueprint system, thanks to which building customizable layouts is really intuitive and simple, and above all you can customize per section.

You also get absolute control over every piece of HTML, handling SEO by customizing tags and meta tags, and even creating specific tags for social sharing.

In practice, in one weekend I released my blog, customized and easy to update.

As developers we often have the instinct to build everything from scratch. But writing code isn't always the best choice.

Sometimes, the best decision is to avoid writing it.

---

The decision in brief

Problem: where to publish the site's articles.

Alternatives considered: custom development, WordPress, Statamic.

Decision: Statamic.

Why: maximizes value, minimizes code to maintain.

Trade-off: giving up some of the flexibility of a fully custom solution.

Technical deep dive: ADR-002 \+ Git tag v0.1-blog.
