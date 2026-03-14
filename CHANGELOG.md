# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-03-14

### Added
- 🚀 **开机启动功能**：使用 ServiceManagement 框架实现真正的开机启动
- 💾 **数据管理增强**：支持清空错词本、收藏夹、所有学习进度
- 📤 **数据导出**：支持导出学习数据到 JSON 文件
- 🔍 **词库搜索**：新增搜索单词功能

### Changed
- 📊 **统计图表改进**：macOS 14+ 显示正确/错误数量细分
- 更新项目链接地址到新仓库

### Fixed
- 修复了一些编译问题

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
- 主页标题与"自定义"文案加粗放大，滚轮选择区域缩小更紧凑

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

[Unreleased]: https://github.com/coutureone/Moyu/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/coutureone/Moyu/releases/tag/v1.3.0
[1.2.0]: https://github.com/coutureone/Moyu/releases/tag/v1.2.0
[1.1.0]: https://github.com/coutureone/Moyu/releases/tag/v1.1.0
[1.0.0]: https://github.com/coutureone/Moyu/releases/tag/v1.0.0
