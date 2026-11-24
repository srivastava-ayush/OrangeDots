# OrangeShell — Animation & Design Philosophy

This document describes how motion works in **OrangeShell**, the vendored
Caelestia fork under `quickshell/caelestia/`, and the design ideas behind it.
It also covers the Hyprland-side compositor animations that share the same
visual language.

Everything below was read from the files in this checkout, not inferred from
setup notes. Where older audit documents disagree with the source, the source
wins — see [Verification note](#verification-note) at the end.

When handing this file to an agent for implementation work, point it at
[Building a new component](#building-a-new-component): that section is the
contract for deriving a new component's look and motion from what is documented
here.

## Contents

- [Two layers of motion](#two-layers-of-motion)
- [Layer 1: Hyprland compositor motion](#layer-1-hyprland-compositor-motion)
- [Layer 2: the shell's token system](#layer-2-the-shells-token-system)
- [Animation primitives in QML](#animation-primitives-in-qml)
- [Signature motion patterns](#signature-motion-patterns)
- [Design philosophy](#design-philosophy)
- [Standardization status](#standardization-status)
- [Building a new component](#building-a-new-component)
- [Where to change things](#where-to-change-things)
- [Validation](#validation)
- [Verification note](#verification-note)

## Two layers of motion

Motion is split by responsibility, and the two layers deliberately use
different vocabularies:

| Layer | Lives in | Animates | Vocabulary |
|---|---|---|---|
| **Compositor** | `hypr/modules/animations.lua` | Workspaces, windows, layers, borders, scratchpads | Named `ayu*` cubic-bezier curves + Hyprland `speed`/`style` |
| **Shell UI** | `quickshell/caelestia/` (C++ tokens + QML components) | Panels, popouts, cards, lock screen, wallpaper strip, colours | Semantic curve/duration tokens (`standard`, `emphasized`, `expressive*`) |

The compositor layer describes *objects arriving and leaving the screen*. The
shell layer describes *state changes inside a continuously present surface*.
Keeping them separate lets each use the tool that fits: Hyprland's declarative
animation leaves, and Qt's property animations/springs driven by shared tokens.

Both layers share the same high-level intent: directional, quick-to-settle
motion that communicates cause and effect without drawing attention to itself.
Game mode removes the compositor layer entirely — `services/GameMode.qml`
sets `animations:enabled` to `0` along with blur, shadows, gaps, rounding and
tearing — but the shell's own token-driven transitions remain.

## Layer 1: Hyprland compositor motion

Source: [`hypr/modules/animations.lua`](hypr/modules/animations.lua).
The config is Lua (`hl.curve`, `hl.animation`), not classic `.conf` syntax.

### The `ayu` curve family

| Curve | Control points `(c1, c2)` | Character |
|---|---|---|
| `ayuOpen` | `(0.22, 1.00)`, `(0.36, 1.00)` | Strong deceleration: arrives fast, settles softly. Used for anything entering. |
| `ayuClose` | `(0.25, 0.00)`, `(0.35, 1.00)` | Slow start, committed exit. Used for anything leaving. |
| `ayuMove` | `(0.25, 0.10)`, `(0.25, 1.00)` | Smooth, weighted travel for objects that stay on screen while moving. |
| `ayuLinear` | `(0.00, 0.00)`, `(1.00, 1.00)` | True linear, reserved for a value that must track its target 1:1. |

### Animation leaves

| Leaf | Speed | Curve | Style | Purpose |
|---|---|---|---|---|
| `workspacesIn` / `workspacesOut` | 3.5 | `ayuOpen` | `slidefadevert` | Vertical workspace changes with fade. |
| `windowsIn` | 3.2 | `ayuOpen` | `popin 10%` | Windows grow from slightly small. |
| `windowsOut` | 2.0 | `ayuClose` | `popin 60%` | Windows collapse and disappear. |
| `windowsMove` | 3.2 | `ayuMove` | — | Continuous repositioning. |
| `fadeIn` | 2.4 | `ayuOpen` | — | Appearing content. |
| `fadeOut` | 2.0 | `ayuClose` | — | Disappearing content. |
| `layersIn` | 2.6 | `ayuOpen` | `slidefade` | Shell/overlay surfaces arriving. |
| `layersOut` | 1.8 | `ayuClose` | `slidefade` | Shell/overlay surfaces leaving. |
| `border` | 3.2 | `ayuLinear` | — | Active-window border colour changes. |
| `specialWorkspace` | 3.6 | `ayuOpen` | `slidefadevert` | Scratchpad (`special:magic`, `special:misc`). |

In Hyprland's model a larger `speed` means a faster animation (a shorter
duration). Two patterns are visible in the table:

- **Entrances resolve faster than exits.** Every `In`/`Out` pair gives the
  incoming animation the higher speed (`windowsIn` 3.2 vs `windowsOut` 2.0,
  `layersIn` 2.6 vs `layersOut` 1.8, `fadeIn` 2.4 vs `fadeOut` 2.0), and the
  incoming window uses the gentler `popin 10%` while the outgoing one uses the
  more pronounced `popin 60%`. Content arrives quickly and subtly; it leaves
  with a slower, larger collapse and the matching `ayuClose` ease.
- **`ayuLinear` only for the border.** Border colour must follow focus
  continuously rather than ease into it, so the one non-eased curve in the
  system is used exactly once.

## Layer 2: the shell's token system

The shell does not scatter raw millisecond values through its QML. Motion is
defined as **design tokens** in C++, exposed to QML as `Tokens.anim`, and then
consumed through a small set of wrapper components.

### Curve tokens

`plugin/src/Caelestia/Config/tokens.hpp` defines `AnimCurves`. Each property
is a flat list of cubic-bezier control values; `anim.cpp` groups them in sixes
(`c1x, c1y, c2x, c2y, endX, endY`), calls `addCubicBezierSegment` on a
`QEasingCurve::BezierSpline`, and rebuilds every curve whenever any control
point changes.

| Token | Default control points | Read as |
|---|---|---|
| `standard` | `0.2,0, 0,1, 1,1` | Neutral, Material-style ease. |
| `standardAccel` / `standardDecel` | `0.3,0, 1,1, 1,1` / `0,0, 0,1, 1,1` | Directional variants. |
| `emphasized` | `0.05,0, 0.133,0.06, 0.167,0.4, 0.208,0.82, 0.25,1, 1,1` | Two-segment, attention-seeking curve. |
| `emphasizedAccel` / `emphasizedDecel` | `0.3,0, 0.8,0.15, 1,1` / `0.05,0.7, 0.1,1, 1,1` | Directional variants. |
| `expressiveFastSpatial` | `0.42,1.67, 0.21,0.9, 1,1` | Overshooting, springy object motion (fast). |
| `expressiveDefaultSpatial` | `0.38,1.21, 0.22,1, 1,1` | Default object motion. |
| `expressiveSlowSpatial` | `0.39,1.29, 0.35,0.98, 1,1` | Deliberate object motion. |
| `expressiveFastEffects` | `0.31,0.94, 0.34,1, 1,1` | Smooth, non-bouncy opacity/colour change (fast). |
| `expressiveDefaultEffects` | `0.34,0.8, 0.34,1, 1,1` | Default effects change. |
| `expressiveSlowEffects` | `0.34,0.88, 0.34,1, 1,1` | Deliberate effects change. |

The split between **spatial** and **effects** curves is the core idea: things
that *move* may overshoot and carry momentum; things that *fade or recolour*
must not bounce, because a bouncing opacity reads as a rendering glitch.

### Duration tokens

`AnimDurationTokens` in the same file defines the base durations (ms):

| Token family | Values |
|---|---|
| Graded | `small` 200, `normal` 400, `large` 600, `extraLarge` 1000 |
| Expressive spatial | `expressiveFastSpatial` 350, `expressiveDefaultSpatial` 500, `expressiveSlowSpatial` 650 |
| Expressive effects | `expressiveFastEffects` 150, `expressiveDefaultEffects` 200, `expressiveSlowEffects` 300 |

`AppearanceConfig.anim.durations.scale` (default `1`) multiplies each base
value at runtime in `appearanceconfig.cpp`, so one setting slows or speeds every
tween. Springs cannot use a duration, so `SpringAnim` scales their oscillator
instead (stiffness `/ t²`, damping `/ t`), which changes speed without changing
the shape of the bounce. The committed preset
`caelestia/shell-tokens.json` overrides only a size token
(`sizes.bar.innerWidth`), so all animation tokens currently run at their
native defaults. Curves and duration scales are global properties: they are
not part of the per-monitor override set.

### How tokens reach QML

```text
shell-tokens.json / built-in defaults
  → TokenConfig (C++, RootConfig, live JSON reload)
  → AnimCurves + AnimDurationTokens
  → AnimTokens rebuilds QEasingCurve objects / applies scale
  → QML: Tokens.anim.emphasized, Tokens.anim.durations.normal, …
  → Anim / AnchorAnim / CAnim / raw Animators
```

Because the native config watches the JSON files, editing a token takes effect
without a shell restart. The trade-off is that the curve/duration *token names*
are part of the compatibility boundary: renaming them would break both the
QML consumers and saved user overrides.

## Animation primitives in QML

All under `quickshell/caelestia/components/`.

| Component | Wraps | Behaviour |
|---|---|---|
| `Anim.qml` | `NumberAnimation` | Token-driven presets selected by `type`. `Standard*`/`Emphasized*` map to graded durations (`type % 4` → small/normal/large/extraLarge); emphasized types use the `emphasized` curve, standard types use `standard`. Expressive types map to their own duration+curve pair. Defaults to `Anim.DefaultSpatial`. |
| `AnchorAnim.qml` | `AnchorAnimation` | Same preset list as `Anim`, including the effects types, for properties that are positions rather than sizes. Defaults to `DefaultSpatial`. |
| `CAnim.qml` | `ColorAnimation` | Colour transitions with `FastEffects` / `DefaultEffects` / `SlowEffects` (150/200/300 ms, non-bouncy). Defaults to `SlowEffects`. |
| `SpringAnim.qml` | `SpringAnimation` | Named spring roles (`Surface`, `Anchor`, `Panel`, `PanelClose`, `Snap`, `Launcher`, `LauncherClose`, `Island`, `Dismiss`, `Reveal`, `Card`, `Content`) instead of per-site `spring`/`damping` numbers. `epsilon` stays at the call site because it is in the animated property's units. Time constant follows `anim.durations.scale`. |
| `AnimLoader.qml` | `Loader` | Cross-fade lifecycle: fade out with `FastEffects`, swap `sourceComponent`, fade in with `DefaultEffects`. Loading is asynchronous. |

A typical usage is a `Behavior` on a property — e.g. `Behavior on
fsTransitionProg { Anim {} }`, `Behavior on surfaceColour { CAnim {} }` in
`modules/desktop/DesktopWindow.qml`. This keeps animation declarative: QML
states *what* value should become, and the token decides *how* it gets there.

## Signature motion patterns

These are the concrete techniques that give the shell its feel.

### 1. One surface, retargetable springs

Popouts, the media island and wallpaper tiles use a retargetable spring rather
than a fixed-duration tween, because the target can change mid-flight. Each one
names a role in `components/SpringAnim.qml` instead of carrying its own numbers:

- **Popout surface** (`modules/taskbar/popouts/PopoutWrapper.qml`):
  `Behavior on implicitWidth`/`implicitHeight` with `SpringAnim { role:
  SpringAnim.Surface; epsilon: 1 }` (3.2 / 0.48). Sweeping across status icons
  retargets the spring instead of restarting an animation, so the panel flows
  from one menu size to the next. `epsilon: 1` stops sub-pixel updates once the
  surface is visually at rest, waking the render loop less.
- **Media island** (`modules/desktop/MediaIsland.qml`): `role:
  SpringAnim.Island` (3.4 / 0.30) opening, `SpringAnim.Dismiss` (4.0 / 0.40)
  closing, `epsilon: 0.002`. Crucially, **one** `revealProgress` value owns the
  whole reveal. Content stage and per-child stagger are *derived* remaps of that
  number. Reversing mid-flight keeps every child exactly where it was instead of
  jumping. The role is switched *before* retargeting, because changing tuning
  and target in the same update makes the first close frame snap.
- **Wallpaper cards** (`modules/wallpaperswitcher/WallpaperSwitcherItem.qml`):
  `role: SpringAnim.Card` (14 / 1.0) for the card morph and its gap
  compensation. This is stiffer and deliberately non-bouncy: a card change is an
  immediate response to a selection, and an overshoot here would make the row
  wobble. `epsilon: 0.25` on the position spring matches the 1px gap check.

### 2. Motion as state, not imperative sequences

`modules/lockscreen/LockView.qml` states the principle directly: one
`progress` value owns entrance, curtain and exit instead of imperative resets
across several animations. `contentProgress` is derived from it; entrance takes
the slow spatial token, unlock the fast one, both with a deliberate `OutCubic`
for a curtain that never overshoots; the lock icon's rotation, scale and opacity
are all pure functions of the progress. On sleep/resume the view can
`settle()` straight to the finished state without replaying its entrance.

The same idea appears in the wallpaper strip: entry offsets live in a
`Translate` transform, so the resting geometry is never touched and reopening
always replays from a clean state.

### 3. Direction and intent

Motion carries information about *where something came from*:

- Compositor `slidefadevert` for workspaces and `slidefade` for layers;
  `popin` with different amounts for windows opening vs closing.
- The wallpaper strip's highlighted card drops in from above while its
  neighbours sweep in from their own edge of the strip; the exit runs the same
  motion backwards, rebuilt from the strip's *current* state so a changed
  highlight cannot leave stale animation targets behind.
- Popout hover uses an 80 ms dwell and a 180 ms close bridge. A quick sweep
  across status icons resets the intent rather than flashing menus; keeping
  the old surface alive until the new target is deliberate avoids a flicker.

### 4. Restraint, with room for one flourish

Everyday motion avoids bounce: effects curves are smooth, card springs are
critically damped, and transient loaders fade out faster than they fade in.
The one explicit
celebration is the Nexus `AnimatedLogo.qml` intro — a 750° spin with settle
steps, `OutBack` overshoot at 1.05, and three stars that fade and bob in on
staggered pauses. It is a one-shot brand moment, then the stars continue as a
quiet infinite idle animation. `skipIntroAnimation` collapses it all to the
final frame for repeat visits.

### 5. Continuity through change

- Browsing previews the wallpaper on the live background, but only Enter/Space
  or a click commits the file; closing always drops the preview.
- With `dynamic` schemes, applying a wallpaper locks the preview palette until
  the CLI has written the new scheme, so the old colours never flash back.
- Panels are only instantiated while visible and their reveal progress is
  nonzero; shared services keep state alive across view unloads and shell
  reloads (`PersistentProperties`).
- Thumbnail `sourceSize` is held constant while a card morphs, and smoothing
  stays on during `PathView` motion — both choices prevent re-decoding or
  shimmer that would look like a stutter.

## Design philosophy

The motion rules above follow a few consistent beliefs:

1. **Name motion by role, not by number.** `FastEffects`, `DefaultSpatial`,
   `emphasized`, `ayuOpen`, `SpringAnim.Card` describe intent. A component says
   what kind of change it is; the shared layer decides the timing. This makes
   the desktop change tempo coherently and gives users one supported global
   control for animation speed (`anim.durations.scale`), which scales tween
   durations and spring time constants alike.
2. **Motion is a projection of state.** Prefer one source value plus derived
   properties over several animations that must be kept in sync. This is what
   makes interruptions, reversals and reload-time settling safe.
3. **Continuity beats spectacle.** Surfaces morph and stretch instead of
   popping between windows; springs retarget instead of restarting; the shell
   is one continuous blob-backed surface with panels attached to its edges.
   Motion explains the change of state rather than decorating it.
4. **Feedback is fast; context is slower.** Effects (opacity, colour, small
   fades) resolve in 150–300 ms. Spatial changes take 350–650 ms. Graded
   standard durations top out at 1000 ms for large transitions. Nothing that
   sits under the user's cursor should feel like it is making them wait.
5. **Physicality without toy-like bounce.** Overshoot is allowed for objects
   travelling through space, never for fades, colour or layout gaps. Springs are
   tuned per role in `SpringAnim` and stopped at a visible-rest epsilon.
6. **Direction is information.** Enter/exit, highlight movement and hover
   intent all have their own timing and travel so the eye can tell what is
   arriving, leaving, or merely being considered.
7. **The panel is one thing.** Popouts, Nexus, dashboard, launcher, sidebar
   and lock content are panels attached to a shared surface, often expanding
   into the same overlay/morph path rather than opening separate windows.
   Animated geometry is part of that identity.
8. **Performance is part of the design.** Fixed image request sizes during
   morphs, lazy/visibility-gated loaders, rest epsilons, and separation of
   live preview from committed state all exist to keep the motion smooth on a
   real desktop with real services running.
9. **Material 3 is the visual grammar.** Motion curves mirror Material's
   standard/emphasized and spatial/effects language; palettes come from
   runtime `scheme.json` with translucent, luminance-aware surfaces, and
   typography is tokenised in the same configuration object as animation.

## Standardization status

Motion is standardized in **structure**, not compressed into one uniform feel:
a launcher, a 12 px status pill and a wallpaper card should not move at the
same rate. So each surface names its motion and the shared layer owns the
numbers.

### What is centralized

| Concern | Single source |
|---|---|
| Curves | `Tokens.anim.*` (`AnimCurves` in `plugin/src/Caelestia/Config/tokens.hpp`) |
| Tween durations | `Tokens.anim.durations.*`, all multiplied by `anim.durations.scale` |
| Springs | `components/SpringAnim.qml` roles: `Surface`, `Anchor`, `Panel`, `PanelClose`, `Snap`, `Launcher`, `LauncherClose`, `Island`, `Dismiss`, `Reveal`, `Card`, `Content` |
| Colour transitions | `CAnim` with `FastEffects` / `DefaultEffects` / `SlowEffects` |
| Compositor curves and leaves | `hypr/modules/animations.lua` |

Rules that now hold across the shell:

- **Springs are named, not hand-tuned per file.** No QML outside
  `SpringAnim.qml` sets `spring` or `damping`; open/close differences are a
  `role` switch applied *before* the target moves, so reversal still keeps the
  spring's velocity. `epsilon` stays local because it is in the animated
  property's units.
- **No animation declares a token `type` and then discards its timing.** Sites
  that genuinely need a bespoke curve now state the duration and easing they
  use (`duration: Tokens.anim.durations.expressiveSlowSpatial * 0.55;
  easing.type: Easing.OutCubic`) instead of wearing a token label that the
  overrides make meaningless. A full-shell scan confirms **zero** such sites.
- **No imperative spring tuning.** No QML sets `spring`, `damping` or `mass`
  outside `SpringAnim.qml`, and there are no raw `SpringAnimation`,
  `ColorAnimation` or `AnchorAnimation` instances outside their wrappers.
- **One shared `Anim`.** `BannerList.qml` no longer shadows the component with a
  local `NumberAnimation`.
- **One speed control.** `anim.durations.scale` multiplies tween durations and
  also scales spring time constants (stiffness `/ t²`, damping `/ t`), so a
  spring keeps its shape and only changes speed. Identity at 100%. Springs speed
  up to 50% and no further, because Qt's fixed 16 ms integrator becomes unstable
  below that; at a setting of 0 tweens are instant while springs run at their
  fastest stable speed, and `LauncherWrapper` additionally disables its spring
  at 0 so the launcher opens instantly.
- **Compositor direction convention.** Entrances use `ayuOpen`, exits use
  `ayuClose` — including `workspacesOut`, which previously reused `ayuOpen`.

### Deliberate exceptions

These are bespoke on purpose, not drift:

| Site | Why |
|---|---|
| `modules/switcher/SwitcherWindow.qml`, Alt+Tab at 140 ms `OutCubic` | The window switcher must feel immediate; it keeps its own fast curve instead of a token or spring. |
| `modules/settings/common/AnimatedLogo.qml` | One-shot brand intro with an explicit storyboard (spin, settle steps, `OutBack` overshoot, staggered stars). |
| `components/widgets/CoverArt.qml` rotation, `modules/desktop/MediaIslandEq.qml`, `components/controls/LoadingIndicator.qml`, `components/controls/CircularProgress.qml`, `modules/dashboard/media/ClickWheel.qml` | Functional loops: record rotation, audio visualiser, indeterminate progress, 33⅓ RPM platter. The duration *is* the behaviour. |
| `components/controls/TextFieldBase.qml`, `bezierCurve: [0.2, 1, 0.21, 1, 1, 1]` | Damped variant of the fast spatial curve for caret travel. |
| `modules/taskbar/popouts/TrayMenu.qml`, `component NoAnim` with `duration: 0` | Explicitly disables a stacking transition; zero is the intent. |
| `EmojiPicker`, `SessionMenu*`, `WallpaperSwitcher*`, `Wallpaper` zoom, `SidebarWrapper`, `Clock`, `StateLayer`, `FilledSlider` | Token durations/easings multiplied by hand-picked factors, or a raw `Easing.*` where an exact curve matters. Motion still follows the global speed setting; only the factor is bespoke. |

### Remaining drift

A scan of all 319 QML files found 601 animation objects: 417 `Anim`, 37 `CAnim`,
13 `SpringAnim`, 5 `AnchorAnim`, 54 `NumberAnimation`, 47 `SequentialAnimation`,
24 `ParallelAnimation`, one `PropertyAnimation`, and one each of the raw
`SpringAnimation`/`ColorAnimation`/`AnchorAnimation` wrappers. So the shared
primitives cover the overwhelming majority, but **the shell is not literally
100% uniform**:

- **53 numeric `duration:` literals in 9 files.** Of these, 34 are the
  `AnimatedLogo` storyboard and 9 are `KbLayout`'s 70/100/140/160/180/220 ms
  steps. The other ten are functional or intentional: the four
  `MediaIslandEq` visualiser staggers, `CoverArt` rotation,
  `LoadingIndicator`, `CircularProgress`, the `ClickWheel` platter,
  `SwitcherWindow` (Alt+Tab, deliberately fast) and `TrayMenu`'s `duration: 0`.
- **69 `Easing.*` references in 20 files** (10 distinct easing types). Most are
  inside `AnimatedLogo` and `KbLayout`; the rest are the bespoke interaction
  curves listed under exceptions.
- **~30 primitive usages set `duration` or `easing` explicitly** rather than
  using a `type` preset. Many still use tokens directly (`standardDecel`,
  `emphasizedDecel`, `durations.small`), but roughly a dozen combine a token
  with an ad-hoc factor (`* 0.55`, `* 0.46`, `/ 2`, `* 2`) or a raw `Easing.*`
  — e.g. `EmojiPicker`, `SessionMenuWrapper`, `WallpaperSwitcher*`,
  `SidebarWrapper`, `Clock`, `StateLayer`, `FilledSlider`.
- **53 bare `NumberAnimation` objects** outside the primitives, almost all in
  `AnimatedLogo` and `KbLayout`, plus a few functional loops.
- Spring values live in QML rather than the C++ token system, so they cannot be
  overridden from `shell-tokens.json` yet; changing them means editing
  `SpringAnim.qml`.

## Building a new component

This is the contract for an agent or person asked to add UI: derive the look and
the motion from the rules above, do not invent new values.

### Look

- **Colour:** `Colours.palette.m3*` for foreground roles (`m3onSurface`,
  `m3onSurfaceVariant`, `m3primary`, `m3outline`, …) and `Colours.tPalette.m3*`
  for translucent surfaces. No hardcoded hex values — palettes come from the
  runtime scheme, so a literal would not follow a theme change.
- **Primitives:** build on `StyledRect`, `StyledClippingRect` and `StyledText`
  under `components/`. They already animate colour through `CAnim`.
- **Space, shape, type:** `Tokens.padding.*`, `Tokens.spacing.*`,
  `Tokens.rounding.*` and `Tokens.font.*` (e.g. `font.body.small`, `font.icon`).
  Monitor-stable panel geometry goes through `Tokens.sizes.*`. These share the
  native config with the animation tokens and reload live from
  `shell-tokens.json`.

### Motion

| What changes | Use |
|---|---|
| Opacity or colour | `Anim.FastEffects` / `DefaultEffects` / `SlowEffects`; colour inside a `Behavior on color` uses `CAnim` (and `StyledRect`/`StyledText` already do) |
| Position or size on a predictable timeline | `Anim.Standard*`, `Emphasized*` or `Fast/Default/SlowSpatial` |
| A surface whose target can change mid-flight | `SpringAnim` with an existing role; add a role only if no current feel fits, and say why |
| Anchors that move with layout | `AnchorAnim` (same type list as `Anim`) |
| Loader content swap | `AnimLoader` |

Rules:

1. No raw `duration:` or `easing.type:` for ordinary UI motion — those belong
   only to the [deliberate exceptions](#deliberate-exceptions).
2. Never declare `type: Anim.X` and then override its `duration` or `easing`:
   state the timing explicitly instead of hiding a bespoke curve behind a token.
3. Never set `spring` or `damping` outside `SpringAnim.qml`. For
   direction-specific feel, switch `role` **before** retargeting the value.
4. Keep `epsilon` at the call site: ~0.25–1 for pixel properties, ~0.001–0.005
   for normalized 0..1 properties.
5. Drive related properties from one state value plus derived properties, not
   parallel animations that have to be kept in sync.
6. Do not reimplement the speed setting — `Anim` and `SpringAnim` already honour
   `anim.durations.scale`.
7. If a deviation is unavoidable, add it to
   [Deliberate exceptions](#deliberate-exceptions) with a reason rather than
   leaving an unexplained literal.

### Minimal skeleton

```qml
pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property real reveal: 0

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.medium
    opacity: root.reveal

    Behavior on reveal {
        Anim { type: Anim.DefaultSpatial }
    }

    // colour is already handled by StyledRect's CAnim behaviour

    StyledText {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        text: qsTr("Example")
    }
}
```

### Acceptance checks

```bash
qmllint <new-file>.qml
python3 scripts/check-layout.py
python3 -m unittest discover -s tests
python3 quickshell/caelestia/tests/integration.py   # needs Wayland/native modules
```

Compositor changes also need `hyprctl reload` and an empty `hyprctl configerrors`;
shell changes need a shell reload. If the new motion cannot be expressed with an
existing `Anim` type or `SpringAnim` role, that is a design decision to discuss,
not a reason to scatter literals.

## Where to change things

| Goal | File |
|---|---|
| Change a compositor curve or window/workspace animation | `hypr/modules/animations.lua` |
| Change compositor rounding, blur, gaps, shadows | `hypr/modules/appearance.lua` |
| Change a default shell easing curve | `AnimCurves` in `quickshell/caelestia/plugin/src/Caelestia/Config/tokens.hpp` |
| Change a default shell duration | `AnimDurationTokens` in the same file |
| Override tokens without code changes | `caelestia/shell-tokens.json` (first-install preset) or `~/.config/caelestia/shell-tokens.json` (live) |
| Change timing of a generic QML transition | `components/Anim.qml`, `AnchorAnim.qml`, `CAnim.qml`, `AnimLoader.qml` |
| Change how stiff/bouncy a surface spring is | `components/SpringAnim.qml` (the role table) |
| Change a specific panel's motion | The panel wrapper/content or `Behavior` in `modules/<area>/`, choosing an `Anim` type or a `SpringAnim` role |
| Disable compositor effects for games | `quickshell/caelestia/services/GameMode.qml` (driven by the dashboard Game mode card and `caelestia shell gameMode toggle`) |
| Adjust theme palette that colours animated surfaces | `hypr/scheme/current.lua` plus the runtime Material 3 scheme consumed by `services/Colours.qml` |

Remember the compatibility boundary from `docs/STRUCTURE.md`: native
`Caelestia.*` imports, config/state paths, JSON keys, IPC targets and persistent
identities must stay stable. The QML is interpreted, but the native plugin
(including the curve-building code) must be rebuilt after Qt upgrades.

## Validation

```bash
python3 scripts/check-layout.py
python3 -m unittest discover -s tests -v
python3 quickshell/caelestia/tests/integration.py   # requires Wayland/native modules
```

The Lua animation assertions live in `tests/test_hypr_modules.py` and check the
live `ayu*` curve points and leaf settings directly.

## Verification note

Earlier audit notes (`AUDIT.md`, `REPORT.md`) claim the active config defines
`MacOpen`/`MacClose` curves and that a test expects `ShellPanel` curves. That is
stale: the current `hypr/modules/animations.lua` defines `ayuOpen`,
`ayuClose`, `ayuMove` and `ayuLinear` (last changed in commit `feb59a8`), and
the current `tests/test_hypr_modules.py` asserts those same `ayu*` names and
points. The document above follows the current source.
