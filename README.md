# LifeTracker

A life-planning app for iOS — your **plans, food and routines** in one place.

This repository contains the first working skeleton: a native SwiftUI app with
the four-tab structure from the product brief, local persistence via SwiftData,
a real calendar integration (EventKit), and clean, stubbed interfaces for the
integrations that need external accounts/keys.

> Status: **v0.1 skeleton.** Everything runs locally today. Integrations that
> need a backend or provider credentials are wired behind protocols with mock
> implementations, so the whole app is clickable end-to-end.

## Requirements

- **Xcode 16 or newer** (the project uses filesystem-synchronised groups)
- iOS 17+ (SwiftData / EventKit full-access APIs)

## Getting started

```sh
open LifeTracker.xcodeproj
```

Select the **LifeTracker** scheme and an iOS 17+ simulator, then Run. On first
launch you'll see the SSO screen — in this build "Continue with Apple/Google"
signs you in instantly with a demo account (see [Authentication](#authentication)).
Sample data (to-dos, pantry items, recipes, routines) is seeded on first run.

## The four tabs

| Tab | What it does | Backing models |
| --- | --- | --- |
| **Plan** | To-do list + the day's calendar events, a 7-day strip, manual add, and sync from a to-do app | `TodoItem`, calendar (EventKit) |
| **Food** | Segmented into **Have** (pantry), **Making** (weekly meal plan) and **Recipes** | `PantryItem`, `MealPlanEntry`, `Recipe` |
| **Routine** | Your own routines (create / edit / duplicate / delete) plus suggested templates | `Routine`, `RoutineStep` |
| **Profile** | Account, integration connections, sign out | `Session` |

Highlights matching the brief:

- **Routines** can be built from scratch, duplicated, and there are built-in
  **suggested** routines (WFH / office / weekend) you copy into your own list.
- **Food** is split exactly as described: what you *have*, what you're *making*,
  and recipes you *want to make* (a want-to-make shortlist).
- **Pantry import** from email/photo is present as a review-and-confirm flow.
- **SSO only** (Apple + Google), no passwords.

## Architecture

```
LifeTracker/
├── App/            App entry, root/auth gating, tab bar
├── Models/         SwiftData @Model types + sample data + shared enums
├── Services/       Integration interfaces (protocols) + real/mock impls
├── DesignSystem/   Theme tokens + reusable views (Card, Pill, EmptyState…)
└── Features/
    ├── Auth/       Login (SSO)
    ├── Plan/       To-do + calendar
    ├── Food/       Pantry, meal plan, recipes
    ├── Routine/    Routines + suggestions
    └── Profile/    Account + connections
```

Every integration sits behind a protocol in `Services/`, injected through the
SwiftUI environment via the `Services` container. This keeps views testable and
lets us swap a mock for a real client without touching UI code.

## What's real vs stubbed

| Integration | Status | Notes |
| --- | --- | --- |
| **Apple Calendar** | ✅ Real | `EventKitCalendarService` reads events via EventKit. |
| **To-do app sync** | 🔸 Stubbed | `MockTodoSyncService` returns sample tasks. Real Todoist/TickTick/Things/Reminders clients slot in behind `TodoSyncService`. |
| **Pantry import (email/photo)** | 🔸 Stubbed | `MockPantryImportService` returns a sample receipt. Real impl = Gmail API / Vision OCR + a parser. |
| **Apple / Google SSO** | 🔸 Demo auth | `MockAuthService` signs in instantly. Real `Sign in with Apple` is implemented in `AppleAuthService` (needs the capability enabled). |

### Enabling real Apple Sign in with Apple

1. In Xcode, select the target → **Signing & Capabilities** → **+ Capability** →
   **Sign in with Apple** (requires a development team; Xcode creates the
   entitlements file for you).
2. In `Services/AppEnvironment.swift`, change the `Services` initialiser default
   from `MockAuthService()` to `AppleAuthService()`.

### Wiring a real to-do or import provider

Implement the relevant protocol (`TodoSyncService` / `PantryImportService`) with
a real API client and swap the default in `Services/AppEnvironment.swift`. The
Plan/Food UIs need no changes.

## Built in v0.1

Beyond the four-tab skeleton:

- **Shopping list** (Food › Shop): auto-fill from the week's meal plan, tick off,
  and move bought items into the pantry.
- **Cook this**: a recipe's "I cooked this" deducts ingredients from the pantry;
  "add missing to shopping list" tops up what you're short of.
- **Routine run mode**: step through a routine with checkable progress.
- **Today at a glance** on the Plan tab: tasks due, next event, tonight's dinner.
- **Local reminders** for to-dos with a due date/time (opt-in).
- **Recipe editing** (not just adding).
- **CI**: every push builds the app on a macOS runner (see `.github/workflows`).

## Roadmap (next up)

- Real to-do provider (OAuth + one provider API end-to-end)
- Real email/photo pantry parsing (Vision OCR + Gmail)
- Per-day routine scheduling & routine step reminders
- Google SSO (GoogleSignIn SDK + client ID)
- Recipe photos and richer nutrition/tags
- Unit conversions when matching pantry ↔ recipe quantities

## Notes

- Bundle id: `com.ellespy.lifetracker` — change under target build settings.
- No secrets are committed; `Secrets.plist` / `GoogleService-Info.plist` are
  git-ignored for when real credentials are added.
