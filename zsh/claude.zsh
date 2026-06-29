# Claude Code session helpers

# Claude session dispatcher:
#   cc            -> start a new session
#   cc ls         -> list all sessions with IDs and titles
#   cc <name>     -> start a new session with that name
cc() {
  case "$1" in
    "")  claude ;;
    ls)  ccls ;;
    *)   claude --name "$1" ;;
  esac
}

# Resume a session by name/search term (or open the picker):  ccr  |  ccr dotfiles
ccr() {
  if [ -n "$1" ]; then claude --resume "$1"; else claude --resume; fi
}

# Rename an existing session:  ccname <session-id> <new-name>
ccname() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: ccname <session-id> <new-name>" >&2
    echo "       (run ccls to see session IDs)" >&2
    return 1
  fi
  claude --resume "$1" --name "$2"
}

# List all Claude sessions with their IDs and titles:  ccls
ccls() {
  local dir f id title proj
  for dir in "$HOME"/.claude/projects/*/; do
    for f in "$dir"*.jsonl; do
      [ -e "$f" ] || continue
      id=$(basename "$f" .jsonl)
      title=$(grep '"type":"ai-title"' "$f" 2>/dev/null | tail -1 \
        | python3 -c "import sys,json
try: print(json.loads(sys.stdin.readline()).get('aiTitle',''))
except: pass" 2>/dev/null)
      [ -z "$title" ] && title="(no title yet)"
      proj=$(basename "$dir")
      printf "%s  %-45s  %s\n" "$id" "$title" "$proj"
    done
  done
}
