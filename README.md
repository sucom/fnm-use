# fnm-use: The companion tool to fast, bloat-free node switching

A lightweight companion utility script for <a href="https://github.com/Schniz/fnm" target="_blank">`fnm`</a> (Node.js version switcher) to switch node version with zero shell hooks, zero temporary symlink clutter, zero filesystem side effects, and absolute predictability.

Native `fnm` is a fantastic, ultra-fast Node version manager. However, its out-of-the-box shell configuration is heavily optimized for an aggressive feature: automatic version switching on directory change (`--use-on-cd`).

To achieve this, native `fnm` builds an abstraction layer using temporary environment session directories (`AppData\Local\fnm_multishells` | `~/.local/state/fnm_multishells/` | `/run/user/<your-uid>/fnm_multishells/`) and hidden symbolic links. If you close your IDE or terminal abruptly, these directories become orphaned, leaving thousands of stray file-system remnants over time and introducing unnecessary terminal initialization complexity.

If you don't need automatic directory switching and prefer explicitly controlling your active Node runtime, this tiny tool eliminates the bloat entirely.

## 🚀 The Core Philosophy
* **Zero Disk Bloat:** No hidden symbolic link structures or tracking folders are generated in your local directories.
* **Instant Startups:** Bypasses complex shell startup loop evaluation guards for near-zero terminal boot latency.
* **Pure Process Isolation:** Uses lightweight memory snapshots to safely swap the active path in the current window without polluting the global environment.


## 🛠️ Phase 1.1: Raw Installation & Directory Setup

> If you have already installed fnm, skip this step and go to Phase 1.2.

Skip package managers like `winget` or `Homebrew`, which introduce sandbox-tracking layers.

1. Go to the <a href="https://github.com/Schniz/fnm/releases" target="_blank">Official FNM GitHub Releases</a> page.
2. Download the compressed binary for your operating system (e.g., `fnm-windows.zip` or `fnm-macos.tar.gz`).
3. Extract the single standalone executable (`fnm.exe` or `fnm`) directly into your central binaries directory of choice (e.g., `C:\fnm`, `~/fnm`).

## 🛠️ Phase 1.2: Existing Installation Directory Lookup and Disable shell config

1. Locate your existing `fnm` directory which contains the `aliases` and `node-versions` folders. On macOS/Linux installations, this path typically defaults to `~/.local/share/fnm`. This path is your source of truth for the `FNM_DIR` environment variable.
2. To completely stop `fnm` from generating temporary session tracking links in your `fnm_multishells` folder, comment out or remove the native evaluation scripts inside your startup files (e.g., `~/.zshrc`, `~/.zprofile`, or `~/.bashrc`).

## 🌐 Phase 2: Global Environment Variables

Configure your system environment variables to establish `fnm`'s storage directory and map your system-wide fallback runtime.

### Windows Environment Variables

Configure these under **System Properties > Environment Variables**:

| Variable Type | Variable Name | Value | Purpose |
| :--- | :--- | :--- | :--- |
| **User/System Var** | `FNM_DIR` | `C:\fnm` *(or your custom path)* | Explicitly routes node downloads out of AppData |
| **User/System Var** | `PATH` | *Append Entry* `%FNM_DIR%\` | Makes the raw `fnm` utility globally accessible |
| **User/System Var** | `PATH` | *Append Entry* `%FNM_DIR%\aliases\default\` | Maps your standard global fallback version |

> 💡 *Note: Place these entries high up in your `PATH` variable list (ideally right under your central utility binaries folder) to guarantee priority over rogue third-party software installers.*

### Mac / Linux Environment Variables

Add these to your global profile configuration file (e.g., `~/.zshrc` or `~/.bashrc`):

```bash
# Existing installation path
export FNM_DIR="$HOME/.local/share/fnm"
# OR
# Raw installation path
#export FNM_DIR="$HOME/fnm"

export PATH="$FNM_DIR:$FNM_DIR/aliases/default/bin:$PATH"
```

## 📂 Phase 3: The Companion Scripts

Download and save the scripts (`fnm-use.cmd` and `fnm-use.sh`) and place them directly inside FNM_DIR folder (`C:\fnm` | `$HOME/fnm` | `$HOME/.local/share/fnm`) so they are immediately accessible globally.

### 1. Windows Command Prompt (`fnm-use.cmd`)
Download and Save this file in `FNM_DIR` folder.

### 2. Git Bash / MacOS / Linux (`fnm-use.sh`)
Download and Save this file in `FNM_DIR` folder.

### 3. Profile Wire-Up Setup

To link your interactive terminal aliases to the standalone scripts, add the matching execution lines below to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) startup configuration.

#### For Windows (Git Bash)
1. Set `FNM_DIR` to `C:\fnm` in your Windows System Properties environment variables panel.
2. Append the following alias line to your user profile setup (`~/.bashrc`):

```bash
alias fnm-use='source "$(cygpath -u "$FNM_DIR")/fnm-use.sh"'
```

#### For macOS & Linux (Zsh / Bash)
Add the following block to your configuration file (`~/.zshrc` or `~/.bashrc`):

```bash
# Define the environment directory safely using $HOME
# Existing installation path
export FNM_DIR="$HOME/.local/share/fnm"
# OR
# Raw installation path
#export FNM_DIR="$HOME/fnm"

# Set up the fallback path at the end of your PATH
export PATH="$FNM_DIR:$FNM_DIR/aliases/default/bin:$PATH"

# Add the fnm-use alias pointer
alias fnm-use='source "$FNM_DIR/fnm-use.sh"'
```

## 📖 Command Cheat Sheet & Workflow

With this architecture implemented, use the native `fnm` engine exclusively for downloading runtimes, and use our lightweight scripts for interactive context switching.

### 1. View Local Versions
Lists all runtimes safely extracted to your storage device.
```cmd
fnm list
```

### 2. Download a New Runtime
Downloads and unzips a node environment cleanly into your storage target directory.
```cmd
fnm install 24
```

### 3. Establish System-Wide Default
Updates the static global default fallback link. Every newly initialized terminal tab or external system application boots with this runtime choice automatically.
```cmd
fnm default 24
```

### 4. Switch Shell Runtime Context
Mounts your targeted environment dynamically to the current shell window instantly without file generation side effects.
```cmd
fnm-use 22          :: Exact or partial major-version lookup
fnm-use v22.23.1    :: Precise version matching
fnm-use             :: Smart scanning for local .node-version or .nvmrc configuration files
```

### 5. Standard Environment Inspection
```cmd
node -v
npm -v
```

## ⚖️ LICENSE

MIT