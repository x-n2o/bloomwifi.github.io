# bloomwifi.github.io
Bloom Nine Elms Guest Wi-Fi

## Overview
Jekyll site displaying daily guest Wi-Fi passwords with QR codes for easy access.

## Source of Truth
Wi-Fi passwords are managed in a [Google Sheet](https://docs.google.com/spreadsheets/d/13G1JKaLiD1rqrGp8rTGW5F14nfoBkfdbRpHar4J7_tk/edit?gid=1635679974#gid=1635679974). The spreadsheet contains two columns: `date` and `password`.

## Setup
Install the local Ruby version pinned in `.ruby-version`, then install gems:

```bash
bundle install
```

Docker is optional. When you want the containerized path instead, add `--docker` to the helper scripts. The Docker image also uses the version pinned in `.ruby-version`.

## Development
```bash
./serve
./serve --docker
```

`./serve` runs Jekyll locally with your host Ruby. `./serve --docker` runs the same site in Docker.

## Updating Passwords
To sync passwords from the Google Sheet and generate post files:

```bash
./update-passwords
./update-passwords --docker
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
./build --docker
```

Output will be in `_site/`.
