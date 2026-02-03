BEGIN { in_block = 0 }

/<!-- PROJECT_BREAKDOWN:START -->/ {
  print
  while ((getline line < "project-breakdown.tmp") > 0)
    print line
  in_block = 1
  next
}

/<!-- PROJECT_BREAKDOWN:END -->/ {
  in_block = 0
  print
  next
}

!in_block { print }