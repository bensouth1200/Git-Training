#!/usr/bin/env bash
# Facilitator tool: set up the Module 4 conflict lab. Run it ONCE.
#
# It creates two things in the ORG repo. Neither is ever merged into main:
#   tag    conflict-lab-start      the commit attendees start their lab branch from
#   branch conflict-lab-teammate   that same commit plus one commit that replaces the
#                                  TODO tip line in team-tips.md (the "teammate's change")
#
# In Module 4 each attendee works entirely in their own fork: they branch from the tag,
# edit the TODO line, then merge upstream/conflict-lab-teammate to get a conflict on that
# same line. Nothing in the lab changes main, so the lab works for any cohort and for
# self-paced learners, with no reviewer and no resets.
#
# Safe to re-run: if the tag and the branch both exist it does nothing.
# Use --force only if you deliberately want to rebuild the lab (it moves the tag and
# rewrites the branch).
#
# The "teammate" commit is authored by whoever runs this script, and the repo is public.
# Set git user.name / user.email first (use your GitHub noreply email).
#
# Run from the root of a clone of the ORG repo (not a fork). Needs: git, push access to origin.
set -euo pipefail

TAG="conflict-lab-start"
BRANCH="conflict-lab-teammate"
BASELINE_LINE='- TODO: replace this line with your tip'

force=0
if [ "${1:-}" = "--force" ]; then
  force=1
elif [ -n "${1:-}" ]; then
  echo "usage: scripts/seed-conflict-lab.sh [--force]"
  exit 2
fi

git switch main
git pull --ff-only

tag_exists=0;    git ls-remote --exit-code --tags  origin "refs/tags/$TAG"     >/dev/null 2>&1 && tag_exists=1
branch_exists=0; git ls-remote --exit-code --heads origin "refs/heads/$BRANCH" >/dev/null 2>&1 && branch_exists=1

if [ "$force" -eq 0 ]; then
  if [ "$tag_exists" -eq 1 ] && [ "$branch_exists" -eq 1 ]; then
    echo "The conflict lab is already set up: tag '$TAG' and branch '$BRANCH' both exist on origin."
    echo "Nothing to do. (Use --force only if you want to rebuild it.)"
    exit 0
  fi
  if [ "$tag_exists" -eq 1 ] || [ "$branch_exists" -eq 1 ]; then
    echo "Only one of the tag '$TAG' and the branch '$BRANCH' exists on origin, so the lab is half set up."
    echo "Run scripts/seed-conflict-lab.sh --force to rebuild both."
    exit 1
  fi
fi

# The tag must point at a commit where team-tips.md still has the TODO line, because
# the attendee steps and the teammate commit both depend on it.
if ! grep -qxF -- "$BASELINE_LINE" team-tips.md; then
  echo "team-tips.md on main does not contain the baseline line:"
  echo "  $BASELINE_LINE"
  echo "Restore team-tips.md to its baseline (scripts/reset-workshop.sh does this) and merge that first."
  exit 1
fi

# 1. Tag the baseline commit.
git tag -f "$TAG"
git push -f origin "$TAG"

# 2. Branch from that same commit with the teammate's change. It is pushed, never merged.
git switch -C "$BRANCH" "$TAG"
sed 's/^- TODO: replace this line with your tip.*/- Facilitator tip: pull from upstream before you start any new piece of work./' \
  team-tips.md > team-tips.md.tmp
mv team-tips.md.tmp team-tips.md
git add team-tips.md
git commit -m "Add facilitator tip for conflict lab"
git push -f origin "$BRANCH"

# Leave your clone tidy.
git switch main
git branch -D "$BRANCH"

echo
echo "Done. On origin you now have:"
echo "  tag    $TAG"
echo "  branch $BRANCH"
echo
echo "Do NOT merge or delete the branch, and do not move or delete the tag."
echo "Module 4 depends on both, for every cohort and for self-paced learners."
