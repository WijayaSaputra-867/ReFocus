# Refocus --- Technical Architecture

## 1. Architecture Goal

Refocus should be **local-first, Android-first, privacy-first, and
modular**.

The application should minimize dependencies on external services.

## 2. Technology Stack

### Application

-   Flutter
-   Dart

### Android Integration

-   Kotlin
-   Android Usage Statistics APIs
-   Android Accessibility Service where required
-   Android notification APIs

### Local Storage

A local database such as SQLite through a Flutter persistence layer.

Possible implementation:

-   Drift
-   SQLite directly
-   Another well-maintained local persistence package

The final choice should prioritize reliability and long-term
maintenance.

## 3. High-Level Architecture

``` text
Flutter UI
    |
    +-- Home
    +-- Protected Apps
    +-- Rules
    +-- Statistics
    +-- Focus Mode
    |
    v
Domain Layer
    |
    +-- Distraction Session Manager
    +-- Cooldown Manager
    +-- Daily Quota Manager
    +-- Protection Rules
    |
    v
Platform Layer
    |
    +-- Usage Detection
    +-- Accessibility Integration
    +-- Notifications
    |
    v
Android OS
```

## 4. Core Domain State

``` text
ProtectionState
├── idle
├── distracting
├── cooldown
└── daily_locked
```

### Idle

No protected app is currently active.

### Distracting

A protected app is active and accumulated distraction time is
increasing.

### Cooldown

The trigger has been reached and protected apps are temporarily blocked.

### Daily Locked

The daily session quota has been exhausted.

## 5. Global Timer Logic

The timer belongs to the **distraction session**, not to an individual
application.

Example:

``` text
TikTok       03:00
Instagram    02:00
YouTube      01:00
------------------
Total        06:00
```

If the trigger is 5 minutes, the trigger occurs during this sequence.

## 6. Protected vs Non-Protected Apps

Only protected apps contribute to distraction time.

Example:

``` text
TikTok       03:00  counted
Home         02:00  ignored
Instagram    02:00  counted
```

Total distraction time:

``` text
03:00 + 02:00 = 05:00
```

## 7. Data Model

Suggested entities:

### ProtectedApp

``` text
id
package_name
display_name
enabled
created_at
updated_at
```

### ProtectionSettings

``` text
trigger_seconds
daily_session_limit
cooldown_seconds
reset_hour
enabled
```

### DistractionSession

``` text
id
started_at
ended_at
duration_seconds
triggered
created_at
```

### DailyUsage

``` text
date
session_count
distraction_seconds
```

The exact schema can change during implementation.

## 8. Platform Boundary

Flutter should own:

-   UI.
-   Settings.
-   Local data.
-   Domain rules where practical.
-   Statistics presentation.

Kotlin should own:

-   Android app detection.
-   Accessibility service integration.
-   Android-specific blocking/intervention.
-   System-level lifecycle handling.

Communication can use Flutter platform channels or a suitable plugin
architecture.

## 9. Resilience

The app should handle:

-   Device reboot.
-   App process termination.
-   Accessibility service being disabled.
-   Usage permission being revoked.
-   Battery optimization restrictions.
-   Time/date changes.
-   App updates.

The system should fail safely and clearly explain when protection cannot
operate.

## 10. Privacy

MVP principles:

-   No account.
-   No cloud database.
-   No remote analytics.
-   No unnecessary network access.
-   Store only data required for functionality.
-   Do not store screen content.
-   Do not transmit Accessibility events.

## 11. Future Architecture

If synchronization is eventually added:

``` text
Local App
    |
Encrypted Sync
    |
Optional Backend
```

Cloud functionality should remain optional and must not be required for
the core blocking experience.
