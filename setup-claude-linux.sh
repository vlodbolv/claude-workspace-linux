#!/bin/bash

# --- Configuration ---
CONTAINER_NAME="claude-workspace"
IMAGE="alpine:latest"
CPU_LIMIT="8"          # Updated to 8 CPU cores
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
distrobox create -n "$CONTAINER_NAME" -i "$IMAGE" --yes \
    --home "$SANDBOX_HOME" \
    --additional-flags "--cpus=$CPU_LIMIT --memory=$MEM_LIMIT --volume $WORKSPACE_DIR:$WORKSPACE_DIR:rw -e USE_BUILTIN_RIPGREP=0"

echo "📦 Installing Claude Code, Python, and matplotlib..."

# 3. Setup Inside Alpine
distrobox enter "$CONTAINER_NAME" -- sh -c "
    sudo apk update
    sudo apk add --no-cache \
        nodejs npm git bash curl \
        libgcc libstdc++ gcompat \
        ripgrep make g++ \
        python3 py3-pip python3-dev \
        musl-dev freetype-dev libpng-dev

    # Upgrade pip
    python3 -m pip install --upgrade pip setuptools wheel

    # Install matplotlib
    python3 -m pip install matplotlib

    # Install Claude Code
    curl -fsSL https://claude.ai/install.sh | bash

    # Fix PATH inside the sandbox
    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \$HOME/.profile
    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \$HOME/.bashrc
"

# 4. Create Launcher
cat <<EOF > ./claude-start.sh
#!/bin/bash
distrobox enter $CONTAINER_NAME -- bash -l -c "cd $WORKSPACE_DIR && claude"
EOF

chmod +x ./claude-start.sh

echo "---"
echo "✅ Setup Complete!"
echo "🚀 To start Claude, run:"
echo "./claude-start.sh"
