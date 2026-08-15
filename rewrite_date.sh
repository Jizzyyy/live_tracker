#!/bin/bash
git log --format="%H" -n 26 | tac | while read commit_hash; do
    git checkout $commit_hash
    # Get current date from commit
    AUTH_DATE=$(git log -1 --format="%ad" --date=iso-strict)
    # Replace 2025 with 2026
    NEW_DATE=${AUTH_DATE/2025/2026}
    
    GIT_COMMITTER_DATE=$NEW_DATE GIT_AUTHOR_DATE=$NEW_DATE git commit --amend --no-edit
done

# Pindahkan branch main ke commit terakhir
git checkout -B main
git push -f origin main
