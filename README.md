# particlekit/docker-nextcloud

Docker image for the KIT Nextcloud instance (`nextcloud.particle.kit.edu`).

## What changed on 2026-10-22

The image was rebuilt on **Debian 13 (trixie)** with **Nextcloud 35.0.2** and
**PHP 8.5.12**, replacing the Alpine 3.17 / NC 25.0.13.2 build.

Why:

* The Alpine image shipped **PHP 8.1.22**, which is vulnerable to
  **CVE-2026-109618 / CVE-2026-109619** (PHP2Shell). Debian's own `php8.5`
  and the official `nextcloud:35-apache` image still ship the vulnerable
  8.5.11 - only `packages.sury.org` has the patched 8.5.12.
* NC 35 requires a newer PHP than 8.1 anyway (NC 26+ needs >= 8.2).
* Alpine 3.17 is EOL.

The instance was migrated 25 -> 26 -> ... -> 35 on 2026-10-22. See
`NEXTCLOUD-UPGRADE-PLAN.md` in the `git.particle.kit.edu` admin repo for the
full procedure and the pitfalls (config.php version pinning, the
`authtoken_old` index collision, the MariaDB 11 `utf8` -> `utf8mb3` rename).

## Build

```
docker build -t particlekit/nextcloud:latest .
```

Build arguments:

| ARG          | default | notes                                            |
|--------------|---------|--------------------------------------------------|
| `NC_VERSION` | 35.0.2  | Nextcloud release to download                    |
| `PHP_VERSION`| 8.5     | PHP minor; must match the NC major (see table)   |

PHP minor per NC major (Nextcloud's own `lib/versioncheck.php` bounds):

| NC major | PHP |
|----------|-----|
| 26, 27   | 8.2 |
| 28, 29, 30 | 8.3 |
| 31, 32   | 8.4 |
| 33, 34, 35 | 8.5 |

The weekly build (`roles/automatedbuilds`) builds with `nocache: yes` and
`pull: yes`, so it picks up the current sury PHP patch level and the current
NC 35.0.x release automatically. **Keep `nocache: yes`** - with the Docker
layer cache a Debian security update never reaches the image and the weekly
build silently re-publishes the old, vulnerable one.

## PHP2Shell mitigations (upstream's two mitigations, applied as defence in depth)

```
memory_limit = -1
post_max_size = 8M
session.upload_progress.enabled = 0
```

## Layout

| path                                  | purpose                                     |
|---------------------------------------|---------------------------------------------|
| `Dockerfile`                          | Debian 13 + NC + sury PHP + apache2        |
| `nc-install`                          | entrypoint: starts MariaDB, copies `/tpl/**`, fixes permissions |
| `tpl/etc/nextcloud/config.php`        | Nextcloud config template (substituted at start) |
| `tpl/etc/nextcloud/autoconfig.php`    | autoconfig template                         |
| `tpl/etc/apache2/sites-available/nextcloud.conf` | Apache vhost template            |

## Note on `config.php`'s `version` key

This deployment stores the **installed instance version in `config.php`'s
`version` key**, not in `oc_appconfig`. `occ` compares that value against the
code version and refuses multi-major jumps ("Updates between multiple major
versions and downgrades are unsupported"). The template is re-copied into the
container on **every** start, so the template has to be kept in sync with the
image's code version - otherwise the long `occ upgrade` re-runs on every
container start. `roles/nextcloud` does this in the task
"keep template config.php version in sync with the container code version".
