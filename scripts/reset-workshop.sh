#!/usr/bin/env bash
# Facilitator tool: reset the workshop repo between sessions.
#
# Removes every attendee profile (keeps _template.md) and restores team-tips.md,
# on a new branch, then opens a pull request. Review and merge it yourself
# (repo admins can bypass the peer-comment bot).
#
# This does NOT touch the Module 4 lab. The tag 'conflict-lab-start' and the branch
# 'conflict-lab-teammate' stay as they are, so you do not need to re-run
# seed-conflict-lab.sh after a reset.
#
# Run from the root of a clone of the ORG repo (not a fork). Needs: git, gh (logged in).
set -euo pipefail

branch="reset/$(date +%Y-%m-%d-%H%M)"

git switch main
git pull --ff-only
git switch -c "$branch"

# Remove all attendee profiles except the template
find attendees -type f -name '*.md' ! -name '_template.md' -print -delete

# Restore team-tips.md to its baseline (the Module 4 lab depends on the TODO line)
cat > team-tips.md <<'EOF'
# Team Tips

Share one tip for working with Git or with AI coding tools.

This file is used in the merge conflict lab. Everyone edits the same line on purpose.

## Tips

- TODO: replace this line with your tip
EOF

git add -A attendees team-tips.md
if git diff --cached --quiet; then
  echo "Nothing to reset. Repo is already clean."
  git switch main
  git branch -D "$branch"
  exit 0
fi

git commit -m "Reset workshop repo for next session"
git push -u origin "$branch"
gh pr create --fill --base main --head "$branch"

echo
echo "Next: merge the reset PR. Module 4 needs nothing more (leave the conflict-lab-start tag and the conflict-lab-teammate branch alone)."
echo "Reminder: ask previous attendees to delete their forks, or leave them. Forks are independent copies."
