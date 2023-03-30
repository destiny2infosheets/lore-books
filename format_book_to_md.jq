"# \(.title)

© Bungie

" + ([.chapters[] | 
"## \(.title)

\(.text | split("\n") | map(sub("^#"; "\\#")) | join("\n"))
"] | join("\n"))
