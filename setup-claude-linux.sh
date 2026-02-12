#!/bin/bash
set -e

# --- Configuration ---
CONTAINER_NAME="claude-workspace"
IMAGE="alpine:latest"
CPU_LIMIT="8"
MEM_LIMIT="8G"

WORKSPACE_DIR="$(pwd)"
SANDBOX_HOME="$WORKSPACE_DIR/.claude_sandbox"

echo "🛠 Preparing workspace..."
mkdir -p "$SANDBOX_HOME"

# --- Update .gitignore safely ---
if [ -f .gitignore ]; then
    grep -qxF ".claude_sandbox/" .gitignore || echo ".claude_sandbox/" >> .gitignore
    grep -qxF "claude-start.sh" .gitignore || echo "claude-start.sh" >> .gitignore
    grep -qxF "node_modules/" .gitignore || echo "node_modules/" >> .gitignore
else
    cat <<EOF > .gitignore
.claude_sandbox/
claude-start.sh
node_modules/
EOF
fi

echo "🐳 Creating container (if not exists)..."

# Only create if it doesn't already exist
if ! distrobox list | grep -q "$CONTAINER_NAME"; then
    distrobox create -n "$CONTAINER_NAME" -i "$IMAGE" --yes \
        --home "$SANDBOX_HOME" \
        --additional-flags "--cpus=$CPU_LIMIT --memory=$MEM_LIMIT --volume $WORKSPACE_DIR:$WORKSPACE_DIR:rw"
else
    echo "Container already exists. Skipping creation."
fi

echo "📦 Installing dependencies inside container..."

distrobox enter "$CONTAINER_NAME" -- sh -c "
    sudo apk update

    # 1. Install System Basics
    sudo apk add --no-cache \
        nodejs npm git bash curl \
        libgcc libstdc++ gcompat \
        ripgrep make g++ \
        python3 py3-pip python3-dev \
        musl-dev freetype-dev libpng-dev

    # 2. Upgrade pip (standard practice)
    python3 -m pip install --upgrade pip setuptools wheel

    # 3. CRITICAL: Install Matplotlib & Numpy via APK (Pre-compiled)
    # Installing these via pip on Alpine is slow and prone to failure.
    sudo apk add --no-cache py3-matplotlib py3-numpy

    # 4. Install Claude Code (if not installed)
    if ! command -v claude >/dev/null 2>&1; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi
"

echo "🚀 Creating launcher..."

cat <<EOF > ./claude-start.sh
#!/bin/bash
set -e
WORKSPACE_DIR="\$(pwd)"
exec distrobox enter $CONTAINER_NAME -- bash -c "cd \"\$WORKSPACE_DIR\" && exec claude"
EOF

chmod +x ./claude-start.sh

echo "--------------------------------"
echo "✅ Setup Complete"
echo "🧠 Uses 8 CPU cores"
echo "📊 matplotlib + numpy installed (via apk)"
echo ""
echo "Start Claude with:"
echo "./claude-start.sh"
echo "--------------------------------"
