# Contributing to Refocus

Thank you for your interest in contributing to Refocus! Refocus is an open-source, privacy-first, local-first digital wellbeing application.

## Core Principles

1. **Local-First**: User activity data must never leave the device. No remote telemetry, no external accounts, no cloud dependencies for core features.
2. **Minimalist & Calm**: Refocus avoids shame-based language, high-friction gimmicks, and addictive gamification.
3. **Ponytail Philosophy**: Choose the simplest, shortest, most maintainable solution that works. Reach for standard libraries and native platform capabilities before adding third-party dependencies.

## Getting Started

### Prerequisites

- Flutter SDK (version ^3.12.2 or higher)
- Android SDK & Android Studio (for native Android testing)
- Dart SDK

### Clone & Setup

```bash
git clone https://github.com/your-repo/refocus.git
cd refocus
flutter pub get
```

### Running Tests & Verification

Before submitting any code, always ensure formatting, analysis, and tests pass:

```bash
# Verify code formatting
dart format --set-exit-if-changed .

# Run static analysis
flutter analyze

# Run automated tests
flutter test
```

## Pull Request Guidelines

1. **Keep it focused**: One feature or bug fix per pull request.
2. **Add tests**: Any logic changes in `lib/domain/` or UI flow should have corresponding unit or widget tests in `test/`.
3. **No unnecessary dependencies**: Check if the standard library or Flutter framework can handle it before adding a package to `pubspec.yaml`.
4. **Security & Privacy**: Read [SECURITY.md](SECURITY.md) before introducing permissions or background services.

## Reporting Issues

- **Bug Reports**: Use the Bug Report issue template. Include device OS version, reproduction steps, and expected vs actual behavior.
- **Feature Requests**: Use the Feature Request template. Explain the motivation and how it aligns with the local-first philosophy.
- **Security Vulnerabilities**: Please report security vulnerabilities privately via GitHub Security Advisories or the contact listed in [SECURITY.md](SECURITY.md).
