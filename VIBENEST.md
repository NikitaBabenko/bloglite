# Bloglite on VibeNest — guided setup candidate

**Status: not runtime validated.** This fork prepares a source build and manual
configuration. It does not claim a successful build, deployment, persistence
test, or fit within VibeNest Free. Upstream's small-memory description is not a
measurement on VibeNest.

Upstream: [rikhuijzer/bloglite](https://github.com/rikhuijzer/bloglite), commit
`507db81d1a4f567a601538d9d315be0577b15e2f`, MIT. Application source and attribution
are preserved. The added root Dockerfile builds the two Rust workspace crates
into **one** service; `bloglite-auth` is a library, not a second application.

## Before deployment

The badge opens a repository preview. The preview can mistake this Rust
workspace for two services. Do not accept an automatic group deployment.
Use the dashboard's manual single-project setup / **Deploy root only** choice.
Review every setting below before starting a deployment.

Building Rust requires separate build capacity; a 256 MB runtime allowance is
not evidence of safe compiler capacity. The pilot must have an assigned test
slot, fresh target-host capacity/queue checks and the normal VibeNest security
gate before any launch. The Dockerfile limits compilation to one Cargo job and
one codegen unit, but does not establish a safe peak-memory bound.

## Required configuration

| Setting | Value |
| --- | --- |
| Repository | `https://github.com/NikitaBabenko/bloglite` |
| Branch | `main` (record the exact commit selected for the deployment) |
| Service count | One |
| Base directory | `/` |
| Build pack | Dockerfile |
| Dockerfile location | `Dockerfile` at repository root |
| Internal HTTP port | `3000` |
| HTTPS | Use VibeNest's assigned HTTPS hostname |
| Persistent volume | Read/write mount at `/data` |
| Database | Embedded SQLite; no managed Postgres, MySQL or Redis |

The build uses a digest-pinned official Rust 1.99.1 Alpine image, the committed
`Cargo.lock`, `cargo fetch --locked`, then `cargo build --frozen --jobs 1`.
It compiles bundled SQLite, compression and TLS dependencies from source.
A static-link inspection fails the build if a dynamic loader or library is
required. The runtime contains the resulting binary, CA certificates and license.
Only native Linux amd64/arm64 builds are intended; neither has been executed
for this fork. Bit-for-bit reproducibility has not been tested.

Set these environment variables through the project's secret/environment UI:

| Variable | Value |
| --- | --- |
| `BLOGLITE_USERNAME` | Your chosen administrator name |
| `BLOGLITE_PASSWORD` | A strong unique secret; keep it stable across replacements |
| `BLOGLITE_DOMAIN` | Your assigned hostname only, e.g. `your-blog.vibenest.net`; no `https://`, path or trailing slash |
| `BLOGLITE_PRODUCTION` | `true` (also set in the image) |
| `BLOGLITE_DATABASE_PATH` | `/data/db.sqlite` (also set in the image) |
| `BLOGLITE_PORT` | `3000` (also set in the image) |

Leave all `BLOGLITE_TRIGGER_*` variables unset. This pilot does not enable the
optional GitHub/Forgejo backup workflow or supply a trigger token.

Configure the repository, port and required secrets before the first launch.
**Saving a persistent volume currently also requests a redeploy and can attach
Free hardware.** Treat that save as a launch, not as draft preparation. Only
perform it when the coordinator has authorized the slot and all launch gates
pass. If the UI cannot safely stage the required settings, stop for coordinator
review. Never substitute a direct provider launch.

Mount the whole `/data` directory, including SQLite WAL sidecars. Posts, uploaded
file bytes, settings and the session salt are all in SQLite. Dockerfile directory
creation alone does not provide persistence. Confirm volume write permissions,
mount identity and continuity after replacement before storing real content.

## Content and authentication

This is a single trusted-author public notebook. Posts and file download URLs
are public. Do not upload private material or untrusted HTML/SVG. Markdown allows
raw HTML, and file responses use the supplied content type. There is no separate
untrusted-contributor sandbox.

Log in at `/login` over HTTPS. Upstream sets `Secure`, `HttpOnly`,
`SameSite=Strict` cookies with a two-week server-checked lifetime. It stores the
production session salt in SQLite; keeping that database and the password should
preserve valid sessions across a restart. This still requires runtime testing.
SameSite is the observed CSRF defense; the source does not add an explicit
anti-CSRF token or Origin check.

The authenticated backup endpoint is `/api/download/all.tar.xz`, using
`Authorization: Bearer <BLOGLITE_PASSWORD>`. Keep the credential out of shell
history, logs and shared reports. The backup is assembled and compressed in
memory; test only tiny synthetic content initially. Do not assume large backups
fit Free. Post deletion replaces content with an upstream deletion marker.

## Acceptance still required

Before describing this as working, record the deployed commit/image and verify:

- Wrong/absent login is rejected; valid HTTPS login works; anonymous writes,
  settings changes, uploads and backups are rejected.
- Public reading, create/edit/delete, search, malformed search and invalid
  pagination work without crashing. Use a small synthetic text/image upload.
- Cookie attributes, logout, session lifetime and authenticated backup behavior.
- Posts, file bytes, settings and valid sessions survive an authorized restart
  and container replacement with the same volume.
- Actual memory, startup peak, CPU quota, disk use and absence of OOM under a
  small load. The catalog Free target is 256 MB RAM, 0.5 platform CPU and 4 GB;
  verify actual cgroup limits separately. Trial duration must be checked against
  the current account/plan, not inferred from preview marketing text.
- Stop/release only the pilot's own assigned resources when the check finishes.

No platform release or upstream outreach is part of this preparation. GitHub
Actions are disabled on this fork; upstream workflow files remain for provenance.
