<div align="center">
  <a href="https://github.com/coutureone/Moyu/blob/main/README_en.md">🌐 English / 中文</a>
</div>

# Moyu 摸鱼背单词

<div align="center">

## 🐟 MOYU

#### 这是一个轻量、低调的背单词软件，可以让你在上班、上课等恶劣环境下安全隐蔽地背单词。

</div>

---

## ✨ 特性

- 🚀 **原生 Swift + SwiftUI** - 轻量快速
- 📚 **丰富词库 + 自定义词库** - 支持四六级/考研/托福/雅思/GRE/SAT/日语词库，支持 CSV/JSON 导入、预览、重命名和删除
- 🇯🇵 **日语支持** - 包含五十音、标日中级词汇
- 🎯 **高效记忆** - 记忆模式 + 选择题测试，顶部进度条
- ⭐ **收藏夹 & 错词本** - 记忆页可一键收藏/加入错词，支持列表查看与再次练习
- 📈 **统计面板** - 今日/累计对错数、连续天数、7 日记录、成就解锁
- 🎚️ **自定义数量** - 闹钟式滚轮选择学习数量
- 🎨 **主题与设置** - 跟随系统/明亮/暗黑切换，提醒时间，进度重置，数据导入导出
- 🫥 **摸鱼模式** - 透明度、小窗模式、固定角落、一键隐藏和快捷唤醒配置
- ⌨️ **快捷键** - 数字键答题、ESC/Cmd+Q 退出，支持可配置隐藏/唤醒热键
- 🔊 **发音功能** - 系统 TTS 朗读
- 📊 **进度追踪** - SQLite 本地存储学习进度
- 🖥️ **状态栏托盘** - 低调运行，随时开始

---

## 🛠️ 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3) 或 Intel Mac

---

## 📦 安装

### 方式一：下载 DMG（推荐）

1. 从 [Releases](https://github.com/coutureone/Moyu/releases) 下载最新的 `Moyu-x.x.x.dmg`
2. 打开 DMG 文件
3. 将 `Moyu.app` 拖入 `Applications` 文件夹
4. 完成！

### 方式二：从源码编译

```bash
# 克隆仓库
git clone https://github.com/coutureone/Moyu.git
cd Moyu

# 使用 Xcode 打开
open Moyu.xcodeproj

# 或者使用命令行编译
xcodebuild -project Moyu.xcodeproj -scheme Moyu -configuration Release build

# 打包成 DMG
chmod +x build_dmg.sh
./build_dmg.sh
```

---

## 🎮 使用说明

### 基本流程

1. **选择词库** - 点击状态栏图标，选择内置词库或导入的自定义词库
2. **设置数量** - 在首页用滚轮选择本次背多少个
3. **开始记忆** - 查看单词、音标、释义、例句，可收藏或加入错词
4. **测试** - 选择题模式答题，顶部有进度条

### 页面说明

| 页面 | 功能 |
|------|------|
| 首页 | 滚轮自定义数量，开始学习 |
| 记忆页 | 查看单词详情，朗读，收藏/错词 |
| 选择题 | 根据中文释义选择正确单词，进度条提示 |
| 错词本 | 查看错词，再练或移除 |
| 收藏夹 | 查看收藏，单词练习或移除 |
| 统计 | 今日/累计，对错数，连续天数，7 日记录，成就 |
| 设置 | 主题切换、提醒时间、进度重置、数据导入导出、词库管理、摸鱼模式 |

---

## 📁 项目结构

```
Moyu/
├── Moyu.xcodeproj/          # Xcode 项目文件
├── Moyu/
│   ├── MoyuApp.swift        # 应用入口 + AppDelegate
│   ├── Models/
│   │   ├── AppState.swift   # 全局状态管理
│   │   └── Word.swift       # 数据模型
│   ├── Views/
│   │   ├── ContentView.swift     # 主容器视图
│   │   ├── HomeView.swift        # 首页
│   │   ├── RememberView.swift    # 记忆页
│   │   ├── ChoiceView.swift      # 选择题页
│   │   └── CongratulateView.swift # 完成页
│   ├── Services/
│   │   └── DatabaseService.swift # SQLite 数据库服务
│   ├── Utils/
│   │   └── Extensions.swift      # 工具扩展
│   └── Resources/
│       └── Assets.xcassets       # 资源文件
├── build_dmg.sh             # DMG 打包脚本
└── README.md                # 说明文档
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📄 许可证

MIT License

---

## 🌟 致谢

- 原版 [ToastFish](https://lab.magiconch.com/toast-fish/)
- [Electron 版 toastfish-mac](https://github.com/Charliecheung2/toastfish-mac)
