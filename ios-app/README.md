# Roam Wild — iOS (V1 POC)

> Native SwiftUI port of the Roam Wild web POC. Built to feel like a shipped product while the backend (Supabase) is shared with the existing web app.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-black) ![Language](https://img.shields.io/badge/Swift-5.9-orange) ![UI](https://img.shields.io/badge/UI-SwiftUI-blue) ![Status](https://img.shields.io/badge/status-V1%20POC-E8531A)

---

## What's in this build

| Web POC screen | iOS equivalent | Notes |
| --- | --- | --- |
| `home.html` onboarding | `OnboardingView.swift` | 3-slide paged intro, same copy + emojis |
| `home.html` home | `HomeView.swift` | Stats, featured spots, 4-col category grid |
| `index.html` map | `MapScreenView.swift` | Native **MapKit** (replaces Leaflet) |
| Spot detail popover | `SpotDetailView.swift` | Bottom sheet, directions via Apple Maps |
| `+ Add spot` | `AddSpotView.swift` | Placeholder form — writes land in V2 |
| `auth.html` (sign in / sign up) | `AuthView.swift` | Email + password against Supabase Auth |
| `auth.html` (user panel) | `AccountView.swift` | Avatar, stats, sign-out |

The app hits the **same Supabase project** as the web POC (`zqkujliskbvexoxtnjxv.supabase.co`), so every spot you see on the web will appear in the app.

---

## Quick start

### 1. Open the project
```bash
open ios-app/RoamWild.xcodeproj
```
Xcode 15 or later required (project targets iOS 17+ for the new `Map` API).

### 2. Pick a destination
In the run-destination dropdown at the top of Xcode, pick any iPhone simulator (e.g. **iPhone 15 Pro**).

### 3. Run
Press **⌘R** (or click the ▶️ button). First build takes ~30s.

That's it — the app launches straight to onboarding, then loads live spots from Supabase.

---

## If the project won't open (fallback plan)

The `.xcodeproj` file is hand-crafted. If Xcode rejects it for any reason, this 2-minute fallback always works:

1. In Xcode: **File → New → Project → iOS → App**
   - Product name: `RoamWild`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
2. Delete the auto-generated `ContentView.swift` and `RoamWildApp.swift`.
3. Drag the folders `RoamWild/Models`, `RoamWild/Services`, `RoamWild/Views`, plus `RoamWild/RoamWildApp.swift` and `RoamWild/AppState.swift` into the Xcode project navigator. Tick **"Copy items if needed"** and **"Create groups"**.
4. In the target's **Info** tab, add a row:
   `Privacy - Location When In Use Usage Description` = *"Roam Wild uses your location to show nearby adventure spots on the map."*
5. Run with **⌘R**.

---

## Project structure

```
ios-app/
├── RoamWild.xcodeproj/              ← Open this in Xcode
└── RoamWild/
    ├── RoamWildApp.swift            ← @main entry + brand tokens
    ├── AppState.swift               ← ObservableObject (spots, filters, saved)
    ├── Models/
    │   └── Spot.swift               ← Spot + SpotCategory + SpotType
    ├── Services/
    │   └── SupabaseService.swift    ← REST fetch (no SDK needed)
    ├── Views/
    │   ├── RootView.swift           ← Onboarded? → TabView
    │   ├── OnboardingView.swift     ← 3-slide intro
    │   ├── HomeView.swift           ← Stats + featured + categories
    │   ├── MapScreenView.swift      ← MapKit + filter chips
    │   ├── SpotDetailView.swift     ← Bottom sheet
    │   ├── AddSpotView.swift        ← Form (V1 local-only)
    │   ├── AuthView.swift           ← Sign in / Sign up (Supabase Auth)
    │   └── AccountView.swift        ← Signed-in user panel
    ├── Assets.xcassets/             ← App icon + accent color
    └── Preview Content/
```

---

## Architecture notes

- **State:** a single `@MainActor ObservableObject` (`AppState`) injected via `@EnvironmentObject`. Plenty for V1; swap to `@Observable` / feature-scoped stores in V2.
- **Networking:** hand-rolled `URLSession` call against Supabase REST — zero third-party dependencies, nothing to `pod install` or SwiftPM-resolve.
- **Map:** MapKit (`Map(position:selection:)` from iOS 17). Ships with Apple Maps → "Get directions" hands off via `MKMapItem.openInMaps`.
- **Design tokens:** the exact hex values from `:root {}` in the web POC, defined once in `RoamWildApp.swift → enum Brand`.
- **Persistence:** `UserDefaults` for onboarding flag, saved-spot IDs, and username. Good enough for V1 POC.

---

## Auth wiring (what's live now)

Tap the circular profile avatar on Home, or the **Sign In** pill on the Map top bar:

- **Not signed in** → `AuthView` opens as a sheet with Sign In / Sign Up tabs.
- **Signed in** → `AccountView` opens with avatar, Saved/Added/Reviews stats, and Sign Out.

Under the hood:
- **Sign In** → `POST /auth/v1/token?grant_type=password` → persists `access_token`, `refresh_token`, `user_id`, `email`, `username` in `UserDefaults`.
- **Sign Up** → `POST /auth/v1/signup` (with `username` + `favourite_activity` metadata) → if Supabase auto-confirms, immediately creates a `profiles` row and signs the user in; otherwise prompts them to confirm their email.
- **Sign Out** → `POST /auth/v1/logout` + local token wipe.
- **Profile fetch** on account screen open → `GET /rest/v1/profiles?id=eq.<uid>`.

Google / Apple sign-in buttons are stubbed with a "coming soon" toast — same UX as the web POC today.

---

## Roadmap to V2

1. **OAuth** — finish Google + Apple using `ASWebAuthenticationSession`.
2. **Token refresh** — auto-refresh `access_token` via `/auth/v1/token?grant_type=refresh_token` before expiry.
3. **Keychain storage** — move tokens out of `UserDefaults` into the Keychain.
4. **Add Spot submission** — POST to `/rest/v1/spots` with RLS. Photo upload to Supabase Storage.
5. **User location pin** — `CLLocationManager` "Near me" button matching the web `findMe()`.
6. **Offline cache** — persist fetched spots in SwiftData for offline map browsing.
7. **Widgets & Live Activities** — "Nearest spot" home screen widget.
8. **Android parity** — Kotlin/Compose build (separate project) sharing the same Supabase schema.

---

## Credits

POC designs & copy by the Roam Wild team. iOS shell wired by the platform team. Supabase schema is shared between web and mobile so any spot added on one surface appears on all.
