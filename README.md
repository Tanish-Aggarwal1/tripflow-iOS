# TripFlow

An iOS trip-planning app built with UIKit and Storyboards.

## Team

- Tanish — My Trips (create/view/delete trips), local notifications
- Joann — Trip Detail & Stops
- Pratham — Explore
- Neel — Map & Settings

## Build & Run

1. Open `TripFlow.xcodeproj` in Xcode 16+ (needs the iOS 18 SDK).
2. Select the `TripFlow` scheme and any iOS Simulator destination.
3. Build & run (`Cmd+R`). On first launch, `DatabaseManager` copies the seed
   `tripflow.sqlite` from the app bundle into the Documents directory.

From the command line:

```
xcodebuild -project TripFlow.xcodeproj -scheme TripFlow \
  -destination 'generic/platform=iOS Simulator' build
```

This is the same build CI runs on every push and PR (see
`.github/workflows/ci.yml`) — if it fails locally, it'll fail in CI too.

## Storyboard structure

Each team member owns their own `.storyboard` file instead of everyone
editing `Main.storyboard` directly:

- `Main.storyboard` — app entry point; holds the root Tab Bar Controller
  and a Storyboard Reference for each member's storyboard
- `TanishTrips.storyboard`
- `JoannStops.storyboard`
- `PrathamDetailExplore.storyboard`
- `NeelMapSettings.storyboard`

**Why:** Storyboard XML doesn't merge well — Interface Builder generates
non-deterministic IDs and doesn't preserve a stable element order, so two
people editing the same `.storyboard` in parallel almost always produces a
git conflict that's painful (and risky) to resolve by hand. Splitting one
storyboard per owner means everyone can work in Xcode at the same time
without touching the same file, and `Main.storyboard` stays a thin router
that rarely needs to change. This mirrors how larger production iOS teams
structure Storyboard-based apps for the same reason.
