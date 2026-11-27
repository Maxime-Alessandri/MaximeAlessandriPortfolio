# Fonts

Invenesis uses two Google Fonts. No local font files were shipped with the source mirror.

| Font | Use | Weights | Source |
|---|---|---|---|
| **Sen** | Display & headings, eyebrow labels, buttons | 400, 700, (800) | https://fonts.google.com/specimen/Sen |
| **Maven Pro** | Body, UI copy | 400, 500, 600, 700 | https://fonts.google.com/specimen/Maven+Pro |
| **Roboto Slab** | Accent serif, used in one tagline slot only | 300, 400 | https://fonts.google.com/specimen/Roboto+Slab |

Loaded via `@import` at the top of `../colors_and_type.css` (Google Fonts CDN). No `.ttf` / `.woff2` are committed locally.

**Caveat:** I was unable to find local font files in the codebase mirror — the live site uses Google Fonts CDN URLs (`fonts.googleapis.com/css2?family=Sen` and `…Maven+Pro`). If you need self-hosted offline copies for production, download them from Google Fonts and place them in this folder, then swap the `@import` for `@font-face` declarations.
