#!/bin/bash
# Install /overnight skill for Claude Code
set -e

DEST="$HOME/.claude/skills/overnight"

if [ -d "$DEST" ]; then
  echo "Updating existing installation..."
  rm -rf "$DEST"
fi

git clone --quiet https://github.com/Twenseventeen/overnight-skill.git "$DEST"
rm -rf "$DEST/.git" "$DEST/.gitignore" "$DEST/LICENSE" "$DEST/README.md" "$DEST/SECURITY.md" "$DEST/install.sh"

echo "Installed to $DEST"
ls "$DEST"
