# Refocus --- Product Requirements Document

## 1. Overview

**Refocus** is an open-source, privacy-first Android productivity
application designed to help users reduce distractions from social
media, games, video platforms, and other selected apps.

The core idea is not to completely prohibit technology usage. Refocus
introduces controlled friction by measuring **accumulated distraction
time across all protected apps**, triggering a cooldown when the
configured threshold is reached, and enforcing a daily session quota.

### Product statement

> **Refocus --- Take back your attention.**

## 2. Problem

Users can lose significant amounts of time by switching between
distracting applications. A per-app timer can be bypassed simply by
moving from one distracting app to another.

Example:

-   TikTok: 3 minutes
-   Instagram: 2 minutes
-   Total distraction: 5 minutes

Refocus should recognize this as one continuous distraction session.

## 3. Goals

-   Reduce uncontrolled social media and gaming sessions.
-   Measure distraction time globally across selected apps.
-   Prevent users from bypassing limits by switching apps.
-   Give users configurable cooldown periods.
-   Enforce a configurable daily distraction-session quota.
-   Keep user data local by default.
-   Require no account for the MVP.
-   Be open source and auditable.

## 4. Non-goals for MVP

-   Cloud synchronization.
-   Social features.
-   Advertising.
-   AI coaching.
-   Cross-platform iOS support.
-   Remote administration.
-   Collection of detailed user activity in a cloud service.

## 5. Target Platform

### MVP

-   Android
-   Flutter for application UI and product logic.
-   Kotlin for Android-specific integration.

iOS may be evaluated after the Android product proves its value.

## 6. Core Concepts

### Protected App

An installed application selected by the user as a distraction source.

Examples:

-   TikTok
-   Instagram
-   YouTube
-   Mobile games
-   Streaming applications

### Distraction Time

The amount of time the user spends inside protected applications during
the current distraction session.

### Distraction Session

A period of accumulated usage of protected applications until the
configured trigger duration is reached.

Switching between protected apps does not reset the timer.

### Global Cooldown

A cooldown that applies to **all protected apps simultaneously**.

### Daily Session Quota

The maximum number of triggered distraction sessions allowed per day.

## 7. Core User Flow

1.  User installs Refocus.
2.  User selects protected apps.
3.  User configures:
    -   Trigger duration.
    -   Daily session limit.
    -   Cooldown duration.
4.  User grants the required Android permissions.
5.  User opens a protected app.
6.  Refocus starts or resumes the global distraction timer.
7.  User switches to another protected app.
8.  The timer continues.
9.  User leaves protected apps.
10. The timer pauses.
11. Trigger duration is reached.
12. Session counter increments.
13. All protected apps enter global cooldown.
14. Cooldown ends.
15. User may use protected apps again.
16. When daily quota is exhausted, protected apps remain blocked until
    the next daily reset.

## 8. Example

Configuration:

-   Trigger: 5 minutes
-   Daily limit: 5 sessions
-   Cooldown: 15 minutes

Usage:

``` text
TikTok       3:00
Instagram    2:00
----------------
Total        5:00
```

Result:

``` text
Distraction Session: 1/5
Global Cooldown: 15 minutes
```

The timer must not reset simply because the user switched applications.

## 9. Functional Requirements

### FR-01 App Selection

Users must be able to select and remove protected apps.

### FR-02 Trigger Duration

Users must be able to configure how much accumulated protected-app usage
triggers a session.

### FR-03 Daily Session Limit

Users must be able to configure the maximum number of triggered sessions
per day.

### FR-04 Global Timer

The application must maintain a global distraction timer across
protected applications.

### FR-05 Timer Pause

The timer must pause when the user leaves all protected apps.

### FR-06 Cross-App Accumulation

Switching from one protected app to another must not reset the current
distraction timer.

### FR-07 Global Cooldown

When the trigger is reached, all protected apps must enter cooldown.

### FR-08 Daily Lock

When the daily session limit is reached, all protected apps must remain
blocked until the next daily reset.

### FR-09 Daily Reset

The daily session count must reset according to the device's local date.

### FR-10 Settings

Users must be able to change protection rules without an account.

### FR-11 Statistics

The MVP should provide basic local statistics such as:

-   Sessions today.
-   Total distraction time.
-   Remaining daily sessions.
-   Number of resisted/ended sessions, if implemented.

## 10. UX Principles

-   Calm rather than addictive.
-   Minimal animation.
-   No unnecessary notifications.
-   Clear explanation before requesting permissions.
-   User remains in control of settings.
-   Avoid shame-based language.
-   Make the next action obvious.

## 11. Main Screens

### Onboarding

Explain:

-   What Refocus does.
-   Why permissions are needed.
-   Privacy principles.

### Home

Show:

-   Current protection state.
-   Sessions used/remaining.
-   Current distraction time.
-   Cooldown status.

### Protected Apps

List selected applications.

### Rules

Configure:

-   Trigger duration.
-   Daily session limit.
-   Cooldown.

### Statistics

Show basic local usage insights.

### Focus Mode

Optional future feature for intentionally blocking selected apps during
a scheduled focus session.

## 12. Acceptance Criteria

The MVP is considered successful when:

-   A user can select multiple protected apps.
-   Usage can be accumulated across multiple protected apps.
-   Leaving protected apps pauses the timer.
-   Re-entering a protected app resumes the session.
-   Reaching the trigger activates a global cooldown.
-   Cooldown applies to every protected app.
-   Triggered sessions increment the daily counter.
-   Reaching the daily quota blocks protected apps until the next day.
-   Core functionality works without a Refocus account.
-   User activity data remains on-device by default.

## 13. Future Features

-   Focus Mode.
-   Scheduled protection.
-   Per-category rules.
-   Home-screen widgets.
-   Streaks.
-   Better statistics.
-   Website blocking.
-   Optional encrypted backup.
-   Optional cloud synchronization.
-   Family/managed-device mode.
