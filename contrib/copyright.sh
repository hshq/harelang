#!/bin/sh -eu

files=$(find . -name '*.ha')

for file in $files; do
  printf "$file\n"

  authorinfo=$(git blame $file --porcelain --incremental)

  # Format as: Author Name <test@example.com>;2011
  year_authorinfo=""
  ignore_this_commit=false
  while read line; do
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
          year_authorinfo="${year_authorinfo}${author} ${mail};${year}\n"
          ;;
        *) ;;
      esac
    fi
  done <<EOF
  $authorinfo
EOF

  uniq_year_authorinfo="$(printf "$year_authorinfo" | sort -u)"
  # Get only the unique author names
  uniq_authors="$(printf "$year_authorinfo" | awk -F ';' '{print $1}' | sort -u)"

  # Get all years for each author, and condense them into one line per author,
  # with the earliest contribution as the start year, and the latest
  # contribution as the end year
  condensed_authorinfo=""
  while read author; do
    years_for_author="$(printf "$year_authorinfo" | awk -F ';' "{if (\$1 == \"$author\") print \$2}")"
    min_year="$(printf "$years_for_author" | sort | head -n 1)"
    max_year="$(printf "$years_for_author" | sort | tail -n 1)"
    if [ $min_year = $max_year ]; then
      condensed_authorinfo="${condensed_authorinfo}${author};${min_year}\n"
    else
      condensed_authorinfo="${condensed_authorinfo}${author};${min_year}-${max_year}\n"
    fi
  done <<EOF
  $uniq_authors
EOF

  sorted_condensed_authorinfo="$(printf "$condensed_authorinfo" | sort -u)"
  formatted_authorinfo="$(printf "$sorted_condensed_authorinfo" | awk -F ';' '{print "// (c) " $2 " " $1}')"

  case $file in
    "./cmd/"*) header="// License: GPL-3.0\n$formatted_authorinfo\n" ;;
    *) header="// License: MPL-2.0\n$formatted_authorinfo\n" ;;
  esac

  n_existing_license_lines=$(cat $file | sed '/\(^\/\/ License\|^\/\/ (c)\|^$\)/! Q' | wc -l)
  line_to_start_from=$((n_existing_license_lines + 1))

  tail -n +${line_to_start_from} $file > copyright_tmp

  if [ -z "$(sed -n '1{/^use/p};q' copyright_tmp)" ]; then
    # File does not start with "use"
    printf "$header\n" | cat - copyright_tmp > $file
  else
    # File starts with "use"
    printf "$header" | cat - copyright_tmp > $file
  fi

  rm copyright_tmp
done
