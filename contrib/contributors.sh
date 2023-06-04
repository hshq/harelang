#!/bin/sh -eu

authors=
commits=

while true; do
  files=${1:-.}
  if [ -d "$files" ]; then
    files=$(find "${1:-.}" -name '*.ha' -o -name '*.s' -o -name README)
  fi

  for file in $files; do
    authorinfo=$(git blame "$file" --porcelain --incremental)

    # Format as: Author Name <test@example.com>
    while read -r line; do
      if printf '%s' "$line" | grep -qE '^[0-9a-f]{40} \d+ \d+ \d+$'; then
        commits=$(printf '%s\n%s' "$commits" \
          "$(printf '%s' "$line" | cut -d' ' -f1)")
        continue
      fi
      case "$line" in
        "author "*) author=$(printf '%s' "$line" | sed 's/author //') ;;
        "author-mail "*) mail=$(printf '%s' "$line" | sed 's/author-mail //') ;;
        "filename "*) authors=$(printf '%s\n%s' "$authors" "$author $mail") ;;
        *) ;;
      esac
    done << EOF
    $authorinfo
EOF
  done

  if [ $# -eq 1 ]; then
    break
  fi
  shift 1
done

# Get co-authors of commits
for commit in $(printf '%s' "$commits" | sort -u); do
  coauthors=$(git show "$commit" | grep '^    Co-authored-by:' \
    | sed 's/    Co-authored-by: *//g')
  authors=$(printf '%s\n%s' "$authors" "$coauthors")
done

# Get only the unique author names
printf '%s\n' "$authors" | tail -n+2 | sort -u
