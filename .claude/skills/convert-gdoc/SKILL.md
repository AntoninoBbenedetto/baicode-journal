---
name: convert-gdoc
description: Convert a Google Docs Markdown export into a bilingual (IT/EN) baicode journal blog post — frontmatter, translationKey, mechanical cleanup, translation, and a post/<slug> branch. Use when the user asks to turn a Google Docs export, or a raw .md draft written in Google Docs, into a blog article.
---

# Convert Google Docs export to blog post

Converts a single-language Markdown file exported from Google Docs ("File → Download → Markdown") into the `content/it/blog/<slug>.md` + `content/en/blog/<slug>.md` pair this site requires, on a dedicated `post/<slug>` branch, ready for the PR flow described in `readme.md` ("Pubblicare un articolo").

Invoked as `/convert-gdoc <path-to-exported-file>`.

Design reference: `docs/superpowers/specs/2026-07-17-convert-gdoc-skill-design.md`. Publishing rules this skill must satisfy: `docs/superpowers/specs/2026-07-14-content-publishing-design.md`.

## Step 0 — Validate input

- If no path argument was given, or the path does not exist, or it does not end in `.md`, stop and tell the user what's wrong. Do not proceed.

## Step 1 — Image guard

Before anything else, scan the source file:

- Search for Markdown image syntax: `![...](...)`.
- Check whether a sibling asset folder exists next to the source file, matching the common Google Docs export conventions: `<basename>_files/` or `images/` in the same directory as the source file.

If either is found: stop immediately. Tell the user this skill does not yet handle images (no image pipeline exists in this repo — see "Fuori scope" in the design doc), and that they should either strip the images from the source Google Doc and re-export, or wait for a dedicated image-handling design. Do not create any files, do not create a branch.

If the file is text-only, continue to Step 2.

## Step 2 — Source-language title and slug

- Read the file. If the first non-blank line is a Markdown H1 (`# ...`), that text is the proposed title, and that line is removed from the body (it will become frontmatter `title`, not body content).
- If there is no H1, propose a title derived from the source filename instead: strip the `.md` extension, replace underscores with spaces, strip a trailing run of punctuation/whitespace left over from Google Docs' filename sanitization (e.g. a trailing `.` or `_`), and trim. Never derive the title from the first paragraph of body text.
- Show the proposed title to the user and ask them to confirm or correct it.
- Propose a slug for the source language: lowercase the confirmed title, transliterate common Italian accented vowels to their unaccented form (à/á→a, è/é→e, ì/í→i, ò/ó→o, ù/ú→u, and uppercase equivalents) — e.g. "perché" → "perche" — then replace any run of remaining characters that are not `a-z0-9` with a single `-` (this also hyphenates apostrophes in contractions, e.g. `l'articolo` → `l-articolo` — intentional, not an oversight), strip leading/trailing `-`. Show it and ask the user to confirm or correct it.
- Ask the user for `tags` (default: empty list `[]`) and `date` (default: today's date, `YYYY-MM-DD`). If the user supplies a future date, warn them explicitly: "La CI della PR rifiuta contenuti con `date` futura (guardrail bloccante) — questa data farebbe fallire la pubblicazione finché non la aggiorni." Do not refuse to proceed — it's the user's call.

## Step 3 — Mechanical cleanup (source language)

Apply only these mechanical fixes to the body (title line already removed in Step 2):

1. Replace any non-breaking space character (U+00A0) with a normal space.
2. Remove auto-generated anchor/table-of-contents links: a Markdown link whose target is a same-document anchor (`[text](#some-anchor)`) that does not correspond to any heading actually kept in the body.
3. Remove orphaned footnote markers: a numeric reference marker (e.g. `[1]`, `¹`) with no corresponding footnote definition left in the body.
4. Collapse runs of more than one consecutive blank line into exactly one blank line.
5. Strip redundant bold markup inside headings: a heading line of the form `## **Text**` or `### **Text**` becomes `## Text` / `### Text`. This is Google Docs re-exporting the same "Heading" style as both structural markup and inline bold — duplicate information, not an authorial choice.

Do **not** touch: bold/italics in body text outside headings, `---` used as a section divider, heading structure/levels themselves (beyond rule 5's bold-stripping), bullet lists, em-dashes or other intentional typographic punctuation, or paragraph length/rhythm (short, one-sentence paragraphs are a legitimate authorial style here, not something to merge). Do not rewrite, rephrase, or "improve" the author's prose — only apply rules 1–5 above.

## Step 4 — Translation

Translate the cleaned title and body into the other language (IT↔EN), preserving structure exactly: same headings in the same order, same paragraph/list breaks, same use of `---` dividers if the original has them. This is a same-conversation assisted translation, not a call to an external translation API.

- Propose a slug for the translated title using the same slugification rule as Step 2.
- Show both the source-language content (after Step 3 cleanup) and the translated content to the user, in full, before writing anything to disk. Explicitly ask for confirmation — the translation must be reviewed before it's treated as final.

## Step 5 — Final metadata confirmation and collision check

Determine which of the two slugs (source or destination) is the English one; call it `<slug-en>`. Compute `translationKey` as `post-<slug-en>`.

Show the user a summary: both filenames (`content/it/blog/<slug-it>.md`, `content/en/blog/<slug-en>.md`), `translationKey`, `tags`, `date`. Then check:

```bash
test -e content/it/blog/<slug-it>.md && echo "CONFLICT: content/it/blog/<slug-it>.md already exists"
test -e content/en/blog/<slug-en>.md && echo "CONFLICT: content/en/blog/<slug-en>.md already exists"
grep -rl "translationKey: \"post-<slug-en>\"" content/ && echo "CONFLICT: translationKey post-<slug-en> already in use"
```

If any conflict is reported, tell the user and ask for a different slug (go back to Step 2/4 as needed) instead of overwriting anything.

## Step 6 — Branch

Check whether the branch already exists:

```bash
git rev-parse --verify post/<slug-en> 2>/dev/null && echo "BRANCH EXISTS"
```

If it exists, stop and tell the user — do not reuse or delete it. Otherwise:

```bash
git checkout -b post/<slug-en> main
```

## Step 7 — Write files

Write both files with complete front matter. Example shape (values are placeholders for the actual confirmed data):

```markdown
---
title: "<confirmed title>"
date: <YYYY-MM-DD>
draft: false
translationKey: "post-<slug-en>"
tags: ["<tag1>", "<tag2>"]
---

<cleaned / translated body>
```

`draft` is always `false` and `date` is always the confirmed date (default today) — never `draft: true`. This matches the publishing flow's own file-creation step (`docs/superpowers/specs/2026-07-14-content-publishing-design.md`, §1 step 2): the PR guardrail rejects `draft: true` or a future `date`, so there is no reason to hand the user a file that would fail it.

Write:
- `content/it/blog/<slug-it>.md`
- `content/en/blog/<slug-en>.md`

## Step 8 — Stop here

Do not run `git add`, `git commit`, `git push`, or open a pull request. Tell the user the two files are written on branch `post/<slug-en>` and that committing/pushing/opening the PR is the next manual step (`readme.md`, "Pubblicare un articolo").
