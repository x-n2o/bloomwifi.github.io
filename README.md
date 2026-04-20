# bloomwifi.github.io
Bloom Nine Elms Guest Wi-Fi

## Overview
Jekyll site displaying daily guest Wi-Fi passwords with QR codes for easy access.

## Source of Truth
Wi-Fi passwords are managed in a [Google Sheet](https://docs.google.com/spreadsheets/d/13G1JKaLiD1rqrGp8rTGW5F14nfoBkfdbRpHar4J7_tk/edit?gid=1635679974#gid=1635679974). The spreadsheet contains two columns: `date` and `password`.

## Setup
Install Docker Desktop or Docker Engine with Docker Compose.

No local Ruby or Bundler installation is required for the default workflow.

## Development
```bash
./serve
```

This builds the dev image on first run, installs gems inside Docker, and serves the site with live reload at `http://127.0.0.1:4000`.

## Updating Passwords
To sync passwords from the Google Sheet and generate post files:

```bash
./update-passwords
```

This script will:
- Fetch the latest passwords from the Google Sheet
- Generate or update post files in `_posts/` with the `YYYY-MM-DD-wifi.md` naming pattern
- Create posts with the proper template including QR codes and copy-to-clipboard functionality

**Note:** The Google Sheet must be publicly accessible (view-only is sufficient) for the script to work.

## Build
Generate the static site for deployment:
```bash
./build
```

Output will be in `_site/`.

## Optional Local Ruby Workflow
If you still want to run everything directly on your host machine:

```bash
bundle install
bundle exec jekyll serve --livereload
ruby scripts/update_passwords.rb
bundle exec jekyll build
```
