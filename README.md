# chrome-debullshit

**Strip the AI, ad-tracking, and nagware out of Google Chrome — with one official enterprise-policy file.**

No extensions. No binary patching. Nothing injected. Just the same managed-policy
mechanism corporate IT uses to lock browsers down, pointed at the stuff *you* don't want.
Your **passwords, payments, and account sync stay completely untouched.**

🔗 **Landing page:** https://OMGrant.github.io/chrome-debullshit

---

## What it does

It applies 27 [official Chrome Enterprise policies](https://chromeenterprise.google/policies/)
across five piles:

| Pile | Policies | Examples |
|------|----------|----------|
| **Generative AI / Gemini** | 6 | Gemini integration, AI Mode in the address bar, on-device AI model, page-content sharing |
| **Ad-tracking (Privacy Sandbox)** | 5 | Ad Topics interest profiling, Protected Audience ads, ad measurement, Related Website Sets, the consent prompt |
| **Tracking & privacy hardening** | 3 | block third-party cookies, kill speculative prefetch/preconnect, stop sites probing for saved cards |
| **Nagware & dark patterns** | 10 | the "unsupported flag" banner, "make Chrome default" nag, promo tabs, shopping/price nags, the New Tab feed + cards, profile-creation popups, satisfaction surveys, and *showing the full URL* in the address bar |
| **Phone-home & telemetry** | 3 | usage/crash metrics, URL-keyed data collection, background process on close |

> A couple of these (block third-party cookies, show full URLs) *turn a protection on* rather than only switching Google's additions off — sane defaults in the same spirit.

The canonical list lives in [`policy/debullshit.json`](policy/debullshit.json) — read it before you run anything.

### What it does **not** touch

Passwords · payment methods · account sync · bookmarks · extensions · history.
None of these policies go near your Google account or your data.

---

## Install

### Linux (Chrome & Chromium — auto-detected)
```bash
git clone https://github.com/OMGrant/chrome-debullshit
cd chrome-debullshit
sudo ./install.sh
```

### macOS
```bash
git clone https://github.com/OMGrant/chrome-debullshit
cd chrome-debullshit/macos
sudo ./install.sh
```

### Windows
**Option A** — double-click `windows\debullshit.reg`.

**Option B** — in an **Administrator** PowerShell:
```powershell
git clone https://github.com/OMGrant/chrome-debullshit
cd chrome-debullshit\windows
.\install.ps1
```

After installing, **fully quit Chrome** (`Ctrl+Q` / `Cmd+Q`), relaunch, and open
`chrome://policy` → **Reload policies**. Every entry should read **OK**.

---

## Uninstall

```bash
# Linux / macOS
sudo ./install.sh --uninstall
```
```powershell
# Windows — double-click windows\debullshit-uninstall.reg, or:
.\install.ps1 -Uninstall
```

---

## Customise

[`policy/debullshit.json`](policy/debullshit.json) is the single source of truth. Delete any
line you want to keep, or add your own, then run [`scripts/generate.sh`](scripts/generate.sh)
to regenerate the Windows `.reg` files and the macOS list (CI fails if they're out of sync).

Some policies are **deliberately left out** because they trade away a feature or carry a
risk — add them yourself if you want to go further:

```json
"SearchSuggestEnabled": false,    // stop sending keystrokes to Google (loses omnibox suggestions)
"SpellCheckServiceEnabled": false // disable server-side spellcheck (local spellcheck still works)
```

Left out on purpose, with reasons:

- **`SafeBrowsingProtectionLevel`** — left at standard. "Enhanced" sends more to Google, but
  *disabling* Safe Browsing is a genuine security risk. Don't.
- **`DnsOverHttpsMode: "secure"`** — a privacy win, but breaks captive portals and some networks.
- **Geolocation/sensor blocks** — too blunt; they break maps and legitimately useful sites.

---

## How it stays working

Policies are far stickier than `chrome://flags` or settings toggles — Chrome updates
generally leave them in place. The one thing to watch: Google ships new AI features over
time, occasionally with a brand-new policy name not covered by the master switch. After big
updates, glance at `chrome://policy`; if something new shows up, open an issue and we'll add a line.

---

## Development

`policy/debullshit.json` is the **only** file you edit. Everything platform-specific is
derived from it:

| File | How it's kept in sync |
|------|-----------------------|
| `install.sh` (Linux) | copies the JSON verbatim |
| `windows/install.ps1` | reads the JSON at runtime |
| `windows/debullshit.reg` / `-uninstall.reg` | **generated** by `scripts/generate.sh` |
| `macos/policies.list` → `macos/install.sh` | **generated** by `scripts/generate.sh` |

After editing the JSON, run `./scripts/generate.sh`. The `validate` GitHub Action runs
`./scripts/generate.sh --check` on every push and **fails if anything drifted** — so the
`.reg` and macOS list can never silently fall out of step with the policy file.

## Disclaimer

Not affiliated with, endorsed by, or sponsored by Google LLC. "Google Chrome" and
"Chromium" are trademarks of Google LLC. This project applies Google's own publicly
documented enterprise policies. Use at your own discretion.

## License

[MIT](LICENSE)
