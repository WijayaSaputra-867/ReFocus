# Refocus

> **Take back your attention.**

Refocus is an open-source, privacy-first Android application that helps
users reduce distractions from social media, games, video platforms, and
other selected applications.

## Why Refocus?

Traditional app limits often treat each application separately.

Refocus uses a **global distraction timer**.

For example:

``` text
TikTok       3 minutes
Instagram    2 minutes
----------------------
Total        5 minutes
```

If the configured trigger is 5 minutes, Refocus activates a cooldown
even though the user switched applications.

## Core Features

-   Global distraction timer.
-   Cross-app accumulated distraction time.
-   Configurable trigger duration.
-   Configurable daily session quota.
-   Global cooldown.
-   Daily lock after quota exhaustion.
-   Protected app selection.
-   Local statistics.
-   Local-first architecture.
-   No account required for the MVP.
-   Open source.

## Example

Configuration:

``` text
Trigger:       5 minutes
Daily limit:   5 sessions
Cooldown:      15 minutes
```

Flow:

``` text
Protected app
      ↓
5 minutes accumulated
      ↓
Session 1/5
      ↓
All protected apps enter cooldown
      ↓
15 minutes
      ↓
Protection ends
```

After session 5:

``` text
5/5 sessions
      ↓
All protected apps locked
      ↓
Next daily reset
```

## Technology

-   Flutter
-   Dart
-   Kotlin
-   Android APIs
-   Local database

## Privacy

Refocus is designed to keep the core experience on-device.

The MVP does not require:

-   User accounts.
-   Cloud storage.
-   Advertising.
-   Remote analytics.

Sensitive Android permissions are documented and should be requested
only when required.

## Open Source

Refocus is intended to be developed transparently with community
contributions, security reports, and public issue tracking.

See:

-   `PRD.md`
-   `ARCHITECTURE.md`
-   `SECURITY.md`
-   `ROADMAP.md`

## Project Status

Early-stage concept / MVP planning.

The architecture and requirements may evolve as Android platform
limitations and real-world usability are tested.

## License

Choose and add an appropriate open-source license before the first
public release.
