# S.P.O.U.T. (Synergistic Plugins Optimizing Usability of Transformers)

SPOUT is an experimental software framework created to unlock the full potential of deep-learning (AI) language models (LLMs) with a suite of specialized tools for creating, transforming, and managing text-based content.

## 🌟 Features

- **Multiple LLM Provider Support**: Use models from OpenAI, Anthropic, Google, DeepSeek, and more
- **12 Core Lexical Function Categories** for advanced prompt engineering
- **Diverse Scripting Examples**: Automate with Python, shell, Node, and more
- **Fully Extensible** with growing third-party addon modules
- **Comprehensive API Logging** for usage tracking and optimization
- **Fully Open Source** & free for personal and commercial use

## 🚀 Getting Started



### Prerequisites

Before installing SPOUT, ensure you have:
- Python 3.x installed
- A supported operating system (Windows required for GUI/Hotkey features)
- At least one API key from a supported provider

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/spout.git
cd spout
```

2. Install dependencies:
```bash
pip install -e .
```

3. Configure your API keys in `spout/config/settings.ini` or through the settings GUI (Capslock + `)

### API Key Setup

You'll need at least one API key from the following providers:
- [OpenAI Platform](https://platform.openai.com/api-keys)
- [Anthropic Console](https://console.anthropic.com/account/keys)
- [Google Gemini AI](https://makersuite.google.com/app/apikey)
- [DeepSeek Platform](https://platform.deepseek.com/api)
- [Replicate Dashboard](https://replicate.com/account/api-tokens)

## 🛠️ Usage

### Command Line Interface
```bash
# Basic text processing
spout enhance "wassup"

# Specify plugin
spout reduce -u namer "How much wood could a woodchuck chuck?"

# Chain operations
spout translate -s "spanish" "$(spout expand "hello")"
```

### Hotkey Console (Windows Only)
Common hotkeys:
- `Capslock + Shift`: Toggle Capslock
- `Capslock + \` : Spout Settings
- `Capslock + Tab`: Clipboard Manager
- `Capslock + Space`: Context Menu
- `Capslock + Esc`: Restart Spout Script

## 📁 Project Structure

```bash
spout_workspace/
├── spout/             # Main package directory
│   ├── addons/        # Extension modules
│   ├── core/          # 12 Core Modules
│   ├── config/        # Configuration files
│   ├── shared/        # Shared resources
│   ├── [consoles]     # Console AHK files
│   └── [scripts]      # CLI and AHK scripts
├── scripting/         # Automation scripts
├── testing/           # Testing tools
└── notes/             # Application notes
```

## 🔧 Configuration

The `spout/config/settings.ini` file contains important configurations:

- `Theme`: UI theme options
- `BrowserLocation`: Preferred browser path
- `NotesFolder`: Output directory
- `PreferredModel`: Default AI model
- `TokenCountModel`: Token counting model
- `SoundEffects`: Enable/disable sounds

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the APACHE 2.0 - see the [LICENSE](LICENSE) file for details.

## 🌱 Origins

SPOUT began as a personal workspace for prompt engineering experiments and AutoHotkey automation scripts in 2024. What started as a collection of utilities to streamline AI workflows evolved into a comprehensive framework spanning over 10,000 lines of code in multiple languages.

## ✨ Interface Options

1. **Command Line Tools**: Terminal-based interaction with intuitive command-line interface
2. **Hotkey Consoles**: Transform your keyboard into an automation command center (Windows Only)
3. **Graphical Interfaces**: Access features through intuitive, modular windows (Windows Only)

## 📚 Documentation

For more detailed information, visit our [documentation pages](https://spout.dev)