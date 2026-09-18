#!/bin/sh

set -eu

branch_file="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GitBranch.txt"

case " ${SWIFT_ACTIVE_COMPILATION_CONDITIONS:-} " in
    *" DEBUG "*) ;;
    *)
        rm -f "$branch_file"
        exit 0
        ;;
esac

# Run on every build so branch changes are captured even without source changes.
# Ask Git directly so linked worktrees are supported as well as regular clones.
git_branch=$(git -C "$SRCROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true)

if [ -z "$git_branch" ]; then
    git_commit=$(git -C "$SRCROOT" rev-parse --short HEAD 2>/dev/null || true)
    if [ -n "$git_commit" ]; then
        git_branch="Detached HEAD ($git_commit)"
    fi
fi

mkdir -p "$(dirname "$branch_file")"
printf '%s\n' "$git_branch" > "$branch_file"
