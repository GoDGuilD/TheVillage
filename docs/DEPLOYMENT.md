<!--
File: DEPLOYMENT.md
Description: How builds are distributed.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-22
Version: 1.1.0
-->

# Deployment

Beta builds follow Chapel of Dreams' path: the Windows export (see `BUILD.md`) lands in
`H:\PROJECTS\Exported Games\The Village.exe` and, for testers, goes onto the beta-testing VMs with
`J:\Docker\guacamole_stack\add-game.ps1 -Name "The Village" -Source <exe> -Exe "The Village.exe"` (PowerShell 7).
That copies it into every running tester clone (`C:\Games\The Village`, desktop shortcut); clones that are rebuilt
lose it unless it is also added with `-Target Master`. First beta: 8.1.0 on 2026-10-22 (clones only). Nothing is
published to a store before the release phase.
