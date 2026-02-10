```markdown
# Claude Code in a Box (Alpine Edition)

A secure, isolated development environment for running **Claude Code** inside an Alpine Linux Distrobox container. 

This setup ensures that Claude has the performance it needs while strictly limiting its access to **only** the current directory and a dedicated sandbox home.

## 🛡️ Security Features

* **Filesystem Isolation**: The container cannot see your host's `$HOME` (Documents, SSH keys, Browser data). It uses a local `.claude_sandbox` folder for all configuration and authentication tokens.
* **Path Restriction**: Only the current project directory is mounted into the container.
* **Resource Capping**: Limits the container to 4 CPU cores and 8GB of RAM (configurable in the script).

## 🚀 Quick Start

### 1. Prerequisites
Ensure you have `distrobox` and either `podman` or `docker` installed on your host system.

### 2. Setup
Run the setup script inside your project folder:
```bash
chmod +x setup_claude.sh
./setup_claude.sh

```

### 3. Usage

The script generates a local helper script to launch the environment:

```bash
./claude-start.sh

```

## 📦 Alpine-Optimized Dependencies

To ensure Claude Code runs smoothly on Alpine's `musl` architecture, this repo automatically installs:

* `gcompat`: For glibc compatibility.
* `ripgrep`: System-level search tool (overriding the built-in binary).
* `libstdc++ / libgcc`: Required for Node.js native modules.
* `USE_BUILTIN_RIPGREP=0`: Environment flag to ensure search stability.

## 🛠️ Configuration

You can adjust resource limits inside `setup_claude.sh`:

* `CPU_LIMIT`: Number of cores.
* `MEM_LIMIT`: Maximum memory (e.g., `8G`).

## 🧹 Cleanup

To remove the container and its sandbox:

```bash
distrobox rm claude-workspace
rm -rf .claude_sandbox claude-start.sh

```

