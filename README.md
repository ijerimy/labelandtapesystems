# Label Tape Systems Website

Static site (8 pages) served by unprivileged nginx. Built by GitHub Actions, run by Portainer on the VPS behind Nginx Proxy Manager. No database, no build step, no outside requests (fonts are bundled).

## Requirements

Docker Desktop (Windows) or Docker Engine + Compose v2.

## How it deploys

```
git push  ->  GitHub Actions builds the image, pushes ghcr.io/ijerimy/labelandtapesystems:<commit>
          ->  Actions commits the new tag into docker-compose.yml
          ->  Portainer (polling, 5 min) sees that commit and redeploys  ->  NPM serves lts-labels.com
```

Why: Portainer can't build images through an agent environment, and its "re-pull image" option is Business Edition only. Pinning the tag per commit makes Portainer CE pull the new image on its own.

**Before editing locally, run `git pull`.** Every deploy adds a small commit from GitHub Actions.

### One-time Portainer setup

1. **GitHub tokens** (both read-only): fine-grained (repo `labelandtapesystems`, Contents: Read) for the repo, classic (`read:packages` only) for the image.
2. **Portainer > Registries > Add registry > Custom:** `ghcr.io`, username `ijerimy`, password = the `read:packages` token.
3. **Portainer > (VPS environment) > Stacks > Add stack > Repository:** URL `https://github.com/ijerimy/labelandtapesystems`, ref `refs/heads/main`, auth with the fine-grained token, compose path `docker-compose.yml`, GitOps polling `5m`, env var `NPM_NETWORK`.
4. **NPM proxy host:** `lts-labels.com` -> `http://lts-website:8080`, Let's Encrypt, Force SSL.

## Local preview (optional)

```
docker compose -f docker-compose.preview.yml up -d --build
```

- Local preview: http://localhost:8080 (this PC only)
- Public preview link: run `docker compose -f docker-compose.preview.yml logs cloudflared` and look for the `https://<random-words>.trycloudflare.com` URL.
- Stop: `docker compose -f docker-compose.preview.yml down`

## Preview vs launch

The preview is kept **out of search engines**: `robots.txt` blocks all crawlers and nginx sends `X-Robots-Tag: noindex`. At launch:

1. Replace `public/robots.txt` with the launch version noted inside it.
2. Remove the two `X-Robots-Tag` lines in `nginx.conf`.
3. Point the real domain at the VPS and add it to the NPM proxy host.
4. Submit `https://www.labelandtapesystems.com/sitemap.xml` in Google Search Console.

## Files

| Path | What it is |
|---|---|
| `public/*.html` | The 8 pages + 404. Header and footer are repeated in each file, so a menu change has to be made in all of them |
| `public/css/styles.css` | Theme. Colors at the top come from the LTS logo |
| `public/img/lts-logo.svg` | Vector rebuild of the existing LTS logo |
| `public/img/slabs-*.svg` | Decorative art based on the LTS letterforms |
| `public/photos/` | LTS product photos. `*-cut.webp` have the background removed |
| `public/fonts/` | Archivo, Pinyon Script, Doto (self-hosted) |
| `_source/photos/` | Every original image pulled from the old site (not served) |
| `nginx.conf` | Server config, security headers, and 301 redirects from old page URLs |

## Old URL redirects

| Old page | New page |
|---|---|
| /index.html, /about.html | same names |
| /Just_Ask.html | /customers.html |
| /How_it_Works.html | /laundry-labeling-systems.html |
| /page04.html | /laundry-labeling-systems.html#print-options |
| /Kits.html | /vision-id-kit.html |
| /Warranties.html | /support.html |
| /page05.html, /Contact-us.html | /order.html |
