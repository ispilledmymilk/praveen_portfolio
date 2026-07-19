#!/usr/bin/env bash
# One-shot: create public repo, push site, enable GitHub Pages.
# Usage:
#   export GH_TOKEN='ghp_...'
#   ./deploy-pages.sh
set -euo pipefail

cd "$(dirname "$0")"

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "Set GH_TOKEN first, e.g.:"
  echo "  export GH_TOKEN='ghp_your_token_here'"
  exit 1
fi

REPO_NAME="${REPO_NAME:-praveen-kasturi-resume}"

echo "Authenticating..."
printf '%s' "$GH_TOKEN" | gh auth login --with-token
OWNER="$(gh api user --jq .login)"
echo "Logged in as: $OWNER"

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Creating public repo $OWNER/$REPO_NAME ..."
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
else
  echo "Remote exists; pushing main..."
  git push -u origin main
fi

echo "Enabling GitHub Pages from main / ..."
# Ignore error if Pages is already enabled
gh api --method POST "repos/$OWNER/$REPO_NAME/pages" \
  -H "Accept: application/vnd.github+json" \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/ \
  >/dev/null 2>&1 || true

# Confirm / update source
gh api --method PUT "repos/$OWNER/$REPO_NAME/pages" \
  -H "Accept: application/vnd.github+json" \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/ \
  >/dev/null 2>&1 || true

sleep 2
PAGES_URL="$(gh api "repos/$OWNER/$REPO_NAME/pages" --jq .html_url 2>/dev/null || true)"
if [[ -z "$PAGES_URL" ]]; then
  PAGES_URL="https://${OWNER}.github.io/${REPO_NAME}/"
fi

echo ""
echo "Done."
echo "Repo:  https://github.com/$OWNER/$REPO_NAME"
echo "Site:  $PAGES_URL"
echo ""
echo "Revoke the PAT when finished:"
echo "  https://github.com/settings/tokens"
