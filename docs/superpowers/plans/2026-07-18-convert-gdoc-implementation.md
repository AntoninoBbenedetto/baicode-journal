# Convert Google Docs Export to Blog Post — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the skill described in `docs/superpowers/specs/2026-07-17-convert-gdoc-skill-design.md`: a project skill, `/convert-gdoc <path>`, that turns a single-language Google Docs Markdown export into the `content/it/blog/<slug>.md` + `content/en/blog/<slug>.md` pair this site requires, on a fresh `post/<slug>` branch, ready for the existing PR flow.

**Architecture:** A single project skill file, `.claude/skills/convert-gdoc/SKILL.md`, containing the full interactive procedure (image guard, title/slug extraction, mechanical cleanup, translation, collision checks, branch creation, file writing). There is no separate script or library — the "implementation" is the instruction file itself, since the transformation requires judgment (naming, translation quality, what counts as an artifact) rather than pure mechanics, per the design's explicit choice of a skill over a deterministic script.

**Tech Stack:** Claude Code project skill (Markdown + YAML frontmatter), git, Hugo content conventions already established in this repo (no new dependency).

## Global Constraints

- No automated test suite in this repo (existing project convention). Every verification step here is a manual/scripted walkthrough with expected-output assertions (`grep`, `test -f`, literal invocation of the skill), not a persisted test framework.
- Translation quality itself cannot be asserted by a script — where a verification step involves reading translated prose, the step says so explicitly and describes what to look for; it is a qualitative read, not a `grep`.
- The skill must never run `git add`, `git commit`, `git push`, or open a PR — it stops after creating the branch and writing the two content files (spec §6–§8).
- Generated content files must always have `draft: false` and a confirmed `date` (default today) — never `draft: true` — because `scripts/check-content-guardrails.sh` (wired into `.github/workflows/deploy.yml`) rejects both on the PR that would eventually be opened from this branch (spec §3, §7; `2026-07-14-content-publishing-design.md` §2).
- Image references or an associated asset folder (`<basename>_files/`, `images/`) next to the source export must halt the skill before any file or branch is created — no image pipeline exists in this repo yet (spec §2, §8).
- The skill file itself is written in English, matching this repo's existing convention for tooling (`scripts/check-content-guardrails.sh`, workflow YAML). This does not change what language Claude converses in with the user when the skill runs.
- The skill lives at exactly `.claude/skills/convert-gdoc/SKILL.md` and is invoked as `/convert-gdoc <path-to-exported-file>` (spec §1).
- Verification tasks in this plan create real git branches and content files as part of testing the skill end-to-end; each such task cleans up everything it created (deletes the test branch, deletes generated files, returns to the branch the task started on) so the working tree is left exactly as it was found.

---

## Task 1: Write the convert-gdoc skill

**Files:**
- Create: `.claude/skills/convert-gdoc/SKILL.md`

**Interfaces:**
- Produces: a project skill invocable as `/convert-gdoc <path-to-exported-file>`, frontmatter `name: convert-gdoc`. Consumed directly (by invocation) in Tasks 2–4 of this plan, and by the user in real future use.

- [ ] **Step 1: Create the skill directory and write the file**

```bash
mkdir -p .claude/skills/convert-gdoc
```

`.claude/skills/convert-gdoc/SKILL.md`:
```markdown
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
- Propose a slug for the source language: lowercase the confirmed title, replace any run of characters that are not `a-z0-9` with a single `-`, strip leading/trailing `-`. Show it and ask the user to confirm or correct it.
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
tags: [<tags>]
---

<cleaned / translated body>
```

`draft` is always `false` and `date` is always the confirmed date (default today) — never `draft: true`. This matches the publishing flow's own file-creation step (`docs/superpowers/specs/2026-07-14-content-publishing-design.md`, §1 step 2): the PR guardrail rejects `draft: true` or a future `date`, so there is no reason to hand the user a file that would fail it.

Write:
- `content/it/blog/<slug-it>.md`
- `content/en/blog/<slug-en>.md`

## Step 8 — Stop here

Do not run `git add`, `git commit`, `git push`, or open a pull request. Tell the user the two files are written on branch `post/<slug-en>` and that committing/pushing/opening the PR is the next manual step (`readme.md`, "Pubblicare un articolo").
```

- [ ] **Step 2: Verify structural content of the skill file**

```bash
test -f .claude/skills/convert-gdoc/SKILL.md && echo "file exists OK"
grep -q '^name: convert-gdoc$' .claude/skills/convert-gdoc/SKILL.md && echo "frontmatter name OK"
grep -q '/convert-gdoc <path-to-exported-file>' .claude/skills/convert-gdoc/SKILL.md && echo "invocation form OK"
grep -q '## Step 1 — Image guard' .claude/skills/convert-gdoc/SKILL.md && echo "image guard step OK"
grep -q '## Step 5 — Final metadata confirmation and collision check' .claude/skills/convert-gdoc/SKILL.md && echo "collision check step OK"
grep -q '## Step 6 — Branch' .claude/skills/convert-gdoc/SKILL.md && echo "branch step OK"
grep -q 'draft` is always `false`' .claude/skills/convert-gdoc/SKILL.md && echo "draft:false rule OK"
grep -q 'Strip redundant bold markup inside headings' .claude/skills/convert-gdoc/SKILL.md && echo "bold-heading cleanup rule OK"
grep -q 'Do not run `git add`, `git commit`, `git push`' .claude/skills/convert-gdoc/SKILL.md && echo "no-commit rule OK"
```

Expected: nine lines, each ending in `OK`, all printed.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/convert-gdoc/SKILL.md
git commit -m "Add convert-gdoc skill: Google Docs export to bilingual blog post"
```

---

## Task 2: Verify against fixture with H1 (`Antonino_Benedetto_Presentazione.md`)

**Files:**
- None created or modified permanently — this task exercises Task 1's skill against a real fixture and cleans up afterward.

**Interfaces:**
- Consumes: `.claude/skills/convert-gdoc/SKILL.md` (Task 1); `docs/Antonino_Benedetto_Presentazione.md` (existing fixture, has an H1 and `---`-separated H2 sections, no images).

- [ ] **Step 1: Record the starting branch**

```bash
original_branch=$(git branch --show-current)
echo "starting branch: $original_branch"
git status --short
```

Expected: prints the current branch name (e.g. `feat/update-design`) and an empty or already-known status (no stray uncommitted changes beyond what you expect).

- [ ] **Step 2: Invoke the skill and drive the interactive flow**

Invoke: `/convert-gdoc docs/Antonino_Benedetto_Presentazione.md` (or, if running as a subagent without slash-command access, call the Skill tool directly with skill name `convert-gdoc` and the same path as an argument).

Answer the skill's prompts with these concrete values:
- Title: accept the extracted H1 as-is, `Antonino Benedetto — Backend Developer`.
- Slug (source, IT): `antonino-benedetto-backend-developer`.
- Tags: `["meta"]` (same category already used for the existing `benvenuto`/`welcome` post — this document is about the author/project, not a technical decision).
- Date: today's date.
- Let the skill produce the English translation and its proposed EN slug; accept the EN slug if it is a reasonable kebab-case rendering of the translated title (e.g. something like `antonino-benedetto-backend-developer` or a closely equivalent English phrasing).

Read the proposed English translation before accepting it: confirm it preserves the four `---`-separated sections and their meaning (this is a qualitative read, not a scripted assertion — there is no single "correct" translation to diff against).

- [ ] **Step 3: Verify the produced files structurally**

```bash
slug_en=<the EN slug the skill produced in Step 2 — substitute the real value>
test -f content/it/blog/antonino-benedetto-backend-developer.md && echo "IT file OK"
test -f "content/en/blog/${slug_en}.md" && echo "EN file OK"
grep -q 'draft: false' content/it/blog/antonino-benedetto-backend-developer.md && echo "IT draft:false OK"
grep -q 'draft: false' "content/en/blog/${slug_en}.md" && echo "EN draft:false OK"
grep -q "translationKey: \"post-${slug_en}\"" content/it/blog/antonino-benedetto-backend-developer.md && echo "IT translationKey OK"
grep -q "translationKey: \"post-${slug_en}\"" "content/en/blog/${slug_en}.md" && echo "EN translationKey OK"
grep -q "date: $(date +%Y-%m-%d)" content/it/blog/antonino-benedetto-backend-developer.md && echo "IT date OK"
git branch --show-current
```

Expected: all seven `OK` lines print, and the last command prints `post/${slug_en}` (the skill must have created and switched to that branch per Step 6 of the skill).

- [ ] **Step 4: Clean up**

```bash
rm -f content/it/blog/antonino-benedetto-backend-developer.md "content/en/blog/${slug_en}.md"
git checkout "$original_branch"
git branch -D "post/${slug_en}"
git status --short
```

Untracked files are not scoped to a branch — `git checkout`/`git branch -D` never touch them, only tracked files move with a branch switch. Since the skill's Step 8 forbids `git add`/`git commit`, the two content files Step 7 wrote are untracked, so they must be `rm -f`'d explicitly before (or after) deleting the branch; deleting the branch alone leaves them sitting in the working tree on whichever branch you're on. Expected: switches back to the original branch, deletes the test branch, `git status --short` prints nothing (working tree clean).

---

## Task 3: Verify against fixture without H1 (`Non volevo un portfolio._.md`)

**Files:**
- None created or modified permanently — same pattern as Task 2, against the second fixture.

**Interfaces:**
- Consumes: `.claude/skills/convert-gdoc/SKILL.md` (Task 1); `docs/Non volevo un portfolio._.md` (existing fixture: no H1, heading style `## **Text**` with redundant bold, short one-sentence paragraphs, a `---` divider before a closing italic P.S., no images).

- [ ] **Step 1: Record the starting branch**

```bash
original_branch=$(git branch --show-current)
echo "starting branch: $original_branch"
git status --short
```

Expected: prints the current branch name and a clean (or already-known) status.

- [ ] **Step 2: Invoke the skill and drive the interactive flow**

Invoke: `/convert-gdoc "docs/Non volevo un portfolio._.md"`.

Answer the skill's prompts with these concrete values:
- Title: the fixture has no H1, so the skill should propose a title derived from the filename — expect something close to `Non volevo un portfolio.` or `Non volevo un portfolio` (extension stripped, underscore→space, trailing stray punctuation trimmed). Confirm it, correcting only if the derivation produced something clearly wrong (e.g. left a stray trailing `._`).
- Slug (source, IT): `non-volevo-un-portfolio`.
- Tags: `["meta"]`.
- Date: today's date.
- Let the skill translate and propose an EN slug; accept if reasonable (e.g. `i-didnt-want-a-portfolio` or similar).

- [ ] **Step 3: Verify cleanup rules were actually applied**

```bash
slug_en=<the EN slug the skill produced in Step 2 — substitute the real value>
grep -q '^## \*\*' content/it/blog/non-volevo-un-portfolio.md && echo "BUG: bold still present in an IT heading" || echo "IT heading bold stripped OK"
grep -q '^## \*\*' "content/en/blog/${slug_en}.md" && echo "BUG: bold still present in an EN heading" || echo "EN heading bold stripped OK"
grep -q '^## ' content/it/blog/non-volevo-un-portfolio.md && echo "IT headings still present OK"
grep -q '^---$' content/it/blog/non-volevo-un-portfolio.md && echo "IT section divider preserved OK"
grep -qE '^\*.+\*$' content/it/blog/non-volevo-un-portfolio.md && echo "IT closing italics preserved OK"
```

Expected: `IT heading bold stripped OK`, `EN heading bold stripped OK`, `IT headings still present OK`, `IT section divider preserved OK`, `IT closing italics preserved OK` — five lines, no `BUG:` lines.

- [ ] **Step 4: Verify the conflict guard on a repeat invocation**

Without cleaning up yet, invoke `/convert-gdoc "docs/Non volevo un portfolio._.md"` a second time, giving the same slug (`non-volevo-un-portfolio`) when asked.

Expected: the skill reports a conflict (per its Step 5) — file and/or `translationKey` already exist — and asks for a different slug instead of overwriting `content/it/blog/non-volevo-un-portfolio.md`. Confirm the file's content/timestamp is unchanged:

```bash
git status --short content/it/blog/non-volevo-un-portfolio.md
```

Expected: no output (file untouched — still only an untracked new file from the first run, not modified by the second run).

Answer "cancel" / do not supply an alternative slug — end this second invocation without producing a second set of files.

- [ ] **Step 5: Clean up**

```bash
rm -f content/it/blog/non-volevo-un-portfolio.md "content/en/blog/${slug_en}.md"
git checkout "$original_branch"
git branch -D "post/${slug_en}"
git status --short
```

Untracked files are not scoped to a branch — deleting the branch alone does not remove them (see Task 2 Step 4's note). `rm -f` them explicitly first.

Expected: switches back to the original branch, deletes the test branch and its untracked content files, `git status --short` prints nothing.

---

## Task 4: Verify the image guard halts the skill

**Files:**
- Create (scratch, not part of the repo): a synthetic fixture under the scratchpad directory, e.g. `/tmp/claude-1000/-home-dev-projects-baicode-journal/*/scratchpad/fake-export-with-image.md` and a sibling `images/` folder — substitute whatever this session's actual scratchpad path is.

**Interfaces:**
- Consumes: `.claude/skills/convert-gdoc/SKILL.md` (Task 1).

- [ ] **Step 1: Build a fixture with an inline image reference**

```bash
scratch="<this session's scratchpad directory>"
mkdir -p "$scratch/gdoc-image-test"
cat > "$scratch/gdoc-image-test/fake-export.md" <<'EOF'
# A fake export

Some text.

![a diagram](diagram.png)

More text.
EOF
```

- [ ] **Step 2: Invoke the skill against it and confirm it halts**

Invoke: `/convert-gdoc "$scratch/gdoc-image-test/fake-export.md"`.

Expected: the skill stops at Step 1 (image guard), tells the user image handling isn't supported yet, and does **not** create a branch or any file under `content/`. Confirm:

```bash
git status --short
git branch --list 'post/*'
```

Expected: `git status --short` prints nothing (no new files under `content/`), and `git branch --list 'post/*'` prints nothing (no branch created).

- [ ] **Step 3: Build a second fixture with a sibling asset folder instead (no inline image markup)**

```bash
mkdir -p "$scratch/gdoc-image-test/fake-export_files"
cat > "$scratch/gdoc-image-test/fake-export_files/.keep" <<'EOF'
placeholder
EOF
cat > "$scratch/gdoc-image-test/fake-export.md" <<'EOF'
# A fake export without inline image markup

Some text, no image tags here, but an asset folder sits next to this file.
EOF
```

- [ ] **Step 4: Invoke the skill again and confirm it still halts**

Invoke: `/convert-gdoc "$scratch/gdoc-image-test/fake-export.md"`.

Expected: same halt behavior as Step 2 — the skill detects the sibling `fake-export_files/` folder and stops before creating anything. Confirm again with the same two commands as Step 2.

- [ ] **Step 5: Clean up the scratch fixture**

```bash
rm -rf "$scratch/gdoc-image-test"
```

Expected: no output; the scratchpad directory no longer contains the test fixture.

---

## Task 5: Verify the future-date warning

**Files:**
- None created or modified — this task only exercises the Step 2 prompt of the skill far enough to observe the warning, then aborts before any branch or file is created.

**Interfaces:**
- Consumes: `.claude/skills/convert-gdoc/SKILL.md` (Task 1); `docs/Antonino_Benedetto_Presentazione.md` (same fixture as Task 2, reused only to reach the date prompt).

- [ ] **Step 1: Record starting state**

```bash
git status --short
git branch --list 'post/*'
```

Expected: both commands print nothing (clean tree, no leftover test branches from earlier tasks).

- [ ] **Step 2: Invoke the skill and supply a future date**

Invoke: `/convert-gdoc docs/Antonino_Benedetto_Presentazione.md`. Proceed through title/slug/tags confirmation as in Task 2 Step 2, but when asked for `date`, supply a future date (e.g. one year ahead of today).

Expected: the skill responds with a warning equivalent to "La CI della PR rifiuta contenuti con `date` futura (guardrail bloccante) — questa data farebbe fallire la pubblicazione finché non la aggiorni," and does **not** refuse to continue — it still lets the user proceed with that date if they choose to.

- [ ] **Step 3: Abort without producing output**

Respond that you want to cancel / restart with today's date instead of continuing, and do not proceed to translation, branch creation, or file writing.

```bash
git status --short
git branch --list 'post/*'
```

Expected: both commands print nothing — confirms the warning-and-continue behavior didn't side-effect anything before the branch/file-writing steps.
