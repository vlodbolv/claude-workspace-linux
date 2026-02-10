#!/bin/bash

# --- Configuration ---
CONTAINER_NAME="claude-workspace"
IMAGE="alpine:latest"
CPU_LIMIT="4" 
MEM_LIMIT="8G"

# 1. Prepare Workspace & Gitignore
WORKSPACE_DIR=$(pwd)
SANDBOX_HOME="$WORKSPACE_DIR/.claude_sandbox"
mkdir -p "$SANDBOX_HOME"

echo "📝 Updating .gitignore..."
cat <<EOF >> .gitignore
# Claude Sandbox & Launcher
.claude_sandbox/
claude-start.sh
node_modules/
EOF
# Clean up duplicates
sort -u .gitignore -o .gitignore

echo "🛡️  Initializing restricted Distrobox in: $WORKSPACE_DIR"

# 2. Create the container
# USE_BUILTIN_RIPGREP=0 is critical for Alpine compatibility
distrobox create -n "$CONTAINER_NAME" -i "$IMAGE" --yes \
    --home "$SANDBOX_HOME" \
    --additional-flags "--cpus=$CPU_LIMIT --memory=$MEM_LIMIT --volume $WORKSPACE_DIR:$WORKSPACE_DIR:rw -e USE_BUILTIN_RIPGREP=0"

echo "📦 Installing Claude Code and Alpine-specific dependencies..."

# 3. Setup Inside Alpine
distrobox enter "$CONTAINER_NAME" -- sh -c "
    sudo apk update
    sudo apk add --no-cache \
        nodejs npm git bash curl \
        libgcc libstdc++ gcompat \
        ripgrep make g++ python3

    # Install Claude Code
    curl -fsSL https://claude.ai/install.sh | bash

    # Fix PATH inside the sandbox
    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \$HOME/.profile
    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \$HOME/.bashrc
"

# 4. Create Launcher
cat <<EOF > ./claude-start.sh
#!/bin/bash
# Check if container exists, if not, warn user
distrobox enter $CONTAINER_NAME -- bash -l -c "cd $WORKSPACE_DIR && claude"
EOF
chmod +x ./claude-start.sh

echo "---"
echo "✅ Setup Complete!"
echo "🚀 To start Claude, simply run: ./claude-start.sh"
