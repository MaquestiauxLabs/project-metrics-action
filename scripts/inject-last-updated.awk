BEGIN { in_block = 0 }

<!-- LAST_UPDATED:START -->/ {
  print
  while ((getline line < "last-updated.tmp") > 0)
    print line
  in_block = 1
  next
}

<!-- LAST_UPDATED:END -->/ {
  in_block = 0
  print
  next
}

!in_block { print }