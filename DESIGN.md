# Design System & Theme Specification - Snake Game (v2.0)

## 1. Visual Theme & Art Direction
Snake Game adopts the **"Fresh Meadow Light"** theme — a bright, joyful, organic aesthetic blending playful tactile mobile components with crisp classic arcade clarity. The theme replaces dark obsidian backgrounds and neon glows with warm meadow off-white canvases (`#F5F9EE`), crisp white tactile cards, vibrant natural greens, and juicy fruit accents. The snake and food sprites remain authentic to the ClearCode sprite system, enhanced with soft halos and ground shadows.

---

## 2. Color Palette & Design Tokens

### 2.1 Backgrounds & Surfaces
- **`background`:** `#F5F9EE` — Warm meadow canvas for all screens and native launch splashes.
- **`surface`:** `#FFFFFF` — Pure white for cards, dialogue sheets, HUD chips, and action surfaces.
- **`surfaceMuted`:** `#EAF2DE` — Subtle meadow tint for inactive controls, containers, and segmented button track backgrounds.
- **`surfaceSubtle`:** `#F0F5E8` — Ultra-light tint for hovered or inactive list items.
- **`border`:** `#D5E2C7` — Soft natural border defining cards, tiles, and chips.

### 2.2 Brand & Primary Colors
- **`primary`:** `#2E7D32` — Deep vibrant meadow green for primary action buttons, active switches, and header titles (WCAG AAA compliant: contrast ratio > 7:1 against `#FFFFFF` and `#F5F9EE`).
- **`primaryDeep`:** `#1B5E20` — Dark foliage green for strong iconography, headings, and focused states.
- **`primarySoft`:** `#C8E6C9` — Gentle pastel green for chip backgrounds, highlight pills, and stat containers.
- **`accentLime`:** `#76BA1B` — Energetic fresh lime for loading progress bars, playful underline accents, and secondary button accents.
- **`onAccent`:** `#FFFFFF` — High contrast white text on accent elements.
- **`onPrimary`:** `#FFFFFF` — Pure white on primary green elements.

### 2.3 Typography & Text Colors
- **`textPrimary`:** `#1A2E1C` — Dark forest charcoal providing > 11:1 contrast on white and meadow canvas.
- **`textSecondary`:** `#4A614D` — Medium moss green for subtitles, secondary metrics, and descriptions (> 4.5:1 contrast).
- **`textMuted`:** `#728876` — Subtle caption tone for footnotes and disabled states.

### 2.4 Board Colors (Default Fresh Meadow)
- **`boardLight`:** `#AAD751` — Classic light green checkerboard cell.
- **`boardDark`:** `#A2D149` — Vibrant slightly deeper green checkerboard cell.
- **`boardFrame`:** `#87B334` — Solid border boundary framing the game board (4.0dp outer container border + 3.0dp canvas perimeter stroke).
- **`boardGrid`:** `#334A752C` — Subtle grid line divider when grid lines are enabled.

### 2.5 Food Pickup Colors & Variants
| Fruit | Item Asset | Halo / Base Color | Text Variant |
|---|---|---|---|
| **Apple (Red)** | `apple.png` | `#E53935` | `#C62828` |
| **Blueberry (Blue)** | `blueberry.png` | `#1E88E5` | `#1565C0` |
| **Grape (Purple)** | `grape.png` | `#8E24AA` | `#6A1B9A` |
| **Banana (Yellow)** | `banana.png` | `#F9A825` | `#E65100` |

- **Fruit Halo:** `Color(0x26E53935)` / soft 24-40% opacity circular wash beneath fruit (opacity tunes with `CanvasTheme.haloOpacity`).
- **Ground Shadow:** `Color(0x1F1A2E1C)` — Soft circular shadow beneath fruit and snake head.

### 2.6 Feedback & Shadows
- **`danger`:** `#D32F2F` — Crimson red for Game Over title, suicide alerts, and destructive actions.
- **`dangerSoft`:** `#FFEBEE` — Soft red wash for warning dialog badges.
- **`shadow`:** `Color(0x141A2E1C)` — Light ambient drop shadow for cards and buttons.
- **`shadowElevated`:** `Color(0x241A2E1C)` — Medium elevation shadow for dialogs and modals.

### 2.7 Canvas Themes (Play Board & Snake Palettes)
Board and snake coloring are driven dynamically by `CanvasTheme` (`lib/theme/canvas_themes.dart`), while all chrome stays Fresh Meadow Light:
1. **Fresh Meadow (`meadow`):** Default (0 pts). Board `#AAD751` / `#A2D149`, frame `#87B334`, grid `#334A752C`. Snake: Original sprite assets (no color filter).
2. **Ocean Breeze (`ocean`):** 15 pts. Board `#A9DDF0` / `#9AD3E8`, frame `#4FA3C7`, grid `#332B6F8F`. Snake: Coral Orange (target hue $18^\circ$).
3. **Sunset Desert (`desert`):** 35 pts. Board `#F4DDA8` / `#EDD398`, frame `#C99A4A`, grid `#33A8793A`. Snake: Deep Purple (target hue $275^\circ$).
4. **Candy Pop (`candy`):** 60 pts. Board `#FBCFE3` / `#F7C0DA`, frame `#E58AB5`, grid `#33B84C80`. Snake: Aqua Teal (target hue $185^\circ$).
5. **Frosty Peak (`frost`):** 100 pts. Board `#E6F1F9` / `#D8E8F4`, frame `#9DBBD3`, grid `#33426E8F`. Snake: Magenta (target hue $320^\circ$).
6. **Midnight Neon (`midnight`):** 150 pts. Board `#2E3B5A` / `#27334F`, frame `#141C30`, grid `#26AAB8E0`. Snake: Neon Lime (target hue $90^\circ$, 1.15 sat, 1.1 bright), halo opacity 0.35.

---

## 3. Typography Specifications
Fonts are bundled locally in `assets/fonts/` for 100% offline functionality.

- **Headings & Scores:** **Fredoka** (Rounded, playful, bold geometry).
  - `displayLarge`: 40sp, FontWeight 700.
  - `displayMedium`: 32sp, FontWeight 700.
  - `appBarTitle`: 20sp, FontWeight 700, letterSpacing 0.5.
  - `scoreLarge`: 32sp, FontWeight 700.
  - `scoreChip`: 20sp, FontWeight 700.
- **Body & Controls:** **Nunito** (Clean, legible, rounded sans-serif).
  - `bodyLarge`: 16sp, FontWeight 600.
  - `bodyMedium`: 14sp, FontWeight 500.
  - `bodySmall`: 12sp, FontWeight 500.
  - `labelLarge`: 15sp, FontWeight 700, letterSpacing 0.5.
  - `labelMedium`: 13sp, FontWeight 700.

---

## 4. Shapes & Radius Tokens (`AppRadius`)
- `xs`: 6dp — Mini chips and status dots.
- `sm`: 10dp — D-pad buttons and small action tiles.
- `md`: 16dp — Standard cards (`AppCard`), settings tiles, and board corners.
- `lg`: 22dp — Dialogs and hero containers.
- `pill`: 999dp — Primary pill CTA buttons, HUD stat chips, and segmented pills.

---

## 5. Spacing Tokens (`AppSpacing`)
- `xs`: 4dp
- `sm`: 8dp
- `md`: 12dp
- `lg`: 16dp
- `xl`: 24dp
- `xxl`: 32dp

---

## 6. Screens & Component Designs

### 6.1 Native Launch Splash
- Background `#F5F9EE` for Android (v21+, Android 12+) and iOS.
- Centered ClearCode snake head sprite (`assets/sprites/clearcode/head_right.png`).
- Seamless transition to Flutter engine with zero dark flash.

### 6.2 In-App Splash Screen
- Light background `#F5F9EE`.
- 4-segment ClearCode snake slides horizontally across the screen toward a pulsing apple.
- Pulsing apple fades as head reaches it.
- Title **SNAKE** in Fredoka (`#1B5E20`) with a stylish `#76BA1B` lime underline.
- Pill progress indicator with lime fill.
- Min duration 2700ms with parallel settings loading & image precaching.

### 6.3 Home Screen
- **Top-Left Theme Shortcut:** Tactile pill button in the top-left corner (`AppColors.surface`, 1.5dp border, subtle shadow, min 44dp height) with palette icon, "THEME" label, and optional lime indicator dot when unviewed themes are unlocked. Tapping opens `ThemeScreen`.
- Centered hero card (`AppCard`) with a dynamically animated 4-segment ClearCode snake slithering horizontally above a parade of pulsing fruits. The snake automatically reflects active canvas recoloring.
- High score display inside an emerald-tinted `StatChip`.
- Large **PLAY** primary pill button with tactile press-down scale.
- Outlined **SETTINGS** secondary pill button.
- Clean footer with version indicator.

### 6.4 Game Play Screen
- **AppBar:**
  - Back/Home icon button on the left.
  - Centered "SNAKE" title in Fredoka.
  - Pause/Resume icon button on the right.
- **HUD Row (Above Board):**
  - "SCORE" chip with apple icon and live score.
  - "BEST" chip with crown/star icon and saved high score.
- **Board:**
  - Two-tone checkerboard (`#AAD751` / `#A2D149`) framed with `#87B334` border (4.0dp outer container border + 3.0dp canvas perimeter stroke).
  - Fruit with gentle halo and ground shadow.
  - ClearCode 14-sprite snake with smooth `AnimatedPositioned` interpolation matching active tick rate.
  - Hit feedback: Dizzy cartoon star burst (4 golden stars orbiting in an ellipse) animates around the snake head upon collision.
- **Bottom Area:**
  - Swipe mode: Subtle pill hint ("Swipe anywhere to turn"). In-game restart button is removed from the play screen to keep the viewport clean.
  - Button mode: D-pad controls (cross in portrait, compact row when height is constrained).
- **Pause Overlay:**
  - Soft scrim with centered white card: "Game Paused", "RESUME", and "HOME" buttons.

### 6.5 Settings Screen
- Grouped white cards (`AppCard`) with section headings in `primaryDeep`.
- **Appearance:** "Theme" tile featuring leading palette icon in `primarySoft`, subtitle indicating selected canvas name and unlock count (e.g. "Fresh Meadow • 1/6 unlocked"), 3-dot color swatch preview of the current canvas, and navigation chevron.
- **Audio & Feedback:** Sound effects toggle, Vibration toggle.
- **Gameplay:** Difficulty segmented button (Easy 300ms, Normal 240ms, Hard 160ms), Controls (Swipe / Buttons), Show grid lines switch.
- Changes update the running game engine immediately.

### 6.6 Theme Screen (Canvas Gallery)
- **Header Card:** Displays player's best score and overall unlock progress bar (e.g. "3 of 6 unlocked").
- **Live Interactive Preview Card:** Shows the currently active board palette, a mini 4-segment crawling snake with runtime recoloring applied, and a pulsing fruit pickup with matching halo.
- **Canvas Collection Grid:** Responsive grid cards (`isLandscape ? 340 : 260` max width) showcasing all 6 canvases:
  - Mini 80dp board preview rendered with exact checkerboard and frame colors.
  - "NEW" badge on newly unlocked canvases until viewed.
  - Three-dot palette swatch (boardLight, boardDark, snakeTarget).
  - Selected state: 2dp `AppColors.primary` border, check icon, and bold "Selected" label.
  - Unlocked state: "Tap to use" secondary callout.
  - Locked state: Grayscale/desaturation filter (0.24 saturation), 42% dark overlay, lock badge, unlock score requirement, and a mini progress bar showing high score toward unlock.

### 6.7 Game Over Dialog
- White rounded card with soft elevated shadow.
- Icon badge (Golden trophy if new best score achieved, danger badge otherwise).
- Big score readout and high score comparison.
- "NEW BEST!" celebratory badge when applicable.
- **Unlocked Canvas Celebration:** If one or more canvases were unlocked during the round, displays an animated banner highlighting the new canvas with an instant "USE NOW" button.
- Full-width "PLAY AGAIN" and secondary "HOME" buttons.

---

## 7. Motion & Micro-Interactions
- **Home Snake Slither Wave:** 1800ms repeating loop featuring a horizontal sinusoidal crawl ($\pm 14\text{dp}$), a phase-delayed vertical wave across the 4 segments ($\Delta y = 3.5\text{dp}$), continuous tilt adjustments ($\pm 0.05\text{ rad}$), subtle accordion squash-and-stretch ($\pm 3\%$), and an interactive ground shadow.
- **Fruit Pulse:** 2000ms looping scale (1.0x to 1.15x), `Curves.easeInOut`.
- **Snake Movement Tween:** `AnimatedPositioned` tween synchronized to `SettingsController.tickDuration`.
- **Hit Star Burst:** 800ms cartoon star burst on death collision (4 golden stars orbiting in a 3D ellipse around snake head with $2\pi$ rotation and scale spring bounce).
- **Lock Shake:** 300ms damped horizontal oscillation ($\pm 7\text{dp}$, 4 oscillations) when attempting to tap a locked canvas card, accompanied by an instructional SnackBar.
- **Unlock Banner Pill:** Non-blocking pill slides down and fades in at the top of the game board upon crossing an unlock threshold, holds for 2 seconds, and smoothly fades out without pausing play.
- **Button Press:** Scale down to 0.96 on pointer down, smooth bounce back on release (100ms).
- **Score Pop:** Brief 1.2x scale spring animation when points increase.
- **Reduced Motion:** When `MediaQuery.disableAnimations` is active, loops and transitions scale to instantaneous state changes.

---

## 8. Responsive Layout Architecture

### 8.1 Board Sizing Algorithm
The board has a fixed logical grid of $20\text{ rows} \times 15\text{ columns}$ ($15:20$ aspect ratio).
To ensure square pixels and prevent pixel distortion or clipping:
$$\text{cellSize} = \text{clamp}\left(\left\lfloor \min\left(\frac{\text{availWidth}}{15}, \frac{\text{availHeight}}{20}\right) \right\rfloor, 16, 44\right)$$
$$\text{boardWidth} = \text{cellSize} \times 15$$
$$\text{boardHeight} = \text{cellSize} \times 20$$
The board is strictly centered in its available space.

### 8.2 Responsive Orientations & Form Factors
- **Portrait (Standard Phones):**
  - Vertical stack: AppBar -> HUD Stat Row -> Board (centered) -> Controls / Swipe Hint.
- **Landscape / Short Viewport:**
  - Side-by-side row: Board on left ($15:20$), control panel & HUD chips on the right.
- **Tablets & Large Screens:**
  - Content constrained to `maxWidth: 640dp`, centered horizontally.
- **D-Pad Responsive Layout:**
  - Vertical space $\ge 140\text{dp}$: Classic Cross D-pad (Up button top, Left-Down-Right bottom row).
  - Constrained vertical space: Compact inline 4-button row ($[\leftarrow] [\uparrow] [\downarrow] [\rightarrow]$).
- **Accessibility & Touch Targets:**
  - Minimum tap target $48\text{dp} \times 48\text{dp}$ on all interactive elements.
  - Text scales cleanly up to $1.3\times$ without clipping or overflow.
