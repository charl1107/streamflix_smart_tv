# Implementation Plan v2 — Vidnest JS-Dialog Gate

**Repository:** `github.com/charl1107/streamflix_smart_tv`
**Target:** `streamflix_tv_app` (Flutter, Android TV)
**Status:** Plan only — nothing implemented
**Supersedes:** Plan v1

---

## Problem

Playing a title through the Vidnest embed raises a blocking native dialog:

```
vidnest.fun
TO ACCESS THE CONTENT, CONFIRM YOU ARE NOT A ROBOT!
                              CANCEL        OK
```

This is **not** an HTML ad overlay. It is a native Android WebView JavaScript
dialog (`window.confirm`) raised by the provider as a monetization gate. On a TV
remote it is awkward to dismiss and it blocks playback.

---

## Findings

Every claim below was verified against a fresh clone of the repository.

### Finding 0 — `player_webview_screen.dart` is dead code

Both platform routers converge on the same route:

| Source | Line | Navigates to |
| --- | --- | --- |
| `lib/platform/player_router_native.dart` | 26 | `/player` |
| `lib/platform/player_router_web.dart` | 23 | `/player` |

Route table in `lib/app.dart`:

| Line | Route | Screen | Size | State |
| --- | --- | --- | --- | --- |
| 23 | `/player` | `PlayerScreen` | 1038 lines | **LIVE** |
| 24 | `/player_webview` | `PlayerWebViewScreen` | 543 lines | **ORPHANED** |

Nothing in the codebase navigates to `/player_webview` — a grep returns only the
route registration and its import.

**Consequence:** `lib/screens/player_screen.dart` is the only file that needs the
fix. Plan v1's "shared hardening service across two screens" was over-engineering.
More importantly, a fix applied only to `player_webview_screen.dart` would have
compiled cleanly and changed nothing at runtime.

### Finding 1 — Root cause is confirmed, not theorised

`lib/services/ad_blocker.dart` line 343 already contains:

```dart
window.confirm = function() { return true; };
```

That override is already shipping, and the dialog still appears. This is direct
evidence rather than inference:

- `runJavaScript` executes in the **main frame only**.
- Vidnest loads the actual player (Lamda, PrimeSrc, and the other servers) inside
  a **cross-origin subframe**.
- The subframe gets a pristine `window.confirm`, so the gate fires untouched.
- The resulting dialog is a **native Android view**, so no amount of DOM or CSS
  blocking can reach it.

`shouldInterceptRequest` in `MainActivity.kt` does see subframes, but it filters
by hostname, and the gate is served from the already-allowlisted `vidnest.fun`
origin — so it passes.

### Finding 2 — The fix is available in the pinned dependency

`AndroidWebViewController.setOnJavaScriptConfirmDialog` is **public API** in the
pinned `webview_flutter_android: ^4.3.0`. Registering a handler makes the plugin
call `setSynchronousReturnValueForOnJsConfirm(true)` internally, which suppresses
the native dialog **for all frames, subframes included**. That is exactly the gap
identified in Finding 1.

### Finding 3 — A private-package import is a latent build hazard

Both player screens contain:

```dart
import 'package:webview_flutter_android/src/android_webkit.g.dart' as android_webview;
```

This reaches into a package's private `src/` directory for generated Pigeon code
that carries no API stability guarantee. A patch bump of `webview_flutter_android`
can rename or remove it and break the build outright. `flutter_lints: ^6.0.0`
also flags this as `implementation_imports`.

### Finding 4 — This is a three-target build

`pubspec.yaml` includes `webview_flutter_tizen` and `path_provider_tizen`, and
there are 15 `kIsWeb` call sites plus `web_iframe_stub.dart` / `web_iframe_web.dart`.
Any change must stay behind `kIsWeb` and `is AndroidWebViewController` guards or
the Tizen and web builds break.

---

## Phased plan

### Phase 0 — Baseline (no code changes)

Capture a known-good state before editing, so any later breakage is unambiguously
attributable:

```bash
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

`test/widgets/` is empty and there is no CI, so this is the only available
regression baseline.

**Blocker:** `android/settings.gradle.kts` pins AGP `9.3.2` and Kotlin `2.3.20`.
These are ahead of what can be confirmed from memory, so `flutter doctor -v`
output is required before any Gradle or Kotlin file is touched.

### Phase 1 — Suppress the dialog (the actual fix)

Single file: `lib/screens/player_screen.dart`, inside the existing
`_disableAndroidPopups` method at line 50. It is already correctly guarded and
already called at line 212, so this is a purely additive change.

- `setOnJavaScriptConfirmDialog` — return `true` when `AdBlocker.isGateMessage(msg)`
  matches, otherwise `false`. Never render UI.
- `setOnJavaScriptAlertDialog` — swallow and return immediately.
- `setOnJavaScriptTextInputDialog` — return `''`.
- Add `AdBlocker.gatePhrases` and `AdBlocker.isGateMessage()` alongside the
  existing `isAdUrl` / `isTrackerUrl` statics at lines 261 and 272, matching the
  established pattern.
- Log every swallowed message behind a debug flag so the phrase list can be grown
  from real `adb logcat` output.

Candidate seed phrases: `not a robot`, `confirm you are`, `access the content`,
`verify`, `continue to`.

### Phase 2 — Remove the private-package import

Addresses Finding 3. Phase 1 makes this possible, because the public dialog API
replaces what `PigeonInstanceManager` was being used for.

- Delete the `src/android_webkit.g.dart` import from `player_screen.dart`.
- Reach multi-window and `setJavaScriptCanOpenWindowsAutomatically` behaviour
  through public API instead.

This leaves the build strictly more stable than it is today.

### Phase 3 — Sandboxed iframe shell (only if Phase 1 proves insufficient)

Replace `loadRequest(embedUrl)` with a `loadHtmlString` shell that frames the
embed:

```html
<iframe src="EMBED_URL"
        sandbox="allow-scripts allow-same-origin allow-forms allow-presentation"
        allow="autoplay; fullscreen; encrypted-media"></iframe>
```

Omitting `allow-modals` makes the browser engine itself drop `alert`, `confirm`,
and `prompt` in that frame **and all its descendants**. Omitting `allow-popups`
kills `window.open`; omitting `allow-top-navigation` kills redirect hijacking.
This is engine-level enforcement that the page cannot monkey-patch away, and
being pure HTML it also works on Tizen.

**Gate this behind a feature flag.** Two real risks:

1. Vidnest may frame-bust or refuse to render when sandboxed.
2. D-pad injection (`_injectDpadNavigation`, `_tvSpatialNav`, `_tvActivate`)
   targets the top document. `postMessage` will not cross into a cross-origin
   frame, so D-pad degrades to raw key dispatch.

Do not ship this without on-device A/B against Phase 1 alone.

### Phase 4 — Backend sanitizing proxy (last resort)

New `backend/src/routes/embed_proxy.js` mounted at `/api/embed/proxy?src=`,
reusing the existing `/api/m3u8` rewriter pattern:

- Fetch the player HTML server-side with a spoofed `Referer` and User-Agent.
- Strip known gate and ad `<script>` tags.
- Inject a hardened bootstrap as the **first element in `<head>`** so it wins the
  race against provider scripts.
- Recursively rewrite nested `<iframe src>` back through the proxy — this is the
  only layer that genuinely reaches the inner player frame.
- Set a response CSP allowlisting only the hosts already in `allowedDomainKeywords`.

**Cost:** Worker CPU per request, and it breaks whenever Vidnest changes markup.
Not recommended unless Phases 1 through 3 all fail.

### Phase 5 — Cleanup and hardening

- Delete `player_webview_screen.dart`, its route in `app.dart`, and its import
  (Finding 0). Removes 543 lines of drifting duplicate logic and a second copy of
  the private import.
- Dedupe `blockedHosts` in `MainActivity.kt` against `AdBlocker.blockedDomains`;
  the two lists have diverged.
- Add a playback watchdog: if no `<video>` element is playing after roughly 12
  seconds, auto-advance to the next server via the existing `embed_service`
  failover rather than stranding the user on a gate.
- Extend `test/services/ad_blocker_test.dart` to cover `isGateMessage`.

---

## Files touched

| File | Phases | Change |
| --- | --- | --- |
| `lib/screens/player_screen.dart` | 1, 2 | Dialog handlers; drop private import |
| `lib/services/ad_blocker.dart` | 1, 5 | `gatePhrases`, `isGateMessage` |
| `lib/screens/player_webview_screen.dart` | 5 | Delete (dead code) |
| `lib/app.dart` | 5 | Remove orphaned route |
| `android/.../MainActivity.kt` | 5 | Dedupe blocklist |
| `backend/src/routes/embed_proxy.js` | 4 | New (last resort) |
| `test/services/ad_blocker_test.dart` | 5 | Coverage |

---

## Risk summary

| Phase | Build risk | Runtime risk |
| --- | --- | --- |
| 0 | None | None |
| 1 | None — additive, already guarded | Over-broad phrase match could auto-confirm a legitimate dialog |
| 2 | **Reduces** existing risk | None |
| 3 | Low | Frame-bust; D-pad regression |
| 4 | None (backend only) | Ongoing maintenance burden |
| 5 | Low | Watchdog false-positive on slow connections |

---

## Recommendation

**Ship Phase 0, 1, and 2 only.**

That is roughly 60 lines in a single Dart file plus a small `AdBlocker` addition.
It directly removes the dialog in the screenshot, it is fully guarded so Tizen and
web are untouched, and it leaves the build more stable than it is today. Verify on
a real Android TV device before considering Phase 3.

### Open questions before implementation

1. `flutter doctor -v` output — required because of the AGP 9.3.2 / Kotlin 2.3.20 pins.
2. Is the **Tizen** target actively shipped, or vestigial? This determines how much
   guarding Phase 3 needs.

### Verification

Manual matrix on a real Android TV box, with `adb logcat -s chromium:* flutter:*`
attached: each of the 9 Vidnest servers, across movie, TV, and anime content.