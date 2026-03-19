# SkillDock

[English](./README.md) | [简体中文](./README.zh-CN.md)

SkillDock 是一款 macOS 应用，用于统一管理多应用的 AI skills。支持本地目录与 Git 来源、一键同步、全局开关与状态反馈。

## 主要功能

- 多应用技能目录管理
- 本地来源与 Git 来源管理
- 一键同步与冲突处理
- 技能搜索与详情查看
- 全局启用/禁用与状态反馈

## 下载安装

1. 在 GitHub Releases 下载最新版本
2. 解压并将 `SkillDock.app` 拖入「应用程序」
3. 双击打开即可使用

如果首次打开被系统拦截，请到「系统设置 → 隐私与安全性」允许打开。

## 使用方式

前置准备：先在本地创建来源目录，并提前把自己已有的 skills 全部转移到该来源目录。

1. 进入「来源管理」添加本地存放 skills 的目录（也支持通过 Git 地址添加）。
2. 切换左侧目标应用，点击「一键同步」写入对应应用的 skills 目录。
3. 在列表中搜索、查看详情，或执行移除/清空。
4. 「移除/清空全部」只会影响当前应用目标目录，不会修改原始来源目录。

同步异常处理建议：如果执行「一键同步」报错，先点击「清空全部」，再执行一次「一键同步」。

## 支持的应用与默认目录

- Claude Code: `~/.claude/skills`
- Codex: `~/.codex/skills`
- OpenCode: `~/.config/opencode/skills`
- Trae: `~/.trae/skills`
- Trae CN: `~/.trae-cn/skills`
- WorkBuddy: `~/.workbuddy/skills`
- CodeBuddy: `~/.codebuddy/skills`
- Aion UI: `~/.aionui-config/skills/`
- Qoder: `~/.qoder/skills/`

## 开发与构建

本项目使用 XcodeGen 生成项目文件。

```bash
xcodegen generate
xcodebuild -project SkillDock.xcodeproj -scheme SkillDock build
```

运行测试：

```bash
xcodebuild test -project SkillDock.xcodeproj -scheme SkillDock
```

## 常见问题

**Q: 添加来源后列表为空？**  
请确认来源目录内包含 `SKILL.md`，且目录未被隐藏或无访问权限。

**Q: 同步后应用未生效？**  
请确认目标应用的 skills 目录存在，且当前用户对该目录有读写权限。

**Q: 一键同步报错怎么办？**  
先在「已安装」视图点击「清空全部」，然后再次执行「一键同步」。同时请确认你已提前把个人 skills 转移到来源目录中，再进行同步。
