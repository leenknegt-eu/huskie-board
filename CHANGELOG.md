# Changelog

All notable changes to **Plasma Keyboard** will be documented in this file.

## [Unreleased] (fork)

- Renamed binary/desktop entry to `tastiera` to avoid clashing with KDE's `plasma-keyboard` (Plasma 6.8+).
- `make install` now installs the binary and `tastiera.desktop`.
- Added Arch Linux PKGBUILD in `packaging/arch/`.
- Settings menu (⚙ in the top bar) replaces the always-visible theme strip; choices persist in `~/.config/KDE/tastiera.conf`.
- New default theme "Auto (KDE)" follows the active KDE color scheme; added Breeze Light.
- Removed redundant `?123` pill from the top bar (the key in the bottom row remains).
- Keyboard and minimized bubble can no longer be dragged off-screen; positions are re-clamped on rotation.
- New "Docked" position: pinned to the bottom centre at its current width, not draggable.
- Fixed unreadable special-key and accent-popup labels on light themes.
- **Typing now works on KWin**: text is committed through `zwp_input_method_v1` (the protocol KWin gives
  its virtual keyboard). KWin 6.8 does not offer `zwp_virtual_keyboard_v1`, so previously everything fell
  back to `/dev/uinput`. Unicode/emoji are committed directly instead of via a clipboard paste.
- `/dev/uinput` is now only opened on demand (no text field active), so a fake hardware keyboard is no
  longer registered at startup.
- New default "Show keyboard: Automatically": appears when a text field is focused, hides when it loses
  focus; ✖ hides it until the next text field. The old ✖ + floating bubble behaviour is kept as "Manually".
- Password/sensitive fields are detected from the input-method content type (disables suggestions).
- Removed the "KDE Touch Key" title; a small grip remains as drag handle in floating mode.
- **Lock screen support**: the keyboard now uses KWin's input-panel surface (`zwp_input_panel_surface_v1`,
  like KDE's own keyboard) when docked in automatic mode and always while the screen is locked, so it
  appears over the lock screen. Floating/manual use keeps the layer-shell overlay.
- **Login screen**: installs a systemd drop-in so Plasma Login Manager's greeter starts Tastiera instead of
  the hard-coded `plasma-keyboard` (CMake option `TASTIERA_LOGIN_SCREEN`, default ON).
- Gboard-style feel (all optional under Settings → Typing): key popout above the pressed key, flat keys
  with colour press feedback, slide-in/out and popup animations. "Classic" keys keep the old outlined look.
- Docked is now the default position for new installs.
- Fixed auto show/hide occasionally reading stale state (keyboard staying hidden after activation).
- The input panel is now only used while the screen is locked: KWin shrinks the focused app window around a
  docked input panel, so outside the lock screen the keyboard is an overlay again (apps keep their size).
- Extended size is now a full PC layout: Esc/F1–F12/Home/End, number row, punctuation, Tab/Caps/Enter,
  both Shifts, Ctrl/Super/Alt and an inverted-T arrow cluster with Del. Modifiers latch for the next key.
- Dock/float toggle and a hide button in the top bar (position removed from Settings); gear icon is now
  drawn so it is exactly centred.
- Removed the word-suggestion row and the Split pill; the terminal / Ctrl-Alt strip only appears when used
  (terminal pills now off by default).
- Mobile-style long-press alternatives: hold a letter for accents (à á â ä æ ã å ā, è é ê ë ē ė ę €, ç ñ ß ø …),
  the top row offers its number first (q=1 … p=0), "." and "," offer punctuation. Slide to pick, release to
  type; the popup stays inside the keyboard and wraps into balanced rows. Works in Extended too.
- Keyboard height setting (70–150 %, Settings → Keyboard height).
- Gboard look: rebuilt phone layout on a 10-unit grid (offset middle row, wide Shift/Backspace, ?123 · ☺ · ,
  · space · . · round Enter), vector Shift/Caps/Backspace/Enter/emoji icons, flat icon toolbar (clipboard,
  terminal, size, dock, settings, hide), digit hints on the top row, flush docked edge.
- Emoji view: emoji were typed twice; added ABC / space / backspace row (the old ABC pill is gone).

## [v0.91] - 2026-08-07

### 🛡️ Security & Process Protection
- **Process Memory Dump Protection**: Added `prctl(PR_SET_DUMPABLE, 0)` and `RLIMIT_CORE = 0` to prevent Linux kernel core dumps from writing process memory to disk on crashes.
- **RAM Key Lock Buffer (`SecureKeyBuffer`)**: Implemented `SecureKeyBuffer` utilizing `mlock()` to pin sensitive key buffers in physical RAM (preventing swap file exposure) and zeroing memory immediately after send via `explicit_bzero()`.
- **Sensitive Data & Password Mode Protection**: Automatically disables Italian word dictionary suggestions, swipe gesture tracking, and clipboard history logging during active password entries (`PASSWORD` or `SENSITIVE_DATA` input flags).

### 🪟 Window Manager & Tiling Integration (Krohnkite)
- **Tiling Window Manager Bypass**: Configured `Qt::BypassWindowManagerHint` in Qt C++ and QML alongside `Qt::FramelessWindowHint`, `Qt::WindowStaysOnTopHint`, and `Qt::WindowDoesNotAcceptFocus` to prevent Krohnkite and tiling WMs from capturing or resizing the floating keyboard.
- **LayerShell Overlay Enforcement**: Set LayerShell scope explicitly to `virtual-keyboard` and layer to `LayerOverlay` with `KeyboardInteractivityNone` and `AnchorBottom`.
- **Wayland App_ID Specification**: Configured desktop entry application ID to `org.kde.plasma-keyboard`.

### 📐 Layout, Sizing & Ergonomics
- **Giant Spacebar Restoration**: Removed global `Layout.fillWidth: true` from `KeyButton.qml` to allow the spacebar (`space`) to expand across ~500px under `z x c v b n m` matching the original layout design.
- **Extended Mode 100% Display Width**: Configured Extended mode (`full`) to take 100% of the display width (`parent.width`) with 17px side padding for comfortable thumb typing at screen edges.
- **One-Handed Mode Ergonomics**: Automatically hides the `▯▯ Split` pill in `1-Handed` size mode and auto-disables split mode.

### ⌨️ Input Engine, Gboard Shift & Accents
- **Gboard Style Shift & Caps Lock**: Single tap toggles temporary Shift (1 uppercase letter, auto-reverts), double tap (within 300ms) locks Caps Lock (`⇪`), tap while active turns OFF.
- **Instant Accented Characters**: Resolved asynchronous clipboard race conditions in `WaylandVirtualKeyboard::sendEmoji` via `QGuiApplication::processEvents()` and thread synchronization, inserting accented letters (`ì`, `é`, `è`, `à`, `ù`, `ò`) instantly.

### 🎯 Directional Controls & Navigation
- **Kernel Evdev / Uinput Input Dispatching**: Directional keys (▲, ▼, ◄, ►, Home, End, Del) use direct `/dev/uinput` kernel injection, guaranteeing 100% compatibility across GTK, Qt, Firefox, Chrome, and terminals.
- **Accelerating Hold Repeat**: Holding down any directional key performs 1 initial step, then continuously accelerates repeat intervals from 80ms down to 12ms for smooth cursor gliding across long documents.
- **Shift + Tab Backward Navigation**: Tapping `Tab` while Shift is active dynamically converts to `Shift+Tab`, enabling backward focus navigation in forms and code editors.

### 🎨 UI & Localizing
- **English UI Labels**: Unified labels across all buttons to clean English (`Normal`, `Extended`, `1-Handed`, `space`, `Del`, `Sel All`).
- **Clean Header TouchBar**: Removed redundant `IT` and `Emoji` pills from top TouchBar.
- **Default Theme**: Initialized default theme to `BreezeDark`.
- **Dynamic Font Scaling**: Added automatic `font.pixelSize` scaling in `KeyButton.qml` based on label length to prevent text overflow.
