# Refocus --- Security Policy

## Security Philosophy

Refocus is designed as an open-source, privacy-first application.

Because Refocus may use sensitive Android capabilities, security and
permission minimization are core requirements.

## Sensitive Components

The most sensitive areas are:

1.  Accessibility Service.
2.  Usage statistics access.
3.  Local application data.
4.  Android platform integration.
5.  Third-party dependencies.

## Permission Principles

Refocus must request only permissions that are required for a specific
feature.

Every sensitive permission should have:

-   A clear explanation.
-   A documented purpose.
-   A user-controlled enable/disable state where Android permits it.

## Accessibility Service

Accessibility functionality must not be used to:

-   Collect passwords.
-   Collect private message content.
-   Record arbitrary screen contents.
-   Transmit accessibility events to a remote server.
-   Perform unrelated actions on behalf of the user.

The service should perform the minimum interaction required to implement
distraction protection.

## Data Protection

The MVP should keep usage data on-device.

Do not store:

-   Passwords.
-   Authentication secrets.
-   API keys.
-   Private signing keys.
-   Unnecessary screen content.
-   Unnecessary Accessibility event data.

## Open Source Security

The repository is public, but secrets must never be committed.

Use:

-   Secret scanning.
-   Dependency vulnerability scanning.
-   Automated tests.
-   Code review.
-   Signed releases where practical.
-   Dependabot or an equivalent dependency update process.

## Reporting a Vulnerability

Security vulnerabilities should be reported privately rather than
publicly disclosed before a fix is available.

The project should provide a private security reporting channel through
the repository's security features.

## Threat Model

Potential threats include:

-   Malicious modified builds.
-   Vulnerable dependencies.
-   Incorrect Accessibility implementation.
-   Local data exposure.
-   Permission misuse.
-   Tampered application state.
-   Supply-chain compromise.

## Official Builds

Users should be directed to official distribution channels and the
official source repository.

Modified third-party APKs should not be treated as official Refocus
releases.

## Security Checklist Before Release

-   [ ] No secrets in source code.
-   [ ] Release signing configured.
-   [ ] Dependencies reviewed.
-   [ ] Android permissions documented.
-   [ ] Accessibility behavior reviewed.
-   [ ] No unnecessary network permissions.
-   [ ] No sensitive logging in production.
-   [ ] Crash logs do not expose private usage information.
-   [ ] Security reporting process documented.
