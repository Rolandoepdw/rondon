---
name: Monolith Deep
colors:
  surface: '#061423'
  surface-dim: '#061423'
  surface-bright: '#002d66'
  surface-container-lowest: '#020f1e'
  surface-container-low: '#0e1c2c'
  surface-container: '#001a3d'
  surface-container-high: '#1d2b3b'
  surface-container-highest: '#283646'
  on-surface: '#d5e4f9'
  on-surface-variant: '#c3c6d3'
  inverse-surface: '#d5e4f9'
  inverse-on-surface: '#243142'
  outline: '#8d909d'
  outline-variant: '#434751'
  surface-tint: '#aec6ff'
  primary: '#aec6ff'
  on-primary: '#002e6a'
  primary-container: '#004395'
  on-primary-container: '#91b4ff'
  inverse-primary: '#2b5caf'
  secondary: '#aec6ff'
  on-secondary: '#002e6a'
  secondary-container: '#074698'
  on-secondary-container: '#97b8ff'
  tertiary: '#aec6ff'
  on-tertiary: '#002e6a'
  tertiary-container: '#004395'
  on-tertiary-container: '#91b4ff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#aec6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#014395'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#aec6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#014395'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#aec6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#014395'
  background: '#061423'
  on-background: '#d5e4f9'
  surface-variant: '#283646'
  surface-base: '#000b1a'
  on-surface-muted: '#80a1ca'
  accent-glow: '#4d8eff'
typography:
  display:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  score-num:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 18px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  container-padding: 16px
  gutter: 12px
---

## Brand & Style

The design system is centered on **Systematic Monochromatism**, evolving the previous "Vigilant Minimalism" into a more cohesive, high-fidelity experience. By unifying the primary, secondary, and tertiary channels into a single deep blue hue (`#004395`), the UI eliminates visual noise and focuses entirely on structural hierarchy and content.

The aesthetic follows a **Corporate / Modern** movement with **Minimalist** restraint. It evokes a sense of deep-sea stability and technological precision. The emotional response is one of absolute reliability—a "digital bedrock" for urban safety and professional coordination. The interface relies on varying luminance levels of the core blue to guide the eye, creating a sophisticated environment where information density feels organized rather than overwhelming.

## Colors

The palette is strictly monochromatic, utilizing the `#004395` core to derive all functional variants. This ensures the dark mode experience is immersive and reduces chromatic aberration during low-light use.

- **Primary / Secondary / Tertiary:** All unified to `#004395`. Differentiation between actions is handled through luminance shifting (tints and shades) rather than hue changes.
- **Surface Strategy:** The background uses a near-black "Deep Midnight" (`#000b1a`). Containers and cards use a progressively lighter "Navy Container" (`#001a3d`) to create depth without introducing new colors.
- **Contrast:** High-priority text and icons utilize a brightened "Sky Blue" tint to ensure WCAG AAA compliance against the dark base.
- **Functional States:** Error states are the only exception to the monochromatic rule, utilizing a desaturated ruby red only when critical intervention is required.

## Typography

This system utilizes **Inter** for its neutral, systematic qualities that align with the monochromatic aesthetic.

- **Scale:** The hierarchy is aggressive to compensate for the lack of color-based emphasis. High-weight headlines provide the "anchor" for each view.
- **Micro-copy:** Metadata and labels use `label-caps` to create a visual distinction from body copy through texture (letter-spacing and casing) rather than hue.
- **Numerical Data:** `score-num` is optimized for tabular data and safety ratings, ensuring legibility at a glance without needing colored backgrounds.

## Layout & Spacing

The layout is governed by a **4px baseline grid**, ensuring mathematical rigor in every alignment. 

- **Grid:** A 12-column fluid grid on desktop provides flexibility for data-heavy dashboards. On mobile, a 4-column grid ensures content remains readable.
- **Density:** High density is encouraged for data lists, while generous vertical margins (`xl`) are used to separate primary functional blocks.
- **Reflow:** On smaller viewports, sidebars collapse into bottom sheets, and the `container-padding` remains a strict 16px to maintain a safe touch-gutter.

## Elevation & Depth

Depth is achieved through **Luminance Stacking**. Since the hue is constant, depth is communicated by increasing the lightness of the surface as it "approaches" the user.

- **Level 0 (Base):** Deepest shade (#000b1a).
- **Level 1 (Cards):** Mid-shade (#001a3d).
- **Level 2 (Modals/Pop-overs):** Lighter shade (#002d66).
- **Outlines:** Instead of heavy shadows, use **Low-contrast outlines** (1px solid #004395 at 30% opacity) to define boundaries between elements of the same elevation level.
- **Shadows:** Use a single "Deep Ambient" shadow (0px 12px 32px rgba(0,0,0,0.6)) only for transient elements like context menus and floating action buttons.

## Shapes

The shape language is **Soft (0.25rem)**. This provides a professional, "tooled" appearance that feels structural and intentional.

- **Actionable Elements:** Buttons and inputs share the same radius for a unified interactive language.
- **Large Containers:** Cards and sections use the `rounded-lg` (0.5rem) token to provide a slightly softer frame for high-density content.
- **Icons:** Must be geometric and linear, utilizing a consistent stroke weight that mimics the Inter typeface's stems.

## Components

- **Buttons:**
    - *Primary:* Filled with the core Primary color (#004395). Text is white.
    - *Secondary:* Ghost style with a 1px border of the Primary color.
    - *Tertiary:* Text-only, utilizing the `accent-glow` light blue tint for the label.
- **Input Fields:** Background matches Level 1 surface. Borders are subtle Primary Blue. Focus states utilize a subtle glow effect (box-shadow) in the primary hue.
- **Cards:** No shadows by default. Use Level 1 surface color with a 1px `outline-variant` border to ensure definition against the Level 0 background.
- **Chips & Badges:** Used for status. All chips use the same dark blue background; status is conveyed through the text label (e.g., "ACTIVE", "RESOLVED") using `label-caps`.
- **Lists:** Items are separated by 1px horizontal lines in a dimmed Primary tint. No zebra-striping; use hover states (10% Primary overlay) to indicate interactivity.