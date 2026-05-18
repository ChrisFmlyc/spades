#!/usr/bin/env bash
# SPADE plugin release helper.
#
# Keeps the plugin's top-level skills/, agents/, and scripts/ in sync with the
# canonical content under .claude/skills/, .claude/agents/, and bin/. Bumps the
# version in .claude-plugin/plugin.json and .claude-plugin/marketplace.json,
# then tags and pushes.
#
# Usage:
#   scripts/release-plugin.sh <new-version>
#   scripts/release-plugin.sh 1.2.0
#
# After the script runs, your working tree is committed and tagged but NOT
# pushed. Push manually:
#   git push origin <branch> --follow-tags

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <new-version>"
  echo "Example: $0 1.2.0"
  exit 1
fi

NEW_VERSION="$1"
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: version must be MAJOR.MINOR.PATCH (e.g., 1.2.0), got '$NEW_VERSION'"
  exit 1
fi
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Sanity: must be on a clean tree
if ! git diff-index --quiet HEAD --; then
  echo "ERROR: working tree has uncommitted changes. Commit or stash first."
  exit 1
fi

echo "==> Mirroring .claude/skills/   -> skills/"
rsync -a --delete .claude/skills/ skills/

echo "==> Mirroring .claude/agents/   -> agents/"
mkdir -p agents
rsync -a --delete --include='spade-*' --exclude='*' .claude/agents/ agents/

echo "==> Mirroring bin/spade-*       -> scripts/"
for f in bin/spade-render bin/spade-update-check bin/spade-marker-replace; do
  if [[ -f "$f" ]]; then
    cp "$f" "scripts/$(basename "$f")"
    chmod +x "scripts/$(basename "$f")"
  fi
done

echo "==> Bumping plugin.json + marketplace.json to $NEW_VERSION"
python3 - <<PY
import json, pathlib

plugin_path = pathlib.Path(".claude-plugin/plugin.json")
market_path = pathlib.Path(".claude-plugin/marketplace.json")

plugin = json.loads(plugin_path.read_text())
plugin["version"] = "$NEW_VERSION"
plugin_path.write_text(json.dumps(plugin, indent=2) + "\n")

market = json.loads(market_path.read_text())
market.setdefault("metadata", {})["version"] = "$NEW_VERSION"
matched = False
for p in market.get("plugins", []):
    if p.get("name") == plugin["name"]:
        p["version"] = "$NEW_VERSION"
        matched = True
if not matched:
    raise SystemExit(f"ERROR: plugin '{plugin['name']}' not found in marketplace.json plugins[]")
market_path.write_text(json.dumps(market, indent=2) + "\n")
PY

echo "==> Committing"
git add .claude-plugin skills agents scripts
git commit -m "spade plugin v$NEW_VERSION"

echo "==> Tagging v$NEW_VERSION"
git tag "v$NEW_VERSION"

echo
echo "Done. To publish:"
echo "  git push origin \"$(git branch --show-current)\" --follow-tags"
