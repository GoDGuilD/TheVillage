<!--
File: SECURITY.md
Description: Security policy.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Security

The game is an offline single-player desktop program: no accounts, no network code, no telemetry. Rules that still apply:

- No secrets in the repo; `.env`, `.dev.vars` and similar files are git-ignored.
- Save files (from Phase 4) will be plain JSON in the user data folder and are treated as untrusted input when loaded.
- Report problems privately to the owner (`AUTHORS.md`).
