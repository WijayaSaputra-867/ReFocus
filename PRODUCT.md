# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Adults who want to manage their own social media and gaming habits independently. They are aware they spend too much time on distracting apps, and they want a tool that respects their autonomy rather than one that shames or locks them out without explanation.

## Product Purpose

Refocus measures accumulated distraction time across all user-selected protected apps as a single session, triggers a configurable cooldown when the threshold is reached, and enforces a daily session quota. This prevents the common bypass of simply switching between distracting apps.

Refocus does not try to prohibit technology use entirely; it introduces controlled friction while keeping the user in control of every rule.

## Positioning

Per-app timers can be bypassed by switching apps. Refocus counts distraction time globally across all protected apps as one continuous session — the only mechanism that closes this gap without requiring remote administration or an account.

## Operating Context

- Used on an Android device, entirely offline.
- The user configures rules once and then uses their device normally; Refocus operates invisibly in the background.
- The trigger, cooldown duration, and daily session limit are the three dials the user controls.
- Protected apps include social media (TikTok, Instagram), video platforms (YouTube), and mobile games.
- Requires Android Usage Statistics permission and, for active blocking, an Accessibility Service grant; both must be explained clearly before request.
- User data never leaves the device in the MVP.

## Capabilities and Constraints

**Confirmed capabilities:**
- Select and deselect individual protected apps.
- Configure trigger duration, daily session limit, and cooldown duration.
- Track accumulated distraction time across protected apps without resetting on app switches.
- Pause the timer when the user leaves all protected apps.
- Trigger a global cooldown across all protected apps when the threshold is reached.
- Increment and enforce a daily session counter; block all protected apps when the quota is exhausted until the next daily reset.
- Basic local statistics: sessions today, total distraction time, remaining sessions.
- No account required; no cloud storage in MVP.

**Platform constraints:**
- Android-first MVP (Flutter + Kotlin). iOS is not in scope for v1.
- Local-first: no remote analytics, no network telemetry, no cloud database in MVP.
- Must handle device reboot, process termination, Accessibility service being disabled, usage permission revoked, battery optimization restrictions, time/date changes, and app updates gracefully.

**Undecided for MVP:**
- Exact local persistence library (Drift, SQLite direct, or equivalent).
- Exact application/package ID.
- Open-source license.

## Brand Commitments

- Name: **Refocus**
- Tagline: **Take back your attention.**
- No visual assets yet; name and tagline are fixed.

## Evidence on Hand

No real testimonials, press, benchmarks, or case studies exist yet. Future work must not fabricate them.

## Product Principles

1. **Calm over coercive.** The interface informs and slows; it does not shame or permanently block without the user's own rules causing it.
2. **User-controlled rules.** Every limit is set by the user and can be changed by the user without an account or external approval.
3. **Transparent about permissions.** Each sensitive Android permission is explained before it is requested, with a clear statement of what it does and does not access.
4. **Local by default.** No data leaves the device unless the user explicitly opts in to a future sync feature.
5. **Auditable.** Open-source codebase; no proprietary telemetry; security policy maintained from day one.

## Accessibility & Inclusion

- Avoid shame-based language throughout the product.
- Explain permission requirements in plain language before requesting them.
- No specific WCAG target confirmed yet; apply standard Android accessibility conventions.

## Distribution

Direct APK / GitHub Releases (sideloading). Google Play Store is not the primary channel for the MVP.
