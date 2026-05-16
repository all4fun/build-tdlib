# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform build scripts for TDLib Java/JNI bindings. Each script clones the `tdlib/td` source, compiles the native JNI library + Java bindings, and outputs to a `tdlib/` directory.

## Local Build

- Linux: `/bin/bash build-linux.sh`
- macOS: `/bin/bash build-macos.sh`
- Windows (Git Bash/WSL): `/bin/bash build-windows.sh`

Each script is self-contained: it installs dependencies, clones `td`, builds, and installs artifacts. macOS script expects Homebrew; Linux script uses `apt-get` (requires `sudo`); Windows script uses vcpkg.

## CI / Release

Three GitHub Actions workflows (`.github/workflows/`):

- **Trigger**: tag creation (`v*` for Linux/macOS, `v*-windows` for Windows) + monthly cron (`0 0 1 * *`)
- **Runner**: `ubuntu-24.04`, `macos-latest`, `windows-latest`
- **Output**: `tdlib-<OS>-<ARCH>.tar.gz` uploaded as GitHub Release asset via `softprops/action-gh-release`
- **Artifact location**: scripts produce either `tdlib/` or `td/tdlib/` — the packaging step auto-detects which exists

## Build Architecture

Two-stage CMake build per platform:

1. Build TDLib core with `-DTD_ENABLE_JNI=ON`, install to `example/java/td`
2. Build Java example from `example/java/`, install to `tdlib/` (or `td/tdlib/`)

Platform-specific CMake flags:
- **macOS**: `-DJAVA_HOME=/opt/homebrew/opt/openjdk/...` and `-DOPENSSL_ROOT_DIR=/opt/homebrew/opt/openssl/`; uses `greadlink` (from coreutils)
- **Linux**: uses `readlink -e` for Td_DIR path resolution
- **Windows**: uses vcpkg toolchain (`-DCMAKE_TOOLCHAIN_FILE`) and `-A x64`

## Key References

- TDLib build docs: https://tdlib.github.io/td/build.html?language=Java
- Releases: https://github.com/all4fun/build-tdlib/releases
