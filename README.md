# Label Tape Systems Website

Static site (8 pages) served by unprivileged nginx. Built by GitHub Actions, run by Portainer on the VPS behind Nginx Proxy Manager. No database, no build step, no outside requests (fonts are bundled).

## Requirements

Docker Desktop (Windows) or Docker Engine + Compose v2.

## How it deploys

```
git push  ->  Portainer polls GitHub every 5 min  ->  rebuilds the image on the VPS  ->  NPM serves lts-labels.com
```

Portainer stack from this Git repo, compose path `docker-compose.yml`. `pull_policy: build` makes Portainer CE rebuild on each update. The container joins Nginx Proxy Manager's network and opens no ports.

### One-time Portainer setup

1. **GitHub token** (read-only): fine-grained, repository `labelandtapesystems` only, Contents: Read.
2. **Portainer > Stacks > Add stack > Repository:**
   - URL `https://github.com/ijerimy/labelandtapesystems`, reference `refs/heads/main`, authentication on (username `ijerimy`, the token)
   - Compose path `docker-compose.yml`
   - GitOps updates: on, Polling, `5m`
   - Environment variable: `NPM_NETWORK` = the network NPM is on
3. **Nginx Proxy Manager > Add Proxy Host:** `lts-labels.com`, scheme `http`, forward host `lts-website`, port `8080`. SSL: Let's Encrypt, Force SSL.

**Day to day:** `git push`, and the site updates within about 5 minutes.

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
