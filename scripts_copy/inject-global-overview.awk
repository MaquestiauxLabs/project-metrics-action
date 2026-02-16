BEGIN { in_block = 0 }

/<!-- GLOBAL_OVERVIEW:START -->/ {
  print
  while ((getline line < "global-overview.tmp") > 0)
    print line
  in_block = 1
  next
}

/<!-- GLOBAL_OVERVIEW:END -->/ {
  in_block = 0
  print
  next
}

!in_block { print }