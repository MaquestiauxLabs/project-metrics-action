BEGIN { in_block = 0 }

/<!-- METRICS:START -->/ {
  print
  while ((getline line < "table.tmp") > 0)
    print line
  in_block = 1
  next
}

/<!-- METRICS:END -->/ {
  in_block = 0
  print
  next
}

!in_block { print }
