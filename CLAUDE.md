# GoDot Workspace

This folder contains **Godot 4.6.3 standalone binaries** only. The actual game project lives elsewhere.

## Game Project
- **Name:** The Village
- **Path:** `C:/Users/email/OneDrive/DEV/TheVillage/`
- **Engine:** Godot 4.6.3 (standalone — no system installation)

## MCP Setup
The `godot-mcp` MCP server connects Claude Code directly to the Godot editor.

- **Plugin:** yurineko73/Godot-MCP-Native (installed in the game project's `addons/` folder)
- **URL:** `http://localhost:9080/mcp`
- **Already registered:** `claude mcp list` should show `godot-mcp: ✓ Connected`

**Prerequisite:** Godot must be open with TheVillage project loaded and the plugin enabled before starting a Claude Code session. If the MCP shows as disconnected, open Godot first.

## Workflow
1. Open `Godot_v4.6.3-stable_win64.exe`
2. Open the TheVillage project
3. Confirm the MCP plugin is enabled (`Project → Project Settings → Plugins`)
4. Start Claude Code — the MCP will connect automatically
