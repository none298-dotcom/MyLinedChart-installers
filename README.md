# MyLinedChart — Installers

Public distribution point for the **MyLinedChart** desktop app installers (macOS `.dmg` / Windows `.exe`) and the free Windows build.

- **Downloads:** see [Releases](../../releases) — the site links directly to these assets.
- **Source is private.** This repo holds only the compiled installers plus a build workflow that pulls the private source at build time (via a read-only token) and publishes the finished `.exe` here. No application source lives in this repo.

### Beta note
The installers are **not yet notarized/signed**. On first launch:
- **macOS:** right‑click the app → **Open** (bypasses Gatekeeper once).
- **Windows:** SmartScreen warns → **More info → Run anyway**.

Full signed/notarized distribution comes later.
