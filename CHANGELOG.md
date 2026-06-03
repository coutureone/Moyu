# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-06-03

### Added
- 数据管理补全：支持清空错词本、清空收藏、重置全部学习进度、导出/导入学习数据。
- 词库管理补全：设置页展示所有内置词库，支持自定义词库重命名、删除、导入预览和导入错误提示。
- 开机启动接入 macOS 登录项 API，菜单开关会真正注册/取消登录启动。
- 摸鱼模式增强：支持小窗模式、窗口透明度、固定右上角、隐藏/唤醒快捷键配置。

### Changed
- 设置页重新整合数据管理、词库管理和摸鱼模式配置，功能入口更集中。
- 自定义词库导入支持更稳健的 CSV 解析和 JSON 字段兼容。

### Fixed
- 修复“跟随系统”主题切换点击不生效的问题。
- 修复学习进度可能超过词库总数的问题。
- 修复自定义词库删除时相关错词、收藏、进度残留的问题。
- 修复文件选择器使用已弃用 API 的构建警告。

## [1.2.0] - 2026-01-10

### Added
- 🎯 **测试模式选择**：设置中可选择中文选英文、英文选中文、拼写模式
- ✏️ **拼写模式**：看中文释义手动输入英文单词，支持即时反馈
- 📊 **每日目标设置**：可设置每日学习目标（20/30/50/100/150/200词）
- 📈 **首页今日进度条**：实时显示今日学习进度，完成后显示"已完成"
- 🎊 **目标完成庆祝**：完成每日目标时显示额外庆祝动画
- 🔊 **TTS语速调节**：滑块调节发音语速（很慢到极快）
- 📐 **窗口尺寸记忆**：自动保存并恢复用户调整的窗口大小

### Changed
- 设置页学习设置区域重新设计，更清晰的分组布局
- 发音功能使用用户设置的语速

## [1.1.0] - 2026-01-07

### Added
- 首页自定义数量改为闹钟式滚轮选择，字号与布局优化
- 收藏夹、错词本、统计、设置等新页面入口与 UI
- 记忆/测试页收藏与错词记录，选择题顶部进度条
- 自定义词库导入（CSV/JSON），状态栏菜单可选择自定义词书
- 统计数据与成就：今日/累计对错数、连续天数、7 日记录、成就解锁
- 设置页：主题切换、提醒时间、进度重置、数据管理、热键唤醒

### Changed
- 窗口支持自定义尺寸，默认更贴合新 UI
- 主页标题与“自定义”文案加粗放大，滚轮选择区域缩小更紧凑

### Fixed
- 深色模式页面不统一、手动切换卡死问题
- 数据库新增字段重复执行 ALTER TABLE 的报错（增加列存在检查）

## [1.0.0] - 2024-01-07

### Added
- 初始版本发布
- SwiftUI 原生界面
- 支持多种英语词库（四六级、考研、托福、雅思、GRE、SAT 等）
- 支持日语词库（五十音、标日中级）
- 记忆模式和选择题测试
- 状态栏托盘菜单
- 快捷键支持
- TTS 发音功能
- SQLite 本地进度存储

### Fixed
- 修复图标白色边框问题（使用 PNG 格式和透明通道）
- 修复 Gatekeeper 阻止问题（添加安装说明）

[Unreleased]: https://github.com/coutureone/Moyu/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/coutureone/Moyu/compare/v2.0.2...v2.1.0
[1.2.0]: https://github.com/coutureone/Moyu/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/coutureone/Moyu/releases/tag/v1.1.0
[1.0.0]: https://github.com/coutureone/Moyu/releases/tag/v1.0.0
