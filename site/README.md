# aish marketing site

First-pass marketing landing page for **aish** — the AI-native shell.

Static, zero-build: plain HTML + CSS + JS. Open `index.html` directly or serve
the folder.

## Run locally

```
python3 -m http.server 8080 --directory site
# then open http://localhost:8080
```

## Files

| File | Purpose |
|---|---|
| `index.html` | Page markup — nav, hero + terminal demo, problem, features, comparison, roadmap, install/CTA, footer |
| `styles.css` | Design system: dark mode, violet accent, 4-pt grid, responsive, reduced-motion |
| `app.js` | Terminal typing demo, scroll reveal, nav state, copy-to-clipboard, tab-visibility pause |
| `DESIGN_REF.md` | Project design north-star (color, type, spacing, motion decisions) |

## Design

Follows the LightHeart Ventures universal design system (`lightheartventures-design`
skill). Key decisions captured in [`DESIGN_REF.md`](./DESIGN_REF.md):

- **Dark mode**, violet accent chosen so CTAs don't collide with terminal
  green/red semantics.
- Two fonts (Plus Jakarta Sans + JetBrains Mono), fluid `clamp()` type scale.
- 4-point spacing grid; desktop sections fill `100vh`/`100dvh`, hero is the
  mobile exception.
- Every button animates on hover **and** press; all motion respects
  `prefers-reduced-motion`; animations pause when the tab is hidden.
- No emojis (inline SVG icons), no hero badge pill.

## First-pass scope / next steps

- [ ] Real OG/Twitter share image + favicon set
- [ ] Mobile hamburger menu for the nav links (hidden < 720px today)
- [ ] Case studies / testimonials section
- [ ] Pull copy from `marketing/` as it firms up
- [ ] Wire analytics + a real install/download path per platform
