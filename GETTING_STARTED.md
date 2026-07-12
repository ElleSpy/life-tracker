# Getting started (non-technical guide)

This walks you through **seeing the app on your screen** and **using GitHub** —
no coding knowledge needed. Read top to bottom.

---

## Part 1 — What you need

To *run* an iPhone app you need a **Mac** with **Xcode** (Apple's free app for
building iPhone apps). There's no way around this — iPhone apps can only be built
on a Mac. If you don't have a Mac, you can still browse the code and progress on
GitHub, but you won't be able to press "play" and see it running.

- **Xcode** is free. Open the **App Store** on your Mac, search **Xcode**,
  install it. It's a big download (several GB), so start this first.
- You need **Xcode 16 or newer** (the current version is fine).

---

## Part 2 — Get the app onto your Mac

The easiest way, no Git knowledge required:

1. Go to the project page: **https://github.com/ElleSpy/life-tracker**
2. Click the green **`< > Code`** button (near the top right of the file list).
3. Click **Download ZIP**.
4. Find the downloaded file (usually in **Downloads**), double-click to unzip it.
   You'll get a folder called `life-tracker` (or `life-tracker-main`).

> Tip: whenever I push new work, just download the ZIP again to get the latest.

---

## Part 3 — Open it in Xcode and press play

1. Open the unzipped folder.
2. Double-click **`LifeTracker.xcodeproj`** (icon looks like a blueprint). Xcode
   opens.
3. Along the top, near the ▶ (play) button, there's a device dropdown. Click it
   and choose an iPhone simulator, e.g. **iPhone 16**.
4. Press the **▶ Run** button (top-left) or hit **⌘R**.
5. The first build takes a minute or two. A simulated iPhone will appear on your
   screen and the app will launch.
6. On the sign-in screen, tap **Continue with Apple** (or Google) — in this
   version that signs you in instantly with a demo account, so you can look
   around all four tabs with sample data already filled in.

### If Xcode shows a red "Signing" error
Running in the **simulator** usually doesn't need this, but if it complains:

1. In the left sidebar, click the blue **LifeTracker** project at the very top.
2. Select the **LifeTracker** target → **Signing & Capabilities** tab.
3. Tick **Automatically manage signing** and pick your name under **Team**
   (sign in with your normal Apple ID if asked — a free account is fine for the
   simulator).

That's it — you should see the app running. 🎉

---

## Part 4 — Understanding GitHub (the essentials)

GitHub is where the code lives online, like a Google Drive for code with a full
history of every change.

- **The repository ("repo")** — the project itself:
  https://github.com/ElleSpy/life-tracker
- **A pull request ("PR")** — a review page showing a batch of proposed changes.
  Ours is **PR #1**: https://github.com/ElleSpy/life-tracker/pull/1
  - Click the **Files changed** tab to see everything that was added.
  - I keep pushing new work to this same PR, so it grows as I build. **Please
    don't merge it yet** — wait until I tell you it's ready, otherwise you'd
    "finalise" a half-finished batch.
  - When I say it's ready: click **Ready for review**, then the green
    **Merge pull request** button, then **Confirm merge**. That makes the work
    the official version on the `main` branch.

- **Optional tidy-up (one click):** because the project started empty, GitHub
  temporarily set the working branch as the "default." To point it at the clean
  `main` branch instead: repo → **Settings** → **General** →
  **Default branch** → switch to **main**. This is cosmetic; nothing breaks
  either way. (I couldn't do it automatically — this environment blocks changing
  repo settings for security.)

---

## Quick reference

| I want to… | Do this |
| --- | --- |
| See the app running | Download ZIP → open `LifeTracker.xcodeproj` in Xcode → ▶ Run |
| See what changed | Open PR #1 → **Files changed** tab |
| Get the newest version | Download the ZIP again |
| Make it official | (When I say it's ready) merge PR #1 |

Any of this confusing? Just tell me which step and I'll explain it differently.
