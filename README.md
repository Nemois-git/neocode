# Xcode Build & Run Helper

![License](https://img.shields.io/badge/License-MIT-blue.svg)

This Zsh script provides a command-line interface to automate common `xcodebuild` tasks for iOS/macOS projects. It simplifies the process of building, running, cleaning, and listing targets for both simulators and physical devices.

> I created this using Google Gemini. My goal was to develop a command-line interface (CLI) application that is easy to use.

## ⚠️ Gemini AI-Assisted Code Disclaimer

Please be aware that this script was developed with significant assistance from Gemini. While it aims to be a helpful utility, it may contain instabilities, bugs, or suboptimal logic.

**Use it at your own risk.** Thorough testing on your specific project is highly recommended before relying on it for critical workflows.

## Features

* **Build:** Incrementally build your project for a specific simulator or a generic device.
* **Run:** Automatically build, install, and launch your app on a specified simulator or physical device, streaming the console logs.
* **List:** Display all available devices and simulators with their UDIDs (using `xcrun xctrace`).
* **Clean:** Remove the local `build` directory (`./build`).

## Prerequisites

* macOS with Xcode and Xcode Command Line Tools installed.
* `zsh` (default shell on modern macOS).
* `devicectl` (for running on physical devices, included with recent Xcode versions).

## Configuration

Before using the script, you **must** edit the configuration variables at the top of the file to match your project.

```bash
# .xcworkspace or .xcodeproj file path
PROJECT_FILE="App.xcworkspace"

# Xcode Scheme name to build
SCHEME_NAME="App"

# The name of the .app file generated after the build (Xcode's Build Settings > Product Name)
# e.g., Even if SCHEME_NAME is "App-Dev", the app name might be "App.app".
PRODUCT_NAME="App"

# Default simulator target name
DEFAULT_SIMULATOR_NAME="iPhone 16e"

```

### Make the script executable

Save the script (e.g., as `build.zsh`) and make it executable:

```bash
chmod +x build.zsh
```

## Usage

The script uses a simple `[ACTION] [TARGET_ENV] [TARGET_ID]` format.

```bash
./build.zsh [build|run|list|clean] [simulator|device] [TARGET_ID]
```

---

```bash
### List Targets

To find the correct `TARGET_ID` (name or UDID) for your simulators and devices, run:

./build.zsh list

---

### Build

# Build for the default simulator (defined in the script)
./build.zsh build simulator

# Build for a specific simulator by name
./build.zsh build simulator "iPhone 16e"

# Build for a generic device (e.g., for archiving or validation)
./build.zsh build device

# Build for a specific device (useful for managing provisioning)
./build.zsh build device <YOUR-DEVICE-UDID>

---

### Run

# Build and run on the default simulator
./build.zsh run simulator

# Build and run on a specific simulator by name
./build.zsh run simulator "iPhone 16e"

# Build and run on a specific physical device
# The [TARGET_ID] (UDID) is required for 'run device'
./build.zsh run device <YOUR-DEVICE-UDID>

---

### Clean

# Clean the build directory
./build.zsh clean
```

---

## License

MIT License

Copyright (c) 2025 nemois

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
