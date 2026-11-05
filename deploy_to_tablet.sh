#!/usr/bin/env bash
set -e

TABLET_HOST="user@172.16.42.1"
REMOTE_DIR="~/huskie-board"

echo "🚀 [1/4] Syncing sources to tablet..."
rsync -avz --exclude="build" --exclude=".git" ./ "${TABLET_HOST}:${REMOTE_DIR}/"

echo "⚙️ [2/4] Registering KDE Plasma 6 Virtual Keyboard service..."
ssh "${TABLET_HOST}" "mkdir -p ~/.local/share/applications && cp ${REMOTE_DIR}/huskie-board.desktop ~/.local/share/applications/ && kbuildsycoca6 2>/dev/null || true"

echo "🛠️ [3/4] Compiling huskie-board on tablet..."
ssh "${TABLET_HOST}" "cd ${REMOTE_DIR} && find . -type f -exec touch {} + && cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j\$(nproc)"

echo "🛑 [4/4] Terminating previous instance and launching detached..."
ssh "${TABLET_HOST}" "pkill -x huskie-board || true"
ssh "${TABLET_HOST}" "export XDG_RUNTIME_DIR=/run/user/\$(id -u); export WAYLAND_DISPLAY=wayland-0; export QT_QPA_PLATFORM=wayland; setsid nohup ${REMOTE_DIR}/build/huskie-board >/tmp/huskie-board.log 2>&1 &"

echo "✅ Deploy complete! Keyboard is now running and registered in KDE Plasma System Settings."
