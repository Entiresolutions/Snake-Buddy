# Product Requirements Document (PRD) - Snake Game

## 1. Overview
**Snake Game** is a modern Flutter recreation of the classic arcade Snake game with animated modular sprites, rich food varieties, dynamic scoring, swipe/keyboard dual input controls, and retro audio effects.

---

## 2. Core Objectives & Scope
- Provide a smooth, deterministic 60fps arcade snake gameplay loop.
- Support both desktop (WASD / Arrow keys) and mobile (Swipe gestures + touch) form factors.
- Use a 14-sprite modular snake rendering system (ClearCode standard) for smooth corner transitions and natural head/tail movement.
- Offer multi-tiered fruit pickups with varied scoring values and pulsing animations.
- Implement low-latency sound effects for eating, starting, and game-over events.

---

## 3. Game Mechanics & Complete Logic

### 3.1 Board Grid & Dimensions
- **Grid Size:** $20 \times 15$ ($Rows = 20$, $Cols = 15$).
- **Coordinates:** Represented as `[col, row]` or `[x, y]` where:
  - $0 \le x < 15$
  - $0 \le y < 20$
- **Cell Size:** Dynamically computed from viewport constraints to maintain square aspect ratios while maximizing screen real estate.
- **Board Framing:** A distinct border boundary (`AppColors.boardFrame`) wraps the grid with both a container border and custom canvas perimeter stroke, ensuring clear visual separation between the play board and screen background.

### 3.2 Snake State & Representation
- **Body Representation:** `List<List<int>> snake = [[7, 9], [7, 10], [7, 11]];`
  - Index `0` is always the **Head**.
  - Subsequent indices are **Body Segments**.
  - The last index is the **Tail**.
- **Unique Segment IDs:** `List<int> segIds` tracks segments across animation frames to support smooth `AnimatedPositioned` tween transitions without glitching.
- **Initial Direction:** Facing `'up'`.

### 3.3 Movement & Turn Timing
- **Tick Rate:** Logic updates every $260\text{ ms}$ (`Duration(milliseconds: 260)`).
- **Direction Lock:** `direction` (active) and `nextDirection` (buffered input) prevent $180^\circ$ suicidal instant reversals during the same tick (e.g., pressing `down` while moving `up` is ignored).
- **Head Calculation:**
  - `'up'`: `[head[0], head[1] - 1]`
  - `'down'`: `[head[0], head[1] + 1]`
  - `'left'`: `[head[0] - 1, head[1]]`
  - `'right'`: `[head[0] + 1, head[1]]`

### 3.4 Collision Detection & Death Animation
1. **Wall Collisions:**
   - If `newHead[0] < 0 || newHead[0] >= cols || newHead[1] < 0 || newHead[1] >= rows` $\implies$ **Game Over**.
2. **Self Collisions:**
   - If `snake.any((seg) => seg[0] == newHead[0] && seg[1] == newHead[1])` $\implies$ **Game Over**.
3. **Collision Feedback (Hit Star Animation):**
   - On death collision, tick movement halts, `over.mp3` triggers (if sound is enabled), and a dizzy cartoon star burst (4 golden stars orbiting in an ellipse) animates around the snake head coordinates before displaying the Game Over dialog.

### 3.5 Food Varieties & Spawning Algorithm
- **Food Enum & Points:**
  | Food Type | Fruit Asset | Points | Spawn Chance |
  |---|---|---|---|
  | `FoodType.red` | `apple.png` | 1 | 50% |
  | `FoodType.blue` | `blueberry.png` | 2 | 25% |
  | `FoodType.purple` | `grape.png` | 3 | 15% |
  | `FoodType.yellow` | `banana.png` | 5 | 10% |
- **Safe Spawning Rule:** Food coordinates $(x, y)$ are generated using `Random()`. A position is validated against the active snake coordinates. If occupied, the engine re-rolls until a free grid cell is selected.

### 3.6 Growth & Tail Truncation
- When the head collides with food:
  - Score increases by `foodPoints(type)`.
  - SFX `eat.mp3` triggers.
  - `pendingGrowth` counter increments.
  - A new food item is generated safely.
- On standard movement tick:
  - If `pendingGrowth > 0`, tail is not removed and `pendingGrowth` is decremented by 1.
  - Otherwise, tail segment is removed (`snake.removeLast()`), keeping length constant.

### 3.7 Sprite Selection Logic (ClearCode 14-Sprite Engine)
Each body segment is mapped to its appropriate asset based on adjacent segment directions:
- **Head:** `head_up.png`, `head_down.png`, `head_left.png`, `head_right.png` determined by vector $(head - segment_1)$.
- **Tail:** `tail_up.png`, `tail_down.png`, `tail_left.png`, `tail_right.png` determined by vector $(segment_{n-1} - tail)$.
- **Straight Body:** `body_horizontal.png` or `body_vertical.png`.
- **Corner Turns:** `body_topleft.png`, `body_topright.png`, `body_bottomleft.png`, `body_bottomright.png` calculated by evaluating $(prev - current)$ and $(next - current)$ deltas.

---

## 4. App Navigation & User Interaction
1. **Startup:** A native light launch splash (#F5F9EE) is followed by an animated
   in-app splash. The in-app splash loads saved settings and pre-caches gameplay
   sprites and fruit images before navigating to Home.
2. **Home:** Provides:
   - Primary **PLAY** pill button to begin a round immediately.
   - **SETTINGS** secondary action button.
   - **Top-Left THEME Shortcut:** Tactile pill button (`AppColors.surface`, 1.5dp border, subtle elevation) featuring a palette icon, `THEME` label, and an automatic notification badge when unviewed canvases are unlocked; navigates directly to the Theme gallery screen.
   - **High Score Display:** Emerald-tinted `StatChip` displaying career best score.
   - **Hero Card Animated Snake:** A unified 4-segment ClearCode snake (`tail_left`, `body_horizontal`, `body_horizontal`, `head_right`) rendered seamlessly with subpixel overlap (`-0.5dp`), native 40dp scale, and `FilterQuality.medium`. The entire snake floats in a calm, harmonic elliptical glide ($2600\text{ms}$) with a dynamic soft ground shadow and automatically reflects the active Canvas Theme colors.
   - **Animated Fruit Parade:** Tiered fruit pickups (Apple, Blueberry, Grape, Banana) with looping pulse animations and matching color halos.
3. **Play:** Selecting Play opens the game and starts a new round automatically;
   there is no separate Start or in-game Restart button on the play screen, keeping the game canvas clean and focused.
4. **Pause & Exit:** The game AppBar provides pause/resume and Home actions.
   The pause menu can resume play or return Home, while HUD chips above the board
   display current score and best score.
5. **Game Over:** Displays final score, best score, and optional celebratory badge.
   The dialog offers Restart ("PLAY AGAIN" starts a fresh round immediately) and Home.

## 5. User Input & Game Controls
1. **Desktop:** Keyboard focus via `RawKeyboardListener`.
   - Arrow Keys & WASD controls.
2. **Mobile / Touch:** `GestureDetector` with vertical/horizontal drag thresholds:
   - $|\Delta y| > 5$: Up / Down detection.
   - $|\Delta x| > 5$: Left / Right detection.
3. **On-screen controls:** Optional directional buttons can be selected in
   Settings instead of swipe input.
4. **Game loop:** Difficulty controls the timer and matching sprite tween:
   Easy 300ms, Normal 240ms, Hard 160ms. Starting or restarting a round plays
   `start.mp3` when sound is enabled.

## 6. Settings & Persistence
- Sound effects, vibration, difficulty, control type, and grid visibility are
  configured and persisted locally using `shared_preferences`. High score is
  automatically tracked and updated across sessions.
- The Settings screen provides grouped sections for Appearance (Theme selection), Audio & Feedback, and Gameplay.
- Settings are shared with an active game; difficulty changes update the tick
  timer live.

## 7. Canvas Themes & Progressive Unlock System

### 7.1 Overview
Players unlock new board and snake color themes ("Canvases") progressively as their career high score increases. While app chrome (AppBar, dialogs, cards, buttons) strictly retains the Fresh Meadow Light aesthetic, the game board checkerboard, border frames, fruit halos, and snake sprites transform to match the active canvas.

### 7.2 Theme Collection & Thresholds
| ID | Canvas Name | Unlock Score | Board Light / Dark | Board Frame | Snake Hue / Target | Halo Opacity |
|---|---|---|---|---|---|---|
| `meadow` | **Fresh Meadow** | 0 (Default) | `#AAD751` / `#A2D149` | `#87B334` | Original Sprite Colors (No filter) | 0.24 |
| `ocean` | **Ocean Breeze** | 15 | `#A9DDF0` / `#9AD3E8` | `#4FA3C7` | Coral Orange ($\approx 18^\circ$) | 0.24 |
| `desert` | **Sunset Desert** | 35 | `#F4DDA8` / `#EDD398` | `#C99A4A` | Deep Purple ($\approx 275^\circ$) | 0.24 |
| `candy` | **Candy Pop** | 60 | `#FBCFE3` / `#F7C0DA` | `#E58AB5` | Aqua Teal ($\approx 185^\circ$) | 0.24 |
| `frost` | **Frosty Peak** | 100 | `#E6F1F9` / `#D8E8F4` | `#9DBBD3` | Magenta ($\approx 320^\circ$) | 0.24 |
| `midnight` | **Midnight Neon** | 150 | `#2E3B5A` / `#27334F` | `#141C30` | Neon Lime ($\approx 90^\circ$, 1.15 sat, 1.1 bright) | 0.35 |

### 7.3 Unlock Rules & Migration
1. **Unlock Trigger:** A canvas is unlocked whenever the player's best score $\ge \text{unlockScore}$.
2. **Permanent Unlocks:** Once unlocked, a canvas remains permanently unlocked in `shared_preferences` under `canvas.unlockedThemes`.
3. **Migration:** On initial launch, any canvas with `unlockScore` $\le$ existing high score is automatically unlocked.
4. **Mid-Game Unlocks:** When a round's score surpasses a locked canvas threshold:
   - Unlock state is persisted immediately.
   - A non-blocking banner pill ("New canvas unlocked: <Name>!") appears at the top of the board for ~2 seconds without pausing gameplay.
   - The active board does not auto-switch mid-round to avoid disorienting the player.
5. **Game Over Dialog Integration:** If new canvases were unlocked during the round, a celebratory announcement row appears above the action buttons with an instant "USE NOW" CTA.
6. **Selection Guards:** Selecting a locked canvas is rejected at the controller level; invalid or locked stored theme IDs safely fall back to `meadow`.

### 7.4 Runtime Snake Recoloring (Non-Destructive)
- Original sprite PNG assets are strictly preserved.
- The 14 snake sprites are rendered under a single `ColorFiltered` layer using a calculated $4 \times 5$ `ColorFilter.matrix`.
- The dominant base hue of the original blue snake sprites is $227.85^\circ$ (`#5B7BF9`). Rotating hue by $(\text{targetHue} - 227.85^\circ)$ shifts only saturated blue pixels, leaving neutral whites (sclera `#F4F4F4`) and blacks (pupils `#000000`) untouched.

### 7.5 Cross-Screen Theme Reflection & Indicator Badges
- Theme changes apply live across the application:
  - Game play board (checkerboard colors, outer frame, custom canvas perimeter stroke, grid lines, and fruit halo opacity).
  - Snake sprites during active gameplay, launch/in-app splash screen, and the Home hero card preview.
- A "NEW" indicator dot appears on the Home screen's top-left Theme shortcut button whenever newly unlocked canvases remain unviewed, automatically clearing when `markAllAsViewed()` is executed upon visiting the Theme gallery.

---

## 8. Shared Color Palette & Design Tokens
- `lib/theme/app_colors.dart` is the single source of truth for application UI
  colors, including the Fresh Meadow Light brand colors (#F5F9EE background,
  fresh meadow greens, two-tone checkerboard, text/icon colors, danger
  feedback, surfaces, borders, and shadows).
- App screens, widgets, the game screen, and Material 3 theme reference
  `AppColors`, `AppSpacing`, `AppRadius`, and `AppTextStyles` instead of defining
  duplicate literals.
- Add or adjust shared UI design tokens in these files when extending the
  design system.

## 9. Audio Architecture
- `AudioPlayer` instances with pre-cached assets:
  - `eat.mp3`: 0.8 volume on fruit ingestion.
  - `start.mp3`: 0.9 volume on game start/resume.
  - `over.mp3`: 1.0 volume upon collision death.
