BEGIN { in_block = 0 }

<!-- LANGUAGES:START -->/ {
  print
  while ((getline line < "languages.tmp") > 0)
    print line
  in_block = 1
  next
}

<!-- LANGUAGES:END -->/ {
  in_block = 0
  print
  next
}

!in_block { print }