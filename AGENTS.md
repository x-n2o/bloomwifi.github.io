# Repository Guidelines

## Project Structure & Module Organization
- Jekyll site for Bloom Nine Elms Guest Wi‑Fi. Core configs in `_config.yml`, layouts in `_layouts/`, and home entrypoint at `index.markdown`.
- Daily Wi‑Fi posts live in `_posts/` using the `YYYY-MM-DD-wifi.md` naming pattern; `_site/` is generated output and should never be edited manually.
- Assets (images, styles) belong in `assets/`; helper script `serve` runs the local server.

## Build, Test, and Development Commands
- `bundle install` — install Ruby gems defined in `Gemfile` (first run or when dependencies change).
- `./serve` or `bundle exec jekyll serve --livereload` — run the site locally at `http://127.0.0.1:4000`.
- `bundle exec jekyll build` — produce the static site in `_site/` for verification before pushing.
- Optional: `bundle exec jekyll doctor` to sanity-check the config and content.

## Coding Style & Naming Conventions
- Posts use YAML front matter with `layout: post` and a `password` field; keep the filename date in UTC to match publish order.
- Keep markup minimal; prefer Markdown with small HTML snippets already used in posts (copy-to-clipboard block). Two-space indentation in HTML/CSS/JS snippets to match existing files.
- Liquid filters handle date formatting: `{{ page.date | date: "%A, %B %e, %Y" }}`; stay consistent when adding variations.
- Avoid editing `_site/`; change templates in `_layouts/` or content in `_posts/` instead.

## Testing Guidelines
- No automated tests; validate by running the local server and confirming password display, QR rendering, and clipboard copy work in the browser.
- If adding scripts or styles, check the console for errors and confirm mobile view (narrow viewport) still renders cleanly.

## Commit & Pull Request Guidelines
- Match existing history: short, imperative summaries (`Add WiFi passwords for late 2025` style). Keep subject under ~72 characters.
- For PRs, include: what changed, why, how to verify locally (`bundle exec jekyll serve` steps), and screenshots of the rendered page when visuals change.
- Link related issues or task IDs when available; call out dependency updates (Gemfile/Gemfile.lock) explicitly.

## Security & Configuration Tips
- Do not hard-code unrelated secrets or tokens; only store intended guest Wi‑Fi passwords in `_posts/`.
- Ensure new external assets use HTTPS and reputable CDNs. If adding plugins, prefer ones supported by GitHub Pages or document any required build steps.
