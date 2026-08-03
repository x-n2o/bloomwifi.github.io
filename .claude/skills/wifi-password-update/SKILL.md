---
name: wifi-password-update
description: Runs the full Bloom Guest Wi-Fi password pipeline for this repo — Google Sheet to generated posts to deployed site. Use this whenever the user wants to change, add, rotate, or check guest Wi-Fi passwords, mentions the password spreadsheet or "source of truth" sheet, asks to run ./update-passwords or update-passwords, asks to fill in a month or date range of passwords, asks why the site shows a stale or missing password, or asks to deploy/publish/redeploy bloomwifi.today. Also use it when the user just names a password and a period ("make August 6NHTtwFN", "set next week to X") without naming any tooling, since that always means this pipeline.
---

# Bloom Guest Wi-Fi password pipeline

This repo publishes one page per day showing that day's guest Wi-Fi password with a
QR code, at https://bloomwifi.today/. Everything downstream is generated, so the
work is almost never "edit a file" — it's "get the sheet right, then let the
tooling regenerate."

## The one constraint that shapes everything

**The Google Sheet is the source of truth, and Claude cannot write to it.**

The Drive connector in this environment can read, search, download, and create
*new* files, but it has no tool that edits an existing file's content, and there
is no Google Sheets connector available. Reaffirming the request doesn't change
this — it's a missing tool, not a judgment call.

So the pipeline has a human step in the middle, and the useful thing you can do
is make that step take ten seconds: generate the exact rows, hand them over, and
wait. Don't burn turns hunting for a write path, and don't quietly generate posts
that the sheet doesn't back — that leaves the repo and the sheet disagreeing,
which is the failure mode this whole design exists to prevent.

Sheet: https://docs.google.com/spreadsheets/d/13G1JKaLiD1rqrGp8rTGW5F14nfoBkfdbRpHar4J7_tk/edit?gid=1635679974
Columns are `date,password` with a header row. `scripts/update_passwords.rb` hardcodes
the sheet ID and gid, so a new sheet means editing that script — prefer keeping this one.

## Pipeline

### 1. Read the sheet as it stands

```bash
curl -sL "https://docs.google.com/spreadsheets/d/13G1JKaLiD1rqrGp8rTGW5F14nfoBkfdbRpHar4J7_tk/export?format=csv&gid=1635679974" | tr -d '\r'
```

This is the same URL the Ruby script uses, so what you see is what it will see.
Check whether the dates the user cares about are present and what they currently
hold. If they're already correct, skip to step 4 — the sheet may already be fine
and the user just wants a redeploy.

### 2. Generate the rows the sheet is missing

```bash
ruby .claude/skills/wifi-password-update/scripts/sheet_rows.rb 2026-08-01 2026-08-31 --password 6NHTtwFN
ruby .claude/skills/wifi-password-update/scripts/sheet_rows.rb 2026-09-01 2026-09-30   # random per day
```

Default is a fresh random 8-character password per day, matching the site's normal
daily-rotation model. `--password X` pins every day in the range to one value, which
is what "same password for all of August" means.

Worth saying out loud if the user asks for a fixed value across a long range: daily
rotation is effectively off for that period. Say it once, then do what they asked —
it's their call, and it's trivially reversible by putting distinct values in the sheet
and re-running.

### 3. Hand the rows to the user and stop

Write them to a file, send it with `SendUserFile` if that tool exists, and also paste
them inline — copying from chat is often faster than downloading. Tell them the row
number to paste at (header + N data rows, so the first empty row is N+2), and that
Sheets will offer "Split text to columns" when comma-separated text lands in one cell.

Then genuinely wait. There is nothing useful to do until the sheet is updated, and
proceeding without it produces posts with no backing row.

### 4. Regenerate posts from the sheet

```bash
./update-passwords          # local ruby
./update-passwords --docker # if no local ruby
```

Read the summary line — it's the real signal:

- `N created` — new dates appeared in the sheet.
- `N updated` — existing dates changed value.
- `N unchanged` — already in sync.
- `Warning: N local post(s) not found in the spreadsheet` — posts exist in `_posts/`
  with no sheet row. The script never deletes, so these linger and serve stale
  passwords forever. Either add the rows to the sheet or delete the files; don't
  leave it warning.

### 5. Prove the sheet really is the source of truth

When the change matters, delete the affected posts and let the script rebuild them
from scratch:

```bash
rm _posts/2026-08-*.md
./update-passwords
git diff --quiet && echo "clean: regenerated files match committed files"
```

A clean tree means the committed posts are exactly what the sheet produces. This
catches hand-edited posts that have silently drifted from the sheet, which is
otherwise invisible until someone reads a wrong password off the wall.

### 6. Build locally before pushing

`bundle exec jekyll` fails in this environment with `command not found: jekyll`
even after a successful `bundle install` — the binstub isn't on PATH. Call the
gem's executable directly:

```bash
bundle install
JEKYLL=$(gem contents jekyll | grep 'exe/jekyll$')
bundle exec ruby "$JEKYLL" build
```

Then confirm a page actually rendered — a green build says nothing about whether
Liquid produced the right password:

```bash
grep -c '6NHTtwFN' _site/2026/08/03/index.html   # expect 3: heading, QR payload, clipboard JS
```

Built pages live at `_site/YYYY/MM/DD/index.html`. `_site/` is gitignored; never
commit it or hand-edit it.

### 7. Commit and push to main

The site deploys from `main`, so password changes go straight there rather than
through a branch — a PR would just delay the passwords people need today. Match
the existing history style:

```
Add WiFi passwords for August 2026
Sync WiFi passwords from sheet
```

Only `_posts/*.md` should appear in the diff. If `Gemfile.lock` or anything else
shows up, that's a separate concern — don't fold it into a password commit.

### 8. Deploy and verify it's actually live

The `deploy` workflow (`.github/workflows/jekyll.yml`) runs on a schedule every 8
hours and on `workflow_dispatch`. A push alone does **not** trigger it, so an urgent
change needs an explicit run:

```
mcp__github__actions_run_trigger:
  method: run_workflow, owner: x-n2o, repo: bloomwifi.github.io,
  workflow_id: jekyll.yml, ref: main
```

Then verify against the live site, not against the workflow's green check — the
build can succeed while serving something you didn't intend:

```bash
curl -sL https://bloomwifi.today/2026/08/03/ | grep -c '6NHTtwFN'
curl -sL https://bloomwifi.today/ | grep -o 'Monday, August  3, 2026'
```

Note the double space in dates — Jekyll's `%e` pads single-digit days.

Avoid `mcp__github__actions_list`; its response is large enough to blow the tool
output limit. `mcp__github__actions_get` with `get_workflow_job` returns the
conclusion compactly.

The `deploy` job fails transiently now and then with `Creating Pages deployment
failed / HttpError: other side closed` — the artifact uploaded fine and GitHub's
deployment API just dropped the connection. Re-run rather than investigate:

```
mcp__github__actions_run_trigger:
  method: rerun_failed_jobs, owner: x-n2o, repo: bloomwifi.github.io, run_id: <id>
```

A re-run makes a new attempt, so the old job ID keeps reporting `failure` and
`run_attempt: 1` forever. Fetch the new job IDs from `get_workflow_run_usage`
before concluding anything about whether the re-run worked.

## Reporting back

Say what's live and what isn't, and be specific about anything you couldn't do —
especially the sheet, since a user who thinks you updated it will stop checking.
Distinguish "the workflow went green" from "I fetched the page and saw the new
password"; only the second one means guests can get online.
