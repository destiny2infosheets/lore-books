sort_by(.makeSafeTitle)
    | ("# Destiny 2 lore books

Automatically extracted from the API data, updated weekly.

Download all books as EPUB: [books.zip](https://destiny2infosheets.github.io/lore-books/books.zip)

" + ([.[] | " * [\(.title)](\(.makeSafeTitle).md)"] | join("\n"))
    )

