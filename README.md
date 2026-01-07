# Moyu 摸鱼背单词 (Swift 原生版)

<div align="center">

## 🐟 MOYU

#### 这是一个轻量、低调的背单词软件，可以让你在上班、上课等恶劣环境下安全隐蔽地背单词。

#### 本项目是 [ToastFish](https://lab.magiconch.com/toast-fish/) MacOS 版本的 **Swift 原生重构版**。

</div>

---

## ✨ 特性

- 🚀 **原生 Swift + SwiftUI** - 比 Electron 版本体积小 90%，启动速度快 10 倍
- 📚 **丰富词库** - 支持四六级、考研、托福、雅思、GRE、SAT 等英语词库
- 🇯🇵 **日语支持** - 包含五十音、标日中级词汇
- 🎯 **高效记忆** - 记忆模式 + 选择题测试
- ⌨️ **快捷键** - 支持数字键快速答题，ESC/Cmd+M 退出
- 🔊 **发音功能** - 系统 TTS 朗读单词
- 📊 **进度追踪** - SQLite 本地存储学习进度
- 🖥️ **状态栏托盘** - 低调运行，随时开始学习

---

## 🛠️ 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3) 或 Intel Mac

---

## 📦 安装

### 方式一：下载 DMG（推荐）

1. 从 [Releases](https://github.com/Charliecheung2/toastfish-mac/releases) 下载最新的 `Moyu-x.x.x.dmg`
2. 打开 DMG 文件
3. 将 `Moyu.app` 拖入 `Applications` 文件夹
4. 完成！

### 方式二：从源码编译

```bash
# 克隆仓库
git clone https://github.com/Charliecheung2/toastfish-mac.git
cd toastfish-mac/MoyuSwift

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

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `ESC` | 退出程序（焦点在 APP 上时） |
| `Cmd+M` | 退出程序（全局快捷键） |
| `1` / `2` / `3` | 快捷答题 |

### 基本流程

1. **选择词库** - 点击状态栏图标，选择想要背诵的词库
2. **设置数量** - 选择这次要背多少个单词
3. **开始记忆** - 查看单词、音标、释义、例句
4. **测试** - 根据中文选择正确的英文单词

### 页面说明

| 页面 | 功能 |
|------|------|
| 首页 | 选择背诵数量，点击"开始" |
| 记忆页 | 显示单词详情，可标记"记住了"或"太简单" |
| 选择题 | 根据中文释义选择正确单词 |
| 完成页 | 显示烟花庆祝，点击返回首页 |

---

## 📁 项目结构

```
MoyuSwift/
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
