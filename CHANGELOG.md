# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-09-12

### Added
- Cooldown completion notifications alerting users when their break ends or daily quota is reached.

### Fixed
- Fixed dark screen artifact upon recent-app swipe by stabilizing Android startup window background.
- Fixed false-pause distraction tracking when Refocus or transient system UI / launcher events are triggered while inside protected apps.
- Enforced cooldown blocker overlay resilience when app is swiped from recents.
- Standardized app display label to **Refocus**.

## [1.0.0] - 2026-09-09

### Added
- **Phase 0: Project Foundation**: Setup Flutter project, Git CI workflow, architecture & security documentation.
- **Phase 1: MVP Core**:
  - Global distraction engine across multiple protected apps.
  - Native Android app detection & Accessibility service integration.
  - Configurable rules: trigger duration, daily session limits, cooldown timer.
  - Local persistence via `SharedPreferences` (offline & local-first).
  - Modern calm UI with full Onboarding flow.
- **Phase 2: Polish & Ergonomics**:
  - Clean NavigationBar with 5 core tabs (Home, Apps, Rules, Stats, Permissions).
  - Live session timers and responsive cooldown indicators.
  - Resilient fallback for installed apps management.
- **Phase 3: Statistics**:
  - Daily distraction time, sessions count, resisted sessions tracking.
  - Weekly trends visualization with animated bar chart.
  - Daily breakdown table for 7-day history.
- **Phase 4: Focus Mode**:
  - Full-screen modal Focus Mode with circular countdown timer.
  - Customizable presets (15m, 25m, 45m, 60m).
  - Focus session completion stats tracking.
- **Phase 5: Community & Internationalization**:
  - GitHub issue templates (`bug_report`, `feature_request`, `config`).
  - Contribution guidelines (`CONTRIBUTING.md`) and Pull Request template.
  - Built-in Translation system (`TranslationService`) supporting English and Indonesian (`id`).
- **Phase 6: Advanced Features**:
  - Encrypted local backup and restore (`BackupService`) with passphrase verification.
  - Cross-device focus sync token generation.
  - Local-first website blocking list.
  - Per-category limits (Social, Entertainment, Games).
  - Home-screen widget state bridge.
