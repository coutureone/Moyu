<div align="center">
  <a href="https://github.com/coutureone/Moyu/blob/main/README.md">🌐 中文 / English</a>
</div>

# Moyu

<div align="center">

## 🐟 MOYU

#### A lightweight and discreet vocabulary learning app that allows you to study vocabulary secretly in adverse environments like work or class.

</div>

---

## ✨ Features

- 🚀 **Native Swift + SwiftUI** - Lightweight and fast
- 📚 **Rich Word Banks + Custom Banks** - Supports CET-4/6, Graduate, TOEFL, IELTS, GRE, SAT, with CSV/JSON import
- 🇯🇵 **Japanese Support** - Includes Hiragana, Shinkango vocabulary
- 🎯 **Efficient Learning** - Memory mode + Multiple choice tests with progress bar
- ⭐ **Favorites & Wrong Book** - One-click favorite/wrong word marking from memory page
- 📈 **Statistics Panel** - Today/total correct/wrong counts, streak days, 7-day records, achievements
- 🎚️ **Custom Quantity** - Clock-style picker for learning quantity
- 🎨 **Themes & Settings** - Light/dark mode, reminder time, progress reset, data management
- ⌨️ **Keyboard Shortcuts** - Number keys for answers, ESC/Cmd+Q to quit, hotkey wake-up
- 🔊 **Pronunciation** - System TTS reading
- 📊 **Progress Tracking** - SQLite local storage
- 🖥️ **Status Bar Tray** - Discreet operation, start anytime

---

## 🛠️ System Requirements

- macOS 13.0 (Ventura) or higher
- Apple Silicon (M1/M2/M3) or Intel Mac

---

## 📦 Installation

### Option 1: Download DMG (Recommended)

1. Download the latest `Moyu-x.x.x.dmg` from [Releases](https://github.com/coutureone/Moyu/releases)
2. Open the DMG file
3. Drag `Moyu.app` to the `Applications` folder
4. Done!

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/coutureone/Moyu.git
cd Moyu

# Open with Xcode
open Moyu.xcodeproj

# Or build via command line
xcodebuild -project Moyu.xcodeproj -scheme Moyu -configuration Release build

# Package as DMG
chmod +x build_dmg.sh
./build_dmg.sh
```

---

## 🎮 Usage

### Basic Flow

1. **Select Word Bank** - Click status bar icon, choose built-in or custom word bank
2. **Set Quantity** - Use picker on home page to select how many words to learn
3. **Start Memorizing** - View word, phonetic symbols, meanings, example sentences; can favorite or mark as wrong
4. **Test** - Answer in multiple choice mode with progress bar

### Pages

| Page | Description |
|------|-------------|
| Home | Picker for quantity, start learning |
| Memory | View word details, pronunciation, favorite/wrong |
| Choice | Select correct English by Chinese meaning, progress bar |
| Wrong Book | View wrong words, practice or remove |
| Favorites | View favorites, practice or remove |
| Statistics | Today/total, correct/wrong, streak days, 7-day records, achievements |
| Settings | Theme, reminder time, progress reset, data management, custom word import |

---

## 📁 Project Structure

```
Moyu/
├── Moyu.xcodeproj/          # Xcode project file
├── Moyu/
│   ├── MoyuApp.swift        # App entry + AppDelegate
│   ├── Models/
│   │   ├── AppState.swift   # Global state management
│   │   └── Word.swift       # Data models
│   ├── Views/
│   │   ├── ContentView.swift     # Main container view
│   │   ├── HomeView.swift        # Home page
│   │   ├── RememberView.swift    # Memory page
│   │   ├── ChoiceView.swift      # Choice question page
│   │   └── CongratulateView.swift # Completion page
│   ├── Services/
│   │   └── DatabaseService.swift # SQLite database service
│   ├── Utils/
│   │   └── Extensions.swift      # Utility extensions
│   └── Resources/
│       └── Assets.xcassets       # Resource files
├── build_dmg.sh             # DMG packaging script
└── README.md                # Documentation
```

---

## 🤝 Contributing

Issues and Pull Requests are welcome!

---

## 📄 License

MIT License

---

## 🌟 Acknowledgments

- Original [ToastFish](https://lab.magiconch.com/toast-fish/)
- [Electron version toastfish-mac](https://github.com/Charliecheung2/toastfish-mac)
