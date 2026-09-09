# Refocus --- Development Roadmap

## Phase 0 --- Project Foundation

-   [x] Create GitHub repository.
-   [x] Choose open-source license.
-   [x] Initialize Flutter project.
-   [x] Configure Android build.
-   [x] Define package/application ID.
-   [x] Create project documentation.
-   [x] Set up formatting and linting.
-   [x] Set up CI.

## Phase 1 --- MVP

### Onboarding

-   [x] Product introduction.
-   [x] Privacy explanation.
-   [x] Permission setup flow.

### Protected Apps

-   [x] List installed applications.
-   [x] Select protected applications.
-   [x] Enable/disable individual apps.

### Rules

-   [x] Trigger duration.
-   [x] Daily session limit.
-   [x] Cooldown duration.

### Distraction Engine

-   [x] Detect foreground protected app.
-   [x] Start global timer.
-   [x] Continue timer across protected-app switches.
-   [x] Pause when outside protected apps.
-   [x] Trigger cooldown.
-   [x] Increment daily session counter.
-   [x] Enforce daily lock.

### Storage

-   [x] Local database.
-   [x] Persist settings.
-   [x] Persist daily usage.
-   [x] Recover state after process restart.

## Phase 2 --- Polish

-   [x] Better onboarding.
-   [x] Empty states.
-   [x] Error handling.
-   [x] Battery optimization guidance.
-   [x] Accessibility-service status indicator.
-   [x] Permission status screen.
-   [x] Better cooldown experience.

## Phase 3 --- Statistics

-   [x] Daily distraction time.
-   [x] Sessions per day.
-   [x] Weekly trends.
-   [x] Protected app breakdown.
-   [x] Resisted sessions.

## Phase 4 --- Focus Mode

-   [x] Start focus session.
-   [x] Temporary protected-app policy.
-   [x] Focus timer.
-   [x] Scheduled focus sessions.
-   [x] Focus completion statistics.

## Phase 5 --- Community

-   [x] Public issue tracker.
-   [x] Contribution guide.
-   [x] Security policy.
-   [x] Translation system.
-   [x] Community feature requests.

## Phase 6 --- Optional Advanced Features

These should not compromise the local-first philosophy.

-   [x] Encrypted backup.
-   [x] Optional synchronization.
-   [x] Widgets.
-   [x] Per-category rules.
-   [x] Website blocking.
-   [x] Cross-device focus mode.

## Release Strategy

### v0.1

Functional prototype.

### v0.2

Stable MVP with reliable protection and local storage.

### v0.5

Statistics and Focus Mode.

### v1.0

Stable public open-source release.
