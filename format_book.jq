"---
title:
- type: main
  text: \(.title)
creator:
- role: author
  text: Bungie
date: \(now | strftime("%Y-%m-%d"))
lang: en
cover-image: book_\(.hash).png
---

" + ([.chapters[] | 
"# \(.title)

\(.text | split("\n") | map(sub("^#"; "\\#")) | join("\n"))
"] | join("\n"))
