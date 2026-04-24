<div align="center">

```text
   ____ _ __  _       _ __ 
  / __ `/(_) /_(_)___  (_) /_
 / /_/ // / __/ / __ \/ / __/
 \__, // / /_/ / / / / / /_  
/____//_/\__/_/_/ /_/_/\__/  
```

**Project Bootstrapper & Automator**

[![Latest Version](https://img.shields.io/github/v/tag/wd006/gitinit?sort=semver&color=blue&label=version)](https://github.com/wd006/gitinit/tags)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()
[![Top Language](https://img.shields.io/github/languages/top/wd006/gitinit?color=green)](https://github.com/wd006/gitinit)
[![License](https://img.shields.io/github/license/wd006/gitinit)](LICENSE)

</div>

<br>

**GitInit** is a zero-dependency, highly customizable CLI wizard designed to eliminate the repetitive tasks of starting a new project. It automates directory creation, metadata generation (`README`, dynamic `LICENSE`, `.gitignore`, `.gitattributes`), NPM versioning setups, and local/remote repository initialization via GitHub CLI. It also features a persistent, self-contained ecosystem to remember your preferences and custom templates.

## 📑 Table of Contents
- [✨ Features](#-features)
-[🚀 Installation & Quick Start](#-installation--quick-start)
- [📖 Documentation & Usage](#-documentation--usage)
- [⚙️ Under the Hood (Architecture)](#️-under-the-hood-architecture)
- [🧹 Cleanup & Uninstall](#-cleanup--uninstall)
- [📄 License](#-license)
- [🤝 Contributing](#-contributing)
- [📬 Contact](#-contact)

## ✨ Features

- **🧠 Persistent Memory:** Automatically learns and saves your preferred directories, license owners, and default branch names to speed up future setups.
- **📄 Template Engine:** Import your own custom `LICENSE` and `.gitignore` files. Custom licenses automatically dynamically populate `{{YEAR}}` and `{{OWNER}}` placeholders upon creation.
- **🛠️ GitHub CLI Integration:** Detects `gh` on your system to automatically create public/private remote repositories and push your initial commit without opening a browser.
- **🛡️ Cross-Platform Safety:** Automatically generates `.gitattributes` to enforce consistent `LF` line endings, preventing `CRLF` git diff nightmares.
- **📦 NPM Versioning:** Seamlessly initializes `package.json` and silently injects `commit-and-tag-version` for standardized release management.
- **🎛️ Configuration Manager:** A built-in CRUD interface to easily manage your saved templates and default configurations.

## 🚀 Installation & Quick Start

You can download and run `gitinit` using a single curl command. For the best experience, move it to your system's `bin` folder so you can use it globally.

```bash
curl -O https://raw.githubusercontent.com/wd006/gitinit/main/gitinit.sh && chmod +x gitinit.sh && sudo mv gitinit.sh /usr/local/bin/gitinit
```

### Prerequisites
- Bash (macOS or Linux)
- `gh` (Optional, required for automatic remote GitHub repository creation. Install via `brew install gh` or `apt install gh`).
- `npm` (Optional, required for `commit-and-tag-version` setup).

## 📖 Documentation & Usage

**GitInit** supports multiple execution modes via CLI arguments to fit your workflow:

### 1. Normal Mode
Just type `gitinit` in your terminal. The CLI wizard will guide you through:
- Selecting or adding a base directory.
- Providing project metadata (Name, Description).
- Selecting an owner and a license (Built-in or imported).
- Generating a `.gitignore` and enforcing `.gitattributes`.
- Configuring NPM versioning.
- Pushing to a remote URL or generating one via GitHub CLI.

```bash
gitinit
```

### 2. Configuration Mode ( 🚧 In Development 🚧 )
Open the interactive Configuration Manager to add, remove, or modify your saved preferences, directories, owners, and custom templates.

```bash
gitinit --config
```

### 3. No-Config Mode
Run in an isolated state. `gitinit` will not read from or write to your saved memory. Perfect for one-off projects where you do not want to alter your defaults.

```bash
gitinit --no-config
```

## ⚙️ Under the Hood (Architecture)

`GitInit` does not clutter your global dotfiles. Instead, it creates a self-contained, portable ecosystem in your home directory (`~/.gitinit/`).

```text
~/.gitinit/
├── config.env           # Stores your preferences, arrays, and behavior flags
├── gitignores/          # Copies of your imported custom .gitignore files
└── licenses/            # Copies of your imported custom LICENSE files
```

Because your custom templates are physically copied into this ecosystem, you can safely delete the original source files without breaking your workflow.

## 🧹 Cleanup & Uninstall

Want to reset your preferences or completely remove the tool's memory? You can purge the entire ecosystem safely:

```bash
gitinit --reset
```
*(Note: This only deletes the `~/.gitinit` directory and its contents. It does not affect any projects you have previously created).*

---

## 📄 License

This project is licensed under the MIT License. See the [`LICENSE`](LICENSE) file for more details.

## 🤝 Contributing

Contributions are greatly appreciated. Please fork the repository and create a pull request, or open an issue for major changes.

## 📬 Contact

**E-Mail:** [github@wd006.pp.ua](mailto:github@wd006.pp.ua)

**Project Link:** [https://github.com/wd006/gitinit](https://github.com/wd006/gitinit)

For questions, bug reports, or support, please **open an issue** on the GitHub repository.