# Claude Code session manager: name -> uuid aliases on top of `claude`.
#
#   cc ls                  list saved name -> uuid aliases
#   cc <name>              resume the aliased conversation
#   cc new <name>          start a brand-new session with a fixed uuid, launch it
#   cc add <name> <uuid>   map a name to an existing on-disk session
#   cc rename <old> <new>  rename an alias (keeps the uuid); alias: cc mv
#   cc rm <name>           drop the alias only (conversation is untouched)
#   cc scan                list recent on-disk sessions with a first-message hint
#   cc help                show this help
#
# Alias store: one "name<TAB>uuid<TAB>dir" line per alias.
: ${CC_STORE:=$HOME/.config/cc/sessions.tsv}

_cc_init() { mkdir -p "${CC_STORE:h}"; [ -f "$CC_STORE" ] || : > "$CC_STORE"; }

# Look up a field by alias name. $1=name -> prints "uuid<TAB>dir"
_cc_lookup() { awk -F'\t' -v n="$1" '$1==n {print $2"\t"$3; found=1} END{exit !found}' "$CC_STORE"; }

# Find the on-disk .jsonl for a uuid; prints its path (or nothing).
_cc_find_file() {
  local d
  for d in "$HOME"/.claude/projects/*/; do
    [ -f "$d$1.jsonl" ] && { print -r -- "$d$1.jsonl"; return 0; }
  done
  return 1
}

# Reconstruct a project dir from a session file path (…/projects/-home-dorfu/x.jsonl -> /home/dorfu)
_cc_dir_from_file() { local p="${1:h:t}"; print -r -- "${p//-//}"; }

# ai-title (or "") for a session file. $1=file
_cc_title() { grep '"type":"ai-title"' "$1" 2>/dev/null | tail -1 | python3 -c "import sys,json
try: print(json.loads(sys.stdin.readline()).get('aiTitle',''))
except: pass" 2>/dev/null; }

cc() {
  _cc_init
  local cmd="$1"; shift 2>/dev/null
  case "$cmd" in
    ""|help|-h|--help)
      sed -n '3,12p' "${(%):-%x}" | sed 's/^# \{0,1\}//'
      ;;

    ls)
      if [ ! -s "$CC_STORE" ]; then echo "no aliases yet — use 'cc new <name>' or 'cc add <name> <uuid>'"; return; fi
      local name uuid dir file title
      while IFS=$'\t' read -r name uuid dir; do
        file=$(_cc_find_file "$uuid"); title=""
        [ -n "$file" ] && title=$(_cc_title "$file")
        [ -z "$title" ] && title="(no title)"
        printf "%-18s %s  %s\n" "$name" "$uuid" "$title"
      done < "$CC_STORE"
      ;;

    new)
      local name="$1"
      [ -z "$name" ] && { echo "usage: cc new <name>" >&2; return 1; }
      _cc_lookup "$name" >/dev/null && { echo "alias '$name' already exists (cc rm '$name' first)" >&2; return 1; }
      local uuid; uuid=$(python3 -c "import uuid;print(uuid.uuid4())")
      printf "%s\t%s\t%s\n" "$name" "$uuid" "$PWD" >> "$CC_STORE"
      echo "new session '$name' -> $uuid"
      claude --session-id "$uuid" --name "$name"
      ;;

    add)
      local name="$1" uuid="$2"
      [ -z "$name" ] || [ -z "$uuid" ] && { echo "usage: cc add <name> <uuid>" >&2; return 1; }
      _cc_lookup "$name" >/dev/null && { echo "alias '$name' already exists" >&2; return 1; }
      local file dir
      file=$(_cc_find_file "$uuid")
      if [ -n "$file" ]; then dir=$(_cc_dir_from_file "$file"); else
        echo "warning: no on-disk session found for $uuid (mapping anyway, resume from its project dir)" >&2
        dir="$PWD"
      fi
      printf "%s\t%s\t%s\n" "$name" "$uuid" "$dir" >> "$CC_STORE"
      echo "mapped '$name' -> $uuid"
      ;;

    rename|mv)
      local old="$1" new="$2"
      [ -z "$old" ] || [ -z "$new" ] && { echo "usage: cc rename <old> <new>" >&2; return 1; }
      _cc_lookup "$old" >/dev/null || { echo "no alias '$old'" >&2; return 1; }
      _cc_lookup "$new" >/dev/null && { echo "alias '$new' already exists" >&2; return 1; }
      local tmp; tmp=$(mktemp)
      awk -F'\t' -v o="$old" -v n="$new" 'BEGIN{OFS="\t"} $1==o{$1=n} {print}' "$CC_STORE" > "$tmp" && mv "$tmp" "$CC_STORE"
      echo "renamed '$old' -> '$new'"
      ;;

    rm)
      local name="$1"
      [ -z "$name" ] && { echo "usage: cc rm <name>" >&2; return 1; }
      _cc_lookup "$name" >/dev/null || { echo "no alias '$name'" >&2; return 1; }
      local tmp; tmp=$(mktemp)
      awk -F'\t' -v n="$name" '$1!=n' "$CC_STORE" > "$tmp" && mv "$tmp" "$CC_STORE"
      echo "dropped alias '$name' (conversation untouched)"
      ;;

    scan)
      local f uuid dir hint
      for f in $(ls -t "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | head -25); do
        uuid="${f:t:r}"; dir=$(_cc_dir_from_file "$f")
        hint=$(python3 - "$f" <<'PY'
import json,sys
for line in open(sys.argv[1]):
    try: d=json.loads(line)
    except: continue
    if d.get('type')=='user':
        c=d.get('message',{}).get('content')
        if isinstance(c,list):
            c=' '.join(p.get('text','') for p in c if isinstance(p,dict))
        if isinstance(c,str) and c.strip():
            print(c.strip().replace('\n',' ')[:70]); break
PY
)
        printf "%s  %-22s %s\n" "$uuid" "$dir" "$hint"
      done
      ;;

    *)
      # treat as an alias name -> resume
      local res uuid dir
      res=$(_cc_lookup "$cmd") || { echo "no alias '$cmd' (try 'cc ls', 'cc scan', or 'cc new $cmd')" >&2; return 1; }
      uuid="${res%%$'\t'*}"; dir="${res#*$'\t'}"
      if [ -n "$dir" ] && [ -d "$dir" ]; then
        ( cd "$dir" && claude --resume "$uuid" )
      else
        claude --resume "$uuid"
      fi
      ;;
  esac
}
