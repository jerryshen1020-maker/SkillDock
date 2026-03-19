# SkillDock

[English](./README.md) | [简体中文](./README.zh-CN.md)

SkillDock is a macOS app for unified AI skill management across multiple applications. It supports local folders and Git sources, one-click sync, global toggles, and clear status feedback.

## Features

- Multi-app skills directory management
- Local directory and Git repository sources
- One-click sync with conflict handling
- Skill search and detail view
- Global enable/disable state management

## Install

1. Download the latest build from GitHub Releases.
2. Unzip and move `SkillDock.app` to `Applications`.
3. Open the app and start using it.

If macOS blocks the first launch, allow it in `System Settings → Privacy & Security`.

## Usage

Prerequisite: create a source directory and move your existing skills into this source directory before syncing.

1. Open `Sources` and add your local skills directory (or add a Git repository source).
2. Select an app from the left sidebar and click `Sync Now`.
3. Search skills, open details, remove, or clear installed items as needed.
4. `Remove/Clear All` only affects the selected app target directory, not your original source directory.

Sync recovery tip: if `Sync Now` fails, click `Clear All` first, then run `Sync Now` again.

## Supported Apps and Default Paths

- Claude Code: `~/.claude/skills`
- Codex: `~/.codex/skills`
- OpenCode: `~/.config/opencode/skills`
- Trae: `~/.trae/skills`
- Trae CN: `~/.trae-cn/skills`
- WorkBuddy: `~/.workbuddy/skills`
- CodeBuddy: `~/.codebuddy/skills`
- Aion UI: `~/.aionui-config/skills/`
- Qoder: `~/.qoder/skills/`

## Development

This project uses XcodeGen.

```bash
xcodegen generate
xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build
```

Run tests:

```bash
xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock
```

## FAQ

**Q: Why is the list empty after adding a source?**  
Make sure the source directory contains `SKILL.md` files and is not hidden or inaccessible.

**Q: Skills do not take effect after sync. Why?**  
Confirm the target app skills directory exists and your current user has read/write permission.

**Q: What should I do if one-click sync reports errors?**  
In `Installed`, click `Clear All`, then run `Sync Now` again. Also make sure your personal skills were moved into your configured source directory before syncing.
