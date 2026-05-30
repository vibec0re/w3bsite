#!/usr/bin/env bash
# Build the Hugo site and publish public/ into the github-pages repo.
#
# Usage: ./deploy.sh [--push] [--minify] [target-repo-path]
#
# Defaults: no push, no minify, target = ../vibec0re.github.io.
set -euo pipefail

push=0
minify=0
target="$(cd "$(dirname "$0")" && pwd)/../vibec0re.github.io"

for arg in "$@"; do
  case "$arg" in
    --push)   push=1 ;;
    --minify) minify=1 ;;
    -h|--help)
      sed -n '2,7p' "$0"; exit 0 ;;
    *) target="$arg" ;;
  esac
done

src="$(cd "$(dirname "$0")" && pwd)"
cd "$src"

if [[ ! -d "$target/.git" ]]; then
  echo "target '$target' is not a git repo" >&2
  exit 1
fi

echo "==> building hugo site"
rm -rf public
if (( minify )); then
  nix develop --command hugo --minify
else
  nix develop --command hugo
fi

echo "==> syncing into $target"
# Wipe everything except .git and .github (workflow lives in the pages repo).
find "$target" -mindepth 1 -maxdepth 1 \
  ! -name .git ! -name .github -exec rm -rf {} +
cp -r public/. "$target"/

cd "$target"
git add -A
if git diff --cached --quiet; then
  echo "==> no changes to publish"
  exit 0
fi

git commit -m "publish fresh build"
echo "==> committed in $target"

if (( push )); then
  git push
  echo "==> pushed"
else
  echo "==> skipping push (pass --push to push)"
fi
