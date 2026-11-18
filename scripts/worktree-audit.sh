#!/usr/bin/env bash
# Read-only worktree prune audit. Classifies every git worktree by size, merge
# state, uncommitted work, remote/PR state, and recent chat activity. Emits a
# table sorted by size with a suggested bucket. Never deletes anything.
#
# Usage: worktree-audit.sh [-b|--base <ref>] [-f|--fetch] [repo-path]
#   repo-path defaults to the current repo.
#   -b sets the ref the MERGED column checks against (e.g. origin/integration).
#      Without it the base is origin/HEAD, then origin/main, then main, then master.
#   -f fetches the remote base branch before checking merge state (disabled by default
#      to keep the audit strictly offline and read-only).
set -u

base=""
do_fetch=false
while [ $# -gt 0 ]; do
  case "$1" in
    -b|--base) [ $# -ge 2 ] || { echo "error: $1 needs a ref" >&2; exit 2; }; base="$2"; shift 2 ;;
    -f|--fetch) do_fetch=true; shift ;;
    -h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    -*) echo "error: unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "not in a git repo; pass a repo path" >&2; exit 1; }
cd "$repo" || exit 1
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: not a git repo: $repo" >&2; exit 1; }

main_wt=$(git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /,""); print; exit}')

if [ -z "$base" ]; then
  for cand in "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" origin/main origin/master main master; do
    [ -n "$cand" ] && git rev-parse --verify --quiet "$cand^{commit}" >/dev/null && { base="$cand"; break; }
  done
  [ -z "$base" ] && { echo "error: no base ref found; pass -b <ref>" >&2; exit 1; }
fi

if [ "$do_fetch" = true ]; then
  case "$base" in
    origin/*) git fetch origin "+refs/heads/${base#origin/}:refs/remotes/$base" --quiet 2>/dev/null \
      || echo "warn: could not fetch $base; merged column may be stale" >&2 ;;
  esac
fi
git rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 || { echo "error: base ref not found: $base" >&2; exit 1; }

if stat -c %Y / >/dev/null 2>&1; then
  stat_fmt=(-c '%Y %n'); fmt_day() { date -d "@$1" '+%Y-%m-%d'; }
else
  stat_fmt=(-f '%m %N'); fmt_day() { date -r "$1" '+%Y-%m-%d'; }
fi

prs=$(mktemp)
trap 'rm -f "$prs"' EXIT

if command -v gh >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 \
  && raw=$(gh pr list --author "@me" --state all --limit 1000 --json number,state,headRefName 2>/dev/null); then
  printf '%s' "$raw" | jq '[.[] | {number, state: (.state | ascii_downcase), head: .headRefName}]' > "$prs" 2>/dev/null
fi
[ -s "$prs" ] || echo "[]" > "$prs"

claude_slug() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#-#g'; }
transcript_dirs() {
  for d in "$HOME/.claude/projects/$(claude_slug "$1")"; do
    [ -d "$d" ] && printf '%s\n' "$d"
  done
}
now=$(date +%s)

echo "# base: $base"
printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tLAST_CHAT\tBUCKET\tWORKTREE\n"

git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /,""); print}' | while IFS= read -r wt; do
  [ "$wt" = "$main_wt" ] && continue

  size=$(du -sh "$wt" 2>/dev/null | awk '{print $1}')
  head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
  head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
  age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

  git merge-base --is-ancestor "$head" "$base" 2>/dev/null && merged=YES || merged=no

  porcelain=$(git -C "$wt" status --porcelain 2>/dev/null)
  if [ -z "$porcelain" ]; then dirty=clean
  elif printf '%s\n' "$porcelain" | grep -qv '^??'; then
    dirty="wip:$(printf '%s\n' "$porcelain" | grep -cv '^??')"
  else dirty="scratch:$(printf '%s\n' "$porcelain" | grep -c '^??')"; fi

  branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
  if [ -z "$branch" ]; then remote=detached
  elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    [ "$(git -C "$wt" rev-parse "origin/$branch" 2>/dev/null)" = "$head" ] \
      && remote=pushed \
      || remote="ahead$(git -C "$wt" rev-list --count "origin/$branch..HEAD" 2>/dev/null)"
  else remote=no-remote; fi

  pr=""
  if [ -n "$branch" ] && command -v jq >/dev/null 2>&1; then
    pr=$(jq -r --arg b "$branch" '.[] | select(.head==$b) | "#\(.number)/\(.state)"' "$prs" 2>/dev/null | head -1)
  fi
  [ -z "$pr" ] && pr="-"

  last="-"; last_ts=0
  dirs=$( { transcript_dirs "$main_wt"; transcript_dirs "$wt"; } | sort -u)
  if [ -n "$dirs" ]; then
    if command -v rg >/dev/null 2>&1; then
      matched_files=$(printf '%s\n' "$dirs" | tr '\n' '\0' | xargs -0 rg -l -e "${wt}/" -e "${wt}\"" 2>/dev/null || true)
    else
      matched_files=$(printf '%s\n' "$dirs" | tr '\n' '\0' | xargs -0 grep -rlF "${wt}" 2>/dev/null || true)
    fi
    if [ -n "$matched_files" ]; then
      f=$(printf '%s\n' "$matched_files" | tr '\n' '\0' | xargs -0 stat "${stat_fmt[@]}" 2>/dev/null | sort -rn | head -1)
      if [ -n "$f" ]; then
        last_ts=$(echo "$f" | awk '{print $1}')
        last=$(fmt_day "$last_ts" 2>/dev/null)
      fi
    fi
  fi
  recent=$([ "$last_ts" -gt 0 ] 2>/dev/null && [ $(( (now - last_ts) / 86400 )) -le 4 ] && echo yes || echo no)

  case "$dirty" in wip:*) bucket=hold-wip ;; *)
    case "$pr" in */open|*/draft) bucket=hold-open-pr ;; *)
      if [ "$recent" = yes ]; then bucket=verify-recent-chat
      elif [ "$merged" = YES ] || [ "$pr" != "-" ]; then bucket=safe
      else bucket=review; fi ;;
    esac ;;
  esac

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$last" "$bucket" "$wt"
done | sort -t$'\t' -k1,1 -rh
