# Label Tape Systems Website

Static site (8 pages) served by unprivileged nginx, with an optional temporary Cloudflare quick tunnel for sharing a preview link. No database, no build step, no outside requests (fonts are bundled).

## Requirements

Docker Desktop (Windows) or Docker Engine + Compose v2.

## Deploy to the VPS (GitHub + Nginx Proxy Manager)

The VPS clones this private repo, builds the container, and checks GitHub every 5 minutes. When a new commit lands on `main` it pulls and rebuilds automatically.

**One-time setup** (on the VPS as `opc`):

From your PC, copy the setup script up, then run it on the VPS:

```
scp deploy/setup-vps.sh opc@129.80.113.77:~
ssh opc@129.80.113.77
sudo bash setup-vps.sh git@github.com:<owner>/<repo>.git
```

The script:
1. Creates a **read-only deploy key** and shows it for you to add under the GitHub repo's Settings > Deploy keys
2. Clones the repo to `/opt/lts-website`
3. Finds Nginx Proxy Manager's Docker network and joins the site to it (no ports published)
4. Builds and starts the `lts-website` container
5. Installs `lts-website-update.timer` (checks every 5 min)

**Nginx Proxy Manager > Add Proxy Host:**
- Domain: `lts.clarifiedtech.net`
- Scheme `http`, Forward Hostname `lts-website`, Port `8080`
- SSL: request a Let's Encrypt certificate, turn on Force SSL

Make sure the DNS A record for `lts.clarifiedtech.net` points to the VPS first, or Let's Encrypt will fail.

**Day to day:** edit locally, `git push`, and the site updates within 5 minutes.

| Task | Command (on VPS) |
|---|---|
| Update now | `sudo lts-website-update --force` |
| Update log | `journalctl -u lts-website-update -n 50` |
| Site logs | `docker logs lts-website` |
| Stop auto-updates | `sudo systemctl disable --now lts-website-update.timer` |

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
