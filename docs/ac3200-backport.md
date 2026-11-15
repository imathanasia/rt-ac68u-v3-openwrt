# Backport list for the RT-AC3200 repo (later)

Things from this pass worth bringing back, in order of value:

1. **Authenticated project page**: render the page as a LuCI view instead of a static
   `/www/*.html`; a static file is served without auth, which leaks whatever the page prints.
2. **Footer badge**: `patches/luci-footer-badge.patch` (luci-base `footer.ut`) puts a fixed
   "★ … project" link on every LuCI page; theme-independent, one file.
3. **Branding helper**: `etc/uci-defaults/91-branding.sh` writes both `DISTRIB_DESCRIPTION`
   and `os-release PRETTY_NAME`, so version/model show up in the SSH banner and ubus too.
4. **Baked default password + page note** (`changeme`, "change with passwd") so a fresh image
   is reachable without a console.
5. **Screenshot script** (`scripts/screenshots.sh`) with fixed viewport/scale and the same
   file names, so both repos' `images/` stay comparable.
6. **Docs layout** (`discoveries.md`, `limitations.md`, `optional-packages.md`) and the
   `CFG=` argument in `build.sh`.
