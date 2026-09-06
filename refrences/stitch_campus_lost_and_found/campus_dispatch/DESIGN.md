---
name: Campus Dispatch
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#434655'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#565e74'
  on-secondary: '#ffffff'
  secondary-container: '#dae2fd'
  on-secondary-container: '#5c647a'
  tertiary: '#943700'
  on-tertiary: '#ffffff'
  tertiary-container: '#bc4800'
  on-tertiary-container: '#ffede6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#dae2fd'
  secondary-fixed-dim: '#bec6e0'
  on-secondary-fixed: '#131b2e'
  on-secondary-fixed-variant: '#3f465c'
  tertiary-fixed: '#ffdbcd'
  tertiary-fixed-dim: '#ffb596'
  on-tertiary-fixed: '#360f00'
  on-tertiary-fixed-variant: '#7d2d00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  code-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  2xs: 0.25rem
  xs: 0.5rem
  sm: 0.75rem
  md: 1rem
  lg: 1.5rem
  xl: 2rem
  2xl: 3rem
  edge-mobile: 1rem
  gutter-mobile: 0.5rem
---

## Brand & Style

This design system drives a utilitarian, high-density lost-and-found mobile utility for university campuses. Designed to counter hyper-decorated, generic SaaS trends, the interface prioritizes speed, legibility, and physical clarity over decorative delight.

### Emotional Demeanor
- **Urgent & Dependable:** Students, staff, and campus security interact with the system during moments of stress or friction. The UI communicates calm authority and absolute reliability.
- **Physical & Grounded:** Clean hairline strokes, structured data cells, and paper-like contrast emulate physical administrative logs and high-end field tools.
- **Anti-Decorative:** Absolutely no blurred backdrops, oversized pill surfaces, floating decorative orbs, or atmospheric gradients. Everything visible serves direct identification or recovery workflows.

### Design Movement
- **Swiss Precision / Functional Minimalism:** Rational layout, typographic discipline, dense metadata grids, and explicit 1px boundary delineation.

## Colors

The palette operates on a disciplined scale of Slate and Zinc neutrals paired with a singular high-contrast procedural blue accent.

### Palette Roles
- **Canvas Base (`#F8FAFC`):** Slate-50 ground plane providing structural separation against pure white content blocks.
- **Surface Elevation (`#FFFFFF`):** Base container for inventory cards, inputs, dialogs, and detail sheets.
- **Hairline Dividers & Borders (`#E2E8F0`):** Slate-200 1px borders define structure without visual clutter.
- **Typography Primary (`#0F172A`):** Slate-900 for headlines, item titles, key identifiers, and high-priority states.
- **Typography Secondary (`#64748B`):** Slate-500 for timestamps, building codes, metadata labels, and subtle helper strings.
- **Action & Brand Accent (`#2563EB`):** High-clarity cobalt blue reserved exclusively for interactive links, filter highlights, primary taps, and progress cues.
- **Critical Action (`#0F172A`):** Slate-900 primary buttons for maximum utilitarian contrast.
- **Status Success (`#16A34A`):** Green-600 indicating returned, verified, or matched items.
- **Status Danger (`#DC2626`):** Red-600 reserved for stolen flags, dispute reports, and destructive actions.

Do not introduce tinted shadows or multi-stop gradients. High-contrast surface separation must rely on `#E2E8F0` structural outlines and background contrast.

## Typography

The type system uses Inter across all viewports. Type hierarchy is maintained through strict optical weights (Regular 400, Semi-Bold 600, Bold 700) rather than oversized scale jumps.

### Implementation Rules
- Item IDs, campus zone abbreviations (e.g., `SCI-B-204`), and status tags utilize uppercase tracking with `label-sm` (`letter-spacing: 0.04em`).
- Body text prioritizes compact horizontal rhythm. Avoid generous line spacing; keep lines close to maintain high data density.
- Numeric values, times, and phone numbers must be set with tabular figure settings (`font-feature-settings: 'tnum' on, 'cv05' on`).

## Layout & Spacing

A strictly bounded, 4px-based geometric spatial grid drives the visual rhythm.

### Layout Philosophy
- **Screen Margins:** Fixed 16px (`1rem`) horizontal outer margins on mobile screen boundaries.
- **Card Padding:** Internal card padding is strictly uniform at 12px or 16px. Never use oversized card padding that forces excessive vertical scrolling.
- **Compact Stacking:** List views rely on 8px row gaps or 0px seamless edge-to-edge lists divided by 1px `#E2E8F0` hairline rules.
- **Utility Strips:** Metadata strips (location, time reported, building sector) employ 4px horizontal gap alignments for tag clusters.

## Elevation & Depth

This design system completely discards heavy drop shadows, diffused colored glows, and atmospheric drop-offs. Visual separation relies on structural layering and perimeter lines.

### Depth Hierarchy
- **Base Ground:** Background color `#F8FAFC`.
- **Containers & Tiles:** Solid `#FFFFFF` surfaces wrapped in a single, crisp 1px stroke of `#E2E8F0`.
- **Interactive Modals & Action Sheets:** Flat white surfaces edged with a crisp border (`1px solid #CBD5E1`) paired with a minimal, direct functional drop shadow: `0 4px 6px -1px rgba(15, 23, 42, 0.08), 0 2px 4px -2px rgba(15, 23, 42, 0.04)`.
- **Dividers:** Explicit 1px horizontal and vertical rules in `#E2E8F0` separate list rows and content segments.

## Shapes

Corners are disciplined, subtle, and utilitarian. Overly rounded or pill-shaped containers are strictly forbidden.

### Geometry Specifications
- **Cards, Panels & Containers:** 8px (`0.5rem`) corner radius.
- **Buttons, Field Inputs & Badges:** 6px (`0.375rem`) corner radius.
- **Thumbnails & Media Previews:** 6px corner radius with an inner inset border (`inset 0 0 0 1px rgba(15, 23, 42, 0.08)`) to preserve hard edge definition on pale images.
- **System Badges & Chips:** Subtle 4px to 6px radii. Never use 9999px pills.

## Components

### Buttons
- **Primary:** Solid `#0F172A` background, `#FFFFFF` text, 6px corner radius, 40px height. Active/Pressed state shifts to `#1E293B`.
- **Secondary / Action Accent:** `#2563EB` background, `#FFFFFF` text. Used for immediate recovery or submission triggers.
- **Outline / Filter:** Transparent background, 1px solid `#E2E8F0`, `#0F172A` text. Hover/Active state shifts to `#F1F5F9`.
- **Destructive:** 1px solid `#DC2626`, `#DC2626` text, transparent background. Active state uses `#FEF2F2` fill.

### Inputs & Search Bars
- **Container:** 40px height, `#FFFFFF` background, 1px solid `#E2E8F0`, 6px border radius, 12px horizontal padding.
- **Typography:** `body-md` in `#0F172A`, placeholder in `#64748B`.
- **Focus State:** Strict 1px solid `#2563EB` paired with an unblurred 1px outer ring in `#93C5FD` (`box-shadow: 0 0 0 1px #2563EB`).

### Item Cards
- Surface `#FFFFFF` bordered by 1px `#E2E8F0`, 8px radius, 12px or 16px internal padding.
- Displays high-contrast title (`headline-sm`), monospaced/uppercase location tag (`label-sm`), timestamp (`body-sm`), and a square 64x64px thumbnail with a 6px corner radius and hairline border.
- Bottom metadata line features inline categorical items separated by middle dots (`·`).

### Status Badges & Chips
- Rectangular with 4px corner radius. Internal padding: 2px vertical, 6px horizontal.
- **Active / Unclaimed:** `#F1F5F9` background, `#334155` text, 1px solid `#CBD5E1`.
- **Claim Pending:** `#EFF6FF` background, `#1D4ED8` text, 1px solid `#BFDBFE`.
- **Resolved / Returned:** `#F0FDF4` background, `#15803D` text, 1px solid `#BBF7D0`.

### Lists & Activity Feeds
- Grouped list rows separated by 1px `#E2E8F0` bottom borders.
- Zero horizontal margin within container cards.
- Left-aligned item icons or thumbnails, center-stacked title/subtitle, right-aligned compact timestamps in `label-sm` slate-500.