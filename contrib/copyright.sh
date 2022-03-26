#!/bin/sh -eu

files=$(find . -name '*.ha')

for file in $files; do
  printf '%s\n' "$file"

  authorinfo=$(git blame $file --porcelain --incremental)

  # Format as: Author Name <test@example.com>;2011
  year_authorinfo=""
  ignore_this_commit=false
  while read -r line; do
    if [ "$ignore_this_commit" = true ]; then
      case $line in
        "filename "*) ignore_this_commit=false ;;
        *) ;;
      esac
    else
      case $line in
        # Add commits that updated the copyright info here in order to ignore them
        "b791275bfb0fe5d7928c19635e75fd3d98e3ba97"*) ignore_this_commit=true ;;
        # This is the “not committed yet” commit
        "0000000000000000000000000000000000000000"*) ignore_this_commit=true ;;
        "author "*) author=$(printf '%s' "$line" | sed 's/author //' ) ;;
        "author-mail "*) mail=$(printf '%s' "$line" | sed 's/author-mail //' ) ;;
        "author-time "*) timestamp=$(printf '%s' "$line" | sed 's/author-time //' ) ;;
        "filename "*)
          year=$(date +%Y -d @${timestamp})
          year_authorinfo=$(printf '%s\n%s' "${year_authorinfo}" "${author} ${mail};${year}")
          ;;
        *) ;;
      esac
    fi
  done <<EOF
  $authorinfo
EOF

  # Get only the unique author names
  uniq_authors="$(printf '%s\n' "$year_authorinfo" | tail -n +2 | awk -F ';' '{print $1}' | sort -u)"

  # Get all years for each author, and condense them into one line per author,
  # with the earliest contribution as the start year, and the latest
  # contribution as the end year
  condensed_authorinfo=""
  while read -r author; do
    years_for_author="$(printf '%s' "$year_authorinfo" | awk -F ';' "{if (\$1 == \"$author\") print \$2}")"
    min_year="$(printf '%s' "$years_for_author" | sort | head -n 1)"
    max_year="$(printf '%s' "$years_for_author" | sort | tail -n 1)"
    if [ "$min_year" = "$max_year" ]; then
      condensed_authorinfo=$(printf '%s\n%s' "$condensed_authorinfo" "$author;$min_year")
    else
      condensed_authorinfo=$(printf '%s\n%s' "$condensed_authorinfo" "$author;$min_year-$max_year")
    fi
  done <<EOF
  $uniq_authors
EOF

  sorted_condensed_authorinfo="$(printf '%s' "$condensed_authorinfo" | tail -n +2 | sort -u)"
  formatted_authorinfo="$(printf '%s' "$sorted_condensed_authorinfo" | awk -F ';' '{print "// (c) " $2 " " $1}')"

  case $file in
    "./cmd/"*) header="// License: GPL-3.0" ;;
    *) header="// License: MPL-2.0" ;;
  esac

  n_existing_license_lines=$(sed '/\(^\/\/ License\|^\/\/ (c)\|^$\)/! Q' $file | wc -l)
  line_to_start_from=$((n_existing_license_lines + 1))

  tail -n +${line_to_start_from} $file > copyright_tmp

  if [ -z "$(sed -n '1{/^use/p};q' copyright_tmp)" ]; then
    # File does not start with "use"
    printf '%s\n%s\n\n' "$header" "$formatted_authorinfo" | cat - copyright_tmp > $file
  else
    # File starts with "use"
    printf '%s\n%s\n' "$header" "$formatted_authorinfo" | cat - copyright_tmp > $file
  fi

  rm copyright_tmp
done
