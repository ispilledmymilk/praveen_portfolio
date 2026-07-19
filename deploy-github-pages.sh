#!/usr/bin/env bash
# Run this in Terminal: bash deploy-github-pages.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Checking GitHub auth..."
if ! gh api user --jq .login >/dev/null 2>&1; then
  echo "==> Logging in to GitHub (browser will open)..."
  gh auth login -h github.com -p https -w -s 'repo,workflow'
fi

USER=$(gh api user --jq .login)
echo "Authenticated as: ${USER}"
REPO="praveen-kasturi-resume"
URL="https://${USER}.github.io/${REPO}/"

echo "==> Creating public repo ${USER}/${REPO} (if needed)..."
if ! gh repo view "${USER}/${REPO}" >/dev/null 2>&1; then
  gh repo create "${REPO}" --public --source=. --remote=origin --description "Resume website for Praveen Kasturi"
else
  echo "Repo already exists."
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/${USER}/${REPO}.git"
  fi
fi

echo "==> Pushing main..."
git push -u origin HEAD

echo "==> Enabling GitHub Pages (main branch, root)..."
# Prefer configuring Pages via API; ignore if already enabled
gh api "repos/${USER}/${REPO}/pages" \
  --method POST \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/ 2>/dev/null \
  || gh api "repos/${USER}/${REPO}/pages" \
  --method PUT \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/ 2>/dev/null \
  || true

echo ""
echo "Done. Site should be available shortly at:"
echo "  ${URL}"
echo ""
echo "If the page 404s for a minute, wait and refresh — Pages can take 1–2 minutes."
