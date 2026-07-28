# TripFlow

An iOS trip-planning app built with UIKit and Storyboards.

## Team

- Tanish — My Trips (create/view/delete trips), local notifications
- Joann — Trip Detail & Stops
- Pratham — Explore
- Neel — Map & Settings

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
