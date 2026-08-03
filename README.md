# bloomwifi.github.io

[![GitHub x-n2o/bloomwifi.github.io](https://img.shields.io/badge/GitHub-x--n2o%2Fbloomwifi.github.io-181717?logo=github&logoColor=white)](https://github.com/x-n2o/bloomwifi.github.io)
[![Deploy workflow](https://github.com/x-n2o/bloomwifi.github.io/actions/workflows/jekyll.yml/badge.svg)](https://github.com/x-n2o/bloomwifi.github.io/actions/workflows/jekyll.yml)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-bloomwifi.today-2ea44f?logo=githubpages&logoColor=white)](https://bloomwifi.today/)
[![Jekyll](https://img.shields.io/badge/Jekyll-GitHub%20Pages-CC0000?logo=jekyll&logoColor=white)](https://jekyllrb.com/)
[![Ruby 3.4.1](https://img.shields.io/badge/Ruby-3.4.1-CC342D?logo=ruby&logoColor=white)](.ruby-version)
[![Docker ready](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)](Dockerfile)
[![Google Sheet source](https://img.shields.io/badge/Google%20Sheet-source%20of%20truth-34A853?logo=googlesheets&logoColor=white)](https://docs.google.com/spreadsheets/d/13G1JKaLiD1rqrGp8rTGW5F14nfoBkfdbRpHar4J7_tk/edit?gid=1635679974#gid=1635679974)

Bloom Nine Elms Guest Wi-Fi

## Overview
Jekyll site displaying daily guest Wi-Fi passwords with QR codes for easy access.

## Source of Truth
Wi-Fi passwords are managed in a [Google Sheet](https://docs.google.com/spreadsheets/d/13G1JKaLiD1rqrGp8rTGW5F14nfoBkfdbRpHar4J7_tk/edit?gid=1635679974#gid=1635679974). The spreadsheet contains two columns: `date` and `password`.

## Setup
The recommended path requires only Docker — no local Ruby installation needed.

```bash
./serve --docker
```

If you prefer a local Ruby setup, install the version pinned in `.ruby-version` and then install gems:

```bash
bundle install
```

The Docker image also uses the Ruby version pinned in `.ruby-version`.

## Development
```bash
./serve
./serve --docker
```

`./serve` runs Jekyll locally with your host Ruby. `./serve --docker` runs the same site in Docker. After either command starts successfully, preview the site at `http://127.0.0.1:4000` (or `http://localhost:4000`). If you use Docker, Jekyll binds to `0.0.0.0` inside the container, but the site is still accessible via localhost on your host machine.

## Updating Passwords
To sync passwords from the Google Sheet and generate post files:

```bash
./update-passwords
./update-passwords --docker
```

This script will:
- Fetch the latest passwords from the Google Sheet
- Generate or update post files in `_posts/` with the `YYYY-MM-DD-wifi.md` naming pattern
- Store each password once, in the post's front matter; the QR code line references it as `{{ page.password }}`, and re-running the script migrates any legacy post that still inlines the literal (reported as "Updated")

**Note:** The Google Sheet must be publicly accessible (view-only is sufficient) for the script to work.

## QR plugin
QR codes are rendered by [`jekyll-qr`](https://codeberg.org/x-n2o/jekyll-qr), consumed as a git-sourced gem pinned to tag `v1.1.0` in the `Gemfile`. It is a GPL-3.0-only fork of upstream [codeberg.org/seabass/jekyll-qr](https://codeberg.org/seabass/jekyll-qr) that adds Liquid variable expansion inside the `{% qr %}` tag, so posts write `{% qr WIFI:T:WPA;S:Bloom Guest;P:{{ page.password }}; %}` and the password lives only in front matter. `bundle install` fetches it from Codeberg automatically — no extra build steps. To upgrade, tag a new version in the fork, bump the `tag:` in the `Gemfile`, and run `bundle install`.

## Build
Generate the static site for deployment:
```bash
./build
./build --docker
```

Output will be in `_site/`.
