# aish Marketing Site — DESIGN_REF

North-star design decisions for the aish marketing site. Follows the LightHeart
Ventures universal design system; where they conflict, **this file wins**.

## Product

**aish** — the AI-native shell. No bash, just intent. Audience: developers,
DevOps/SRE, teams, researchers. Tone: confident, technical, calm-professional.

## Mode

**Dark mode** — fits the terminal/shell product and the developer audience.
Dark mode rules apply: no elevation shadows (depth via lighter surfaces),
brighter borders, off-white body text, separate dark palette.

## Color (5 max + semantics)

Split-complementary around a violet accent. Violet is deliberately chosen so the
CTA never collides with the terminal's own semantic colors (green = success,
red = error) — those stay reserved for meaning.

| Token | Hex | Role |
|---|---|---|
| `--bg` | `#0E0B16` | Dominant background (60%) — very dark violet-tinted neutral |
| `--surface` | `#171327` | Cards / elevated surfaces (30%) |
| `--surface-2` | `#201A33` | Second elevation (nested cards, code blocks) |
| `--border` | `#2C2545` | Borders (brighter than bg, dark-mode rule) |
| `--accent` | `#8B5CF6` | Accent (10%) — CTAs, links, active state |
| `--accent-hi` | `#A78BFA` | Accent hover (lighter) |
| `--accent-press`| `#7C3AED` | Accent press (darker) |
| `--text` | `#EDE9F5` | Off-white body text (not pure white) |
| `--text-strong` | `#FFFFFF` | Reserved: primary CTA text, logo, key H1 word |
| `--text-muted` | `#9A93B0` | Muted secondary text |
| `--ok` | `#34D399` | Semantic success (terminal output, checkmarks) |
| `--no` | `#F0606B` | Semantic negative (comparison X marks) |

Ambient accent glow (large blurred violet circles) used behind the hero only.

## Typography (2 fonts, ≤6 sizes)

- **Plus Jakarta Sans** — headings + body (variable weights 400/500/600/700).
- **JetBrains Mono** — terminal/code snippets only (a code element, not chrome).
- Sizes via `clamp()` fluid scale, all 4px-grid anchored:
  `--fs-hero` clamp(40→76), `--fs-h2` clamp(30→48), `--fs-h3` 24, `--fs-lead` clamp(18→22), `--fs-body` 16, `--fs-small` 14.
- Large headings: letter-spacing −0.03em, tightened line-height.
- `tabular-nums` on any in-place number (terminal counters).

## Spacing & layout

- 4-point grid throughout (4/8/12/16/24/32/48/64/96).
- Desktop/tablet sections fill `100vh` (paired with `100dvh`), content centered.
- **Hero is the mobile exception**: drop `min-height:100vh`, `justify-content:flex-start`, 24px top padding.
- `min-width:0` on all flex/grid children; `overflow-x:hidden` on html/body.
- Max content width 1120px, gutter 24px.

## Components

- Buttons: 2× horizontal padding; animate on **both** hover (arrow slide / fill)
  and press (scale-down 0.97); 4 states. Primary = filled accent, white text.
- Cards: icon inline next to title; dark-mode = bordered surfaces, no fill-only.
- Comparison table: check = `--ok`, X = `--no`, aish column highlighted.

## Motion

- Scroll-reveal fade-up via IntersectionObserver; staggered cascade (~90ms) for card grids.
- Typed terminal demo in hero (intent → streamed result), respects reduced-motion (shows final state instantly).
- `prefers-reduced-motion: reduce` overrides every animation.
- `visibilitychange` pauses the typing loop + glow when tab hidden.

## Mobile / platform

- `viewport-fit=cover`, `theme-color=#0E0B16`.
- Nav: `fixed` desktop, `sticky` mobile. No `backdrop-filter` on mobile (solid bg).
- No emojis (inline SVG icons, Lucide-style). No hero badge pill.
