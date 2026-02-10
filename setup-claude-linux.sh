#!/bin/bash

# --- Configuration ---
CONTAINER_NAME="claude-workspace"
IMAGE="alpine:latest"
CPU_LIMIT="4" 
MEM_LIMIT="8G"

# 1. Prepare Workspace
# We create a local sandbox for Claude's config/auth and binaries
WORKSPACE_DIR=$(pwd)
SANDBOX_HOME="$WORKSPACE_DIR/.claude_sandbox"
mkdir -p "$SANDBOX_HOME"

echo "🛡️  Initializing restricted Distrobox in: $WORKSPACE_DIR"

# 2. Create the container
# --home: Redirects home to our sandbox folder
# --volume: Mounts ONLY the current directory
# USE_BUILTIN_RIPGREP=0: Force use of Alpine's ripgrep
distrobox create -n "$CONTAINER_NAME" -i "$IMAGE" --yes \
    --home "$SANDBOX_HOME" \
    --additional-flags "--cpus=$CPU_LIMIT --memory=$MEM_LIMIT --volume $WORKSPACE_DIR:$WORKSPACE_DIR:rw -e USE_BUILTIN_RIPGREP=0"

echo "📦 Installing Claude Code and Alpine-specific dependencies..."

# 3. Setup Inside Alpine
distrobox enter "$CONTAINER_NAME" -- sh -c "
    # Update and install recommended dependencies
    sudo apk update
    sudo apk add --no-cache \
        nodejs npm git bash curl \
        libgcc libstdc++ gcompat \
        ripgrep make g++ python3

    # Install Claude Code via the official installer
    curl -fsSL https://claude.ai/install.sh | bash

    # Fix the PATH permanently inside the sandbox home
    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \$HOME/.profile
    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \$HOME/.bashrc

    echo '✅ Installation complete!'
"

echo "---"
echo "🚀 To start Claude in this workspace, run:"
echo "distrobox enter $CONTAINER_NAME -- bash -l -c 'cd $WORKSPACE_DIR && claude'"

# Optional: Create a local launcher script for convenience
cat <<EOF > ./claude-start.sh
#!/bin/bash
distrobox enter $CONTAINER_NAME -- bash -l -c "cd $WORKSPACE_DIR && claude"
EOF
chmod +x ./claude-start.sh

echo "📝 Created a local launcher: ./claude-start.sh"
